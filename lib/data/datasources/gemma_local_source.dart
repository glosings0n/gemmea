import 'dart:developer' as dev;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';

import 'package:gemmea/core/services/gemma_engine_manager.dart';
import 'package:gemmea/core/utils/text_sanitizer.dart';
import 'package:gemmea/data/datasources/sqlite_helper.dart';

abstract class GemmaLocalSource {
  Future<String> evaluateCropImage(File imageFile, String prompt);
}

const String kNonLeafRejectionMessage =
    "L'image capturée ne semble pas être une feuille de plante. Veuillez reprendre une photo en ciblant clairement une feuille de votre culture.";

/// Structured result emitted by Pass-1 lightweight visual triage (SautiLM-Nuru-Agri or pixel VLM triage).
class NuruVisionClassification {
  final bool isPlantLeaf;
  final String cropLabel;
  final String diseaseHint;
  final String visualObservations;
  final double confidence;

  const NuruVisionClassification({
    required this.isPlantLeaf,
    required this.cropLabel,
    this.diseaseHint = '',
    this.visualObservations = '',
    this.confidence = 0.0,
  });

  factory NuruVisionClassification.fromPassOneResponse(String raw) {
    final clean = TextSanitizer.cleanLatexAndFormatting(raw).trim();
    final lower = clean.toLowerCase();

    final explicitNonLeaf = RegExp(
      r'\bis_leaf\s*:\s*(non|no|false|0)\b',
      caseSensitive: false,
    ).hasMatch(clean);
    final phraseNonLeaf = lower.contains("ne semble pas être une feuille") ||
        lower.contains("pas une feuille") ||
        lower.contains("not a leaf") ||
        lower.contains("non_plant") ||
        lower.contains("aucun végétal");

    if (explicitNonLeaf || phraseNonLeaf) {
      return const NuruVisionClassification(
        isPlantLeaf: false,
        cropLabel: 'non_plant',
        confidence: 0.9,
      );
    }

    String extractField(String key) {
      final m = RegExp(
        '^\\s*$key\\s*:\\s*(.+)\$',
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(clean);
      return m?.group(1)?.trim() ?? '';
    }

    final crop = extractField('CROP');
    final disease = extractField('DISEASE');
    final symptoms = extractField('SYMPTOMS');
    final confStr = extractField('CONFIDENCE').replaceAll('%', '').trim();
    final parsedConf = double.tryParse(confStr);
    final normalizedConf = parsedConf == null
        ? 0.75
        : (parsedConf > 1.0 ? (parsedConf / 100.0).clamp(0.0, 1.0) : parsedConf.clamp(0.0, 1.0));

    return NuruVisionClassification(
      isPlantLeaf: true,
      cropLabel: crop.isNotEmpty ? crop : 'inconnue',
      diseaseHint: disease,
      visualObservations: symptoms.isNotEmpty ? symptoms : clean,
      confidence: normalizedConf,
    );
  }

  String buildRagQuery(String userPrompt) {
    const ignoredTerms = {'inconnue', 'unknown', 'sain', 'saine', 'aucune', 'non', 'none', 'non_plant'};
    final parts = <String>[];

    void addIfMeaningful(String raw) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return;
      if (ignoredTerms.contains(trimmed.toLowerCase())) return;
      parts.add(trimmed);
    }

    addIfMeaningful(cropLabel);
    addIfMeaningful(diseaseHint);

    if (parts.isEmpty) {
      final words = userPrompt
          .toLowerCase()
          .replaceAll(RegExp(r'[^\p{L}0-9\s]', unicode: true), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.length >= 4)
          .where((w) => ![
                'fournissez',
                'analyse',
                'agronomique',
                'complète',
                'détaillée',
                'organisée',
                'selon',
                'rubriques',
                'diagnostic',
                'principal',
                'hypothèses',
                'symptômes',
                'vecteurs',
                'remèdes',
                'biologiques',
                'étape',
                'gestion',
                'irrigation',
                'action',
                'immédiat',
                'directives',
                'sources',
                'officielles',
              ].contains(w));
      parts.addAll(words.take(4));
    }

    return parts.join(' ').trim();
  }
}

/// Collaborative Pass-1 visual classifier abstraction (hosted by SautiLM-Nuru-Agri or pixel VLM triage).
abstract class NuruVisionClassifier {
  Future<NuruVisionClassification> classifyCropImage(
    Uint8List imageBytes,
    String userPromptHint,
  );
}

typedef AgronomyRagSearch = Future<List<Map<String, dynamic>>> Function(String query);
typedef CropSynthesisGenerator = Future<String> Function({
  required Uint8List imageBytes,
  required NuruVisionClassification classification,
  required String faoContext,
  required String userPrompt,
});

/// Decodes SautiLM-Nuru-Agri INT8 TFLite softmax probabilities matching `nuru_vision_trainer.py`.
class NuruTfliteDecoder {
  NuruTfliteDecoder._();

  static const double defaultAbstentionThreshold = 0.55;

  static const List<String> labels = [
    'non_plant',
    'healthy_leaf',
    'cassava_cmd',
    'cassava_cbsd',
    'maize_rust',
    'maize_faw',
    'banana_sigatoka',
    'bean_angular_leaf_spot',
    'tomato_blight',
  ];

  static const Map<String, ({String crop, String disease, String obs})> _meta = {
    'healthy_leaf': (
      crop: 'Feuille saine',
      disease: 'Aucune maladie (Feuille Saine)',
      obs: 'Limbe foliaire uniforme sans nécrose ni chlorose détectée par SautiLM-Nuru.',
    ),
    'cassava_cmd': (
      crop: 'Manioc',
      disease: 'Mosaïque Africaine du Manioc (CMD)',
      obs: 'Marbrures chlorotiques en mosaïque vert-jaune détectées par SautiLM-Nuru-Agri.',
    ),
    'cassava_cbsd': (
      crop: 'Manioc',
      disease: 'Strie Brune du Manioc (CBSD)',
      obs: 'Chlorose nervuraire et nécrose caractéristique détectées par SautiLM-Nuru-Agri.',
    ),
    'maize_rust': (
      crop: 'Maïs',
      disease: 'Rouille Commune du Maïs (Puccinia sorghi)',
      obs: 'Pustules brun-rouille sur limbe détectées par SautiLM-Nuru-Agri.',
    ),
    'maize_faw': (
      crop: 'Maïs',
      disease: 'Chenille Légionnaire d\'Automne (FAW)',
      obs: 'Dégâts foliaires et perforations en fenêtres détectés par SautiLM-Nuru-Agri.',
    ),
    'banana_sigatoka': (
      crop: 'Banane',
      disease: 'Cercosporiose Noire du Bananier (Black Sigatoka)',
      obs: 'Stries brun-noir et nécroses foliaires caractéristiques détectées par SautiLM-Nuru-Agri.',
    ),
    'bean_angular_leaf_spot': (
      crop: 'Haricot',
      disease: 'Tache Angulaire du Haricot (Pseudocercospora griseola)',
      obs: 'Taches anguleuses brunes délimitées par les nervures détectées par SautiLM-Nuru-Agri.',
    ),
    'tomato_blight': (
      crop: 'Tomate',
      disease: 'Mildiou de la Tomate (Phytophthora infestans)',
      obs: 'Taches nécrotiques aqueuses sur feuillage détectées par SautiLM-Nuru-Agri.',
    ),
  };

  static NuruVisionClassification fromOutputProbabilities(
    List<double> probabilities, {
    double threshold = defaultAbstentionThreshold,
  }) {
    if (probabilities.length != labels.length || probabilities.isEmpty) {
      return const NuruVisionClassification(
        isPlantLeaf: false,
        cropLabel: 'non_plant',
        diseaseHint: 'Sortie tenseur SautiLM-Nuru invalide',
        confidence: 0.0,
      );
    }

    var bestIdx = 0;
    var bestProb = probabilities.first;
    for (var i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > bestProb) {
        bestProb = probabilities[i];
        bestIdx = i;
      }
    }

    final bestLabel = labels[bestIdx];
    if (bestLabel == 'non_plant' || bestProb < threshold) {
      return NuruVisionClassification(
        isPlantLeaf: false,
        cropLabel: 'non_plant',
        diseaseHint: 'Objet non végétal ou confiance insuffisante (< ${(threshold * 100).round()}%)',
        confidence: bestProb,
      );
    }

    final info = _meta[bestLabel]!;
    return NuruVisionClassification(
      isPlantLeaf: true,
      cropLabel: info.crop,
      diseaseHint: info.disease,
      visualObservations: info.obs,
      confidence: bestProb,
    );
  }
}

typedef NativeTfliteClassifyFn = Future<List<double>?> Function(Uint8List imageBytes);

/// Runs fast SautiLM-Nuru-Agri INT8 TFLite inference on Android when the `.tflite` bundle
/// is present, falling back seamlessly to `_VlmPixelPassOneClassifier` otherwise.
class TfliteNuruVisionClassifier implements NuruVisionClassifier {
  static const MethodChannel _channel = MethodChannel('com.gemmea.app/nuru_vision');
  final NativeTfliteClassifyFn? _nativeInvokeOverride;
  final NuruVisionClassifier _fallback;

  TfliteNuruVisionClassifier({
    NativeTfliteClassifyFn? nativeInvokeOverride,
    NuruVisionClassifier? fallback,
  })  : _nativeInvokeOverride = nativeInvokeOverride,
        _fallback = fallback ?? _VlmPixelPassOneClassifier();

  @override
  Future<NuruVisionClassification> classifyCropImage(
    Uint8List imageBytes,
    String userPromptHint,
  ) async {
    try {
      final probs = _nativeInvokeOverride != null
          ? await _nativeInvokeOverride(imageBytes)
          : await _channel
              .invokeMethod<List<dynamic>>('classifyCrop', {'imageBytes': imageBytes})
              .then((raw) => raw?.map((e) => (e as num).toDouble()).toList());
      if (probs != null && probs.length == NuruTfliteDecoder.labels.length) {
        return NuruTfliteDecoder.fromOutputProbabilities(probs);
      }
    } catch (e) {
      dev.log(
        'Nuru TFLite native fallback to VLM triage: $e',
        name: 'GEMMA_LOCAL_SOURCE',
      );
    }
    return _fallback.classifyCropImage(imageBytes, userPromptHint);
  }
}

class _VlmPixelPassOneClassifier implements NuruVisionClassifier {
  @override
  Future<NuruVisionClassification> classifyCropImage(
    Uint8List imageBytes,
    String userPromptHint,
  ) async {
    final model = await _getVisionModel();
    final session = await model.createSession();
    const triagePrompt = '''
EXAMEN VISUEL RAPIDE (TRIAGE SAUTILM-NURU — NE GÉNÈRE AUCUNE ANALYSE LONGUE) :
Observe uniquement les pixels de cette image :
1. Est-ce clairement une feuille ou plante agricole ? (oui/non)
2. Si oui : Culture probable (Maïs, Manioc, Haricot, Bananier, Tomate, Caféier, Riz, Arachide ou Inconnue)
3. Symptômes ou maladie visuelle probable (ou "sain" / "inconnue")

Réponds STRICTEMENT avec ces 4 lignes :
IS_LEAF: oui|non
CROP: <culture>
DISEASE: <maladie_ou_symptome>
SYMPTOMS: <description_courte_des_lesions>
''';
    await session.addQueryChunk(
      Message.withImage(
        text: triagePrompt,
        imageBytes: imageBytes,
        isUser: true,
      ),
    );
    final raw = await session.getResponse();
    GemmaEngineManager.resetChatSession();
    return NuruVisionClassification.fromPassOneResponse(raw);
  }
}

Future<InferenceModel> _getVisionModel() async {
  try {
    return await FlutterEdgeAi.getActiveModel(
      supportImage: true,
      maxTokens: 4096,
      preferredBackend: PreferredBackend.cpu,
    );
  } catch (_) {
    return await FlutterEdgeAi.getActiveModel(
      supportImage: true,
      maxTokens: 4096,
    );
  }
}

class GemmaLocalSourceImpl implements GemmaLocalSource {
  final NuruVisionClassifier? _customVisionClassifier;
  final AgronomyRagSearch? _customRagSearch;
  final CropSynthesisGenerator? _customSynthesisGenerator;

  GemmaLocalSourceImpl({
    NuruVisionClassifier? visionClassifier,
    AgronomyRagSearch? ragSearch,
    CropSynthesisGenerator? synthesisGenerator,
  })  : _customVisionClassifier = visionClassifier,
        _customRagSearch = ragSearch,
        _customSynthesisGenerator = synthesisGenerator;

  @override
  Future<String> evaluateCropImage(File imageFile, String prompt) async {
    final bool usesExternalPipeline =
        _customVisionClassifier != null && _customSynthesisGenerator != null;

    Future<String> runEvaluation() async {
      GemmaEngineManager.resetChatSession();
      try {
        if (!usesExternalPipeline) {
          await GemmaEngineManager.ensureInitialized();
        }
        if (!await imageFile.exists()) {
          throw Exception(kNonLeafRejectionMessage);
        }

        dev.log(
          "Reading image bytes for Pass-1 visual triage (pixel-only, zero filename heuristics)",
          name: 'GEMMA_LOCAL_SOURCE',
        );
        final rawBytes = await imageFile.readAsBytes();

        if (rawBytes.isEmpty) {
          throw Exception(kNonLeafRejectionMessage);
        }

        // Optimize image resolution to 512px max dimension to prevent native OOM crashes.
        final imageBytes = await _optimizeImageBytes(rawBytes);

        // PASS 1 (SautiLM-Nuru Collaborative Visual Triage): Native TFLite INT8 first, else VLM triage.
        final classifier = _customVisionClassifier ?? TfliteNuruVisionClassifier();
        final classification = await classifier.classifyCropImage(imageBytes, prompt);
        if (!classification.isPlantLeaf) {
          dev.log(
            "Pass-1 classifier rejected non-plant image before SQLite RAG query.",
            name: 'GEMMA_LOCAL_SOURCE',
          );
          return kNonLeafRejectionMessage;
        }

        // PASS 2A (Grounded Retrieval): Query SQLite FAO/IITA/NARS knowledge ONLY from visual classification.
        final faoContext = await _fetchRagContextFromClassification(classification, prompt);

        // PASS 2B (Expert Synthesis): Grounded agronomic report on SautiLM-Jua-Agri / VLM.
        final synthesizer = _customSynthesisGenerator ?? _runDefaultVlmSynthesis;
        final response = await synthesizer(
          imageBytes: imageBytes,
          classification: classification,
          faoContext: faoContext,
          userPrompt: prompt,
        );

        if (response.trim().isNotEmpty) {
          return TextSanitizer.cleanLatexAndFormatting(response);
        }
        throw Exception("L'analyse VLM n'a renvoyé aucun résultat.");
      } catch (e, stack) {
        dev.log(
          "On-device image evaluation error",
          name: 'GEMMA_LOCAL_SOURCE',
          error: e,
          stackTrace: stack,
        );
        rethrow;
      } finally {
        GemmaEngineManager.resetChatSession();
      }
    }

    return usesExternalPipeline ? runEvaluation() : GemmaEngineManager.runWithLock(runEvaluation);
  }

  Future<String> _runDefaultVlmSynthesis({
    required Uint8List imageBytes,
    required NuruVisionClassification classification,
    required String faoContext,
    required String userPrompt,
  }) async {
    final model = await _getVisionModel();
    final session = await model.createSession();
    final vlmPrompt = '''
Vous êtes Gemmea (architecture collaborative SautiLM-Nuru -> SQLite RAG -> SautiLM-Jua-Agri), l'assistant agronome IA d'analyse et de santé des cultures.
Examinez attentivement l'image fournie et appuyez-vous UNIQUEMENT sur ce qui est visuellement observable et sur les extraits SQLite vérifiés ci-dessous.

RÈGLE DE RIGUEUR :
Si l'image n'est pas clairement une plante ou feuille agricole, répondez uniquement :
"$kNonLeafRejectionMessage"
Si une information clinique/agronomique ou chimique manque dans les extraits FAO/NARS ci-dessous, indiquez-le honnêtement sans inventer de dosage ni de référence officielle.

TRIAGE VISUEL PRÉLIMINAIRE (SAUTILM-NURU) :
- Culture suspectée : ${classification.cropLabel}
- Symptôme/Maladie suspecté(e) : ${classification.diseaseHint.isEmpty ? 'à confirmer visuellement' : classification.diseaseHint}
- Observations initiales : ${classification.visualObservations}

Fournissez votre analyse structurée organisée selon les 7 rubriques suivantes (SANS AUCUN ÉMOJI) :
   ### 1. DIAGNOSTIC PRINCIPAL & HYPOTHÈSES
   - Culture : [Indiquer la culture exacte observée sur l'image : Maïs, Manioc, Haricot, Bananier, Tomate, ou Inconnue]
   - Maladie : [Si la plante est en bonne santé, écrire EXPLICITEMENT : "Aucune maladie (Feuille Saine)". Si malade, indiquer le nom précis de la maladie]
   - Niveau de confiance : [Exemple : 90%]
   - Diagnostics différentiels : [Précisions ou facteurs environnementaux si applicables]
   ### 2. SYMPTÔMES DÉTAILLÉS OBSERVÉS
   (Décoloration, pustules, tavelures, enroulement, déformation du limbe, ou feuille intacte).
   ### 3. CAUSES & VECTEURS (NORMES IITA / NARS)
   (Agent pathogène et mode de transmission selon normes IITA/NARS, ou état physiologique sain).
   ### 4. REMÈDES BIOLOGIQUES & TRAITEMENT ÉTAPE PAR ÉTAPE
   (Recettes bio locales si maladie, ou conseils d'entretien préventif).
   ### 5. GESTION DU SOL, NUTRIMENTS & IRRIGATION
   (Drainage, compost, paillage, humidité).
   ### 6. PLAN D'ACTION IMMÉDIAT
   (Étape 1, Étape 2, Étape 3 pour l'agriculteur).
   ### 7. DIRECTIVES & SOURCES OFFICIELLES
   (Uniquement des références vérifiées FAO / IITA / NARS présentes ci-dessous).

CONTEXTE RAG DE RÉFÉRENCE RETROUVÉ APRÈS TRIAGE VISUEL :
$faoContext

Consigne utilisateur : $userPrompt
''';

    await session.addQueryChunk(
      Message.withImage(
        text: vlmPrompt,
        imageBytes: imageBytes,
        isUser: true,
      ),
    );
    return session.getResponse();
  }

  Future<Uint8List> _optimizeImageBytes(Uint8List inputBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(
        inputBytes,
        targetWidth: 512,
      );
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      dev.log("Image optimization notice: $e", name: 'GEMMA_LOCAL_SOURCE');
    }
    return inputBytes;
  }

  Future<String> _fetchRagContextFromClassification(
    NuruVisionClassification classification,
    String hint,
  ) async {
    try {
      final query = classification.buildRagQuery(hint);
      if (query.isEmpty) {
        return "AUCUNE FICHE FAO/NARS SPÉCIFIQUE RETROUVÉE (culture visuelle non identifiée avec certitude). Basez-vous strictement sur les symptômes observables et recommandez une validation par un agronome local.";
      }

      final searchFn = _customRagSearch ?? SQLiteHelper.instance.searchFAOKnowledge;
      final ragRecords = await searchFn(query);
      if (ragRecords.isEmpty) {
        return "AUCUNE FICHE FAO/NARS SPÉCIFIQUE TROUVÉE POUR '$query' DANS LA BASE SQLITE LOCALE. Ne fabriquez aucune citation ni dosage chimique ; signalez les limites et proposez de consulter un agronome ou les services INERA/NARO/RAB/ISABU/KALRO/TARI.";
      }

      final buffer = StringBuffer();
      buffer.writeln("[EXTRAITS FACTUELS RETROUVÉS VIA RAG SQLITE LOCAL (NORMES FAO/IITA/NARS)]");
      for (int i = 0; i < ragRecords.length; i++) {
        final r = ragRecords[i];
        buffer.writeln("Extrait #${i + 1} - ${r['topic']} (${r['crop_name']}):");
        buffer.writeln("- Citation Officielle: ${r['source_citation']}");
        buffer.writeln("- Description & Agent Pathogène: ${r['content']}");
        buffer.writeln("- Recette & Remède Organique: ${r['organic_remedy']}");
        buffer.writeln("- Perte Estimée: ${r['estimated_loss_pct']}%");
        buffer.writeln("");
      }
      return buffer.toString();
    } catch (e) {
      dev.log("Error querying SQLite RAG context: $e", name: 'GEMMA_LOCAL_SOURCE');
      return "BASE SQLITE RAG INDISPONIBLE POUR CETTE REQUÊTE : répondez prudemment à partir des observations visuelles sans inventer de référence FAO.";
    }
  }
}
