import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_gemma/flutter_gemma.dart';

import 'package:gemmea/core/services/gemma_engine_manager.dart';
import 'package:gemmea/core/utils/text_sanitizer.dart';
import 'package:gemmea/data/datasources/sqlite_helper.dart';

abstract class GemmaLocalSource {
  Future<String> evaluateCropImage(File imageFile, String prompt);
}

class GemmaLocalSourceImpl implements GemmaLocalSource {
  @override
  Future<String> evaluateCropImage(File imageFile, String prompt) async {
    return GemmaEngineManager.runWithLock(() async {
      GemmaEngineManager.resetChatSession();
      try {
        await GemmaEngineManager.ensureInitialized();
        if (!await imageFile.exists()) {
          throw Exception(
            "L'image capturée ne semble pas être une feuille de plante. Veuillez reprendre une photo en ciblant clairement une feuille de votre culture.",
          );
        }

        dev.log(
          "Reading image bytes for evaluation: ${imageFile.path}",
          name: 'GEMMA_LOCAL_SOURCE',
        );
        final rawBytes = await imageFile.readAsBytes();

        if (rawBytes.isEmpty) {
          throw Exception(
            "L'image capturée ne semble pas être une feuille de plante. Veuillez reprendre une photo en ciblant clairement une feuille de votre culture.",
          );
        }

        // Optimize image resolution to 512px max dimension to ensure fast vision encoding and prevent native OOM crashes
        final imageBytes = await _optimizeImageBytes(rawBytes);

        final faoContext = await _fetchRagContextFromSqlite(imageFile.path, prompt);

        // Execute Gemma VLM multimodal analysis with the optimized image bytes and SQLite RAG factual context
        try {
          dev.log(
            "Executing Gemma VLM multimodal vision analysis for image (${imageBytes.length} bytes)...",
            name: 'GEMMA_LOCAL_SOURCE',
          );

          InferenceModel model;
          try {
            model = await FlutterGemma.getActiveModel(
              supportImage: true,
              maxTokens: 4096,
              preferredBackend: PreferredBackend.cpu,
            );
          } catch (e) {
            model = await FlutterGemma.getActiveModel(
              supportImage: true,
              maxTokens: 4096,
            );
          }

          final session = await model.createSession();
          final vlmPrompt = '''
Vous êtes Gemmea, l'assistant agronome IA d'analyse et de santé des cultures.
Examinez l'image fournie.

RÈGLE ABSOLUE ET URGENTE (ÉVALUATION IMMÉDIATE) :
Étape 1 : Regardez l'image. Si ce n'est PAS une feuille de plante ou une culture agricole (ex: visage, téléphone, personne, chaussure, meuble, animal, objet) :
Arrêtez immédiatement toute génération et répondez UNIQUEMENT par cette phrase :
"L'image capturée ne semble pas être une feuille de plante. Veuillez reprendre une photo en ciblant clairement une feuille de votre culture."
NE GÉNÉREZ AUCUNE RUBRIQUE, AUCUN TITRE ET N'UTILISEZ PAS LE CONTEXTE RAG CI-DESSOUS.

Étape 2 : SI ET SEULEMENT SI L'IMAGE EST VRAIMENT UNE FEUILLE OU UNE CULTURE AGRICOLE :
Fournissez votre propre analyse TRÈS DÉTAILLÉE, STRUCTURÉE ET COMPLÈTE organisée selon les 7 rubriques suivantes (SANS AUCUN ÉMOJI) :

EXIGENCES DE MISE EN FORME MARKDOWN :
- Titres de rubriques clairs avec ### (ex: ### 1. DIAGNOSTIC PRINCIPAL & HYPOTHÈSES)
- Numérotations claires (1., 2., 3.) pour les étapes du plan d'action et les méthodes de traitement
- Points de puces (- ) pour énumérer les symptômes, causes et conseils du sol
- Mots-clés en **gras** (ex: **Agent pathogène :**, **Dosage :**, **Traitement bio :**)
- Remarques et conseils secondaires en *italique* (ex: *Appliquer de préférence tôt le matin.*)

   ### 1. DIAGNOSTIC PRINCIPAL & HYPOTHÈSES
   - Culture : [Indiquer la culture exacte observée sur l'image : Maïs, Manioc, Haricot, Banane, Tomate, ou Inconnue]
   - Maladie : [Si la plante est en bonne santé, écrire EXPLICITEMENT : "Aucune maladie (Feuille Saine)". Si malade, indiquer le nom précis de la maladie]
   - Niveau de confiance : [Exemple : 90%]
   - Diagnostics différentiels : [Précisions ou facteurs environnementaux si applicables]
   ### 2. SYMPTÔMES DÉTAILLÉS OBSERVÉS
   (Décoloration, pustules, tavelures, enroulement, déformation du limbe, ou feuille intacte).
   ### 3. CAUSES & VECTEURS (NORMES IITA)
   (Agent pathogène et mode de transmission selon normes IITA, ou état physiologique sain).
   ### 4. REMÈDES BIOLOGIQUES & TRAITEMENT ÉTAPE PAR ÉTAPE
   (Recettes bio locales si maladie : Neem, cendre de bois, Bicarbonate de soude - NaHCO3, savon noir. Si la feuille est saine, donner des conseils d'entretien préventif).
   ### 5. GESTION DU SOL, NUTRIMENTS & IRRIGATION
   (Drainage, compost, paillage, humidité).
   ### 6. PLAN D'ACTION IMMÉDIAT
   (Étape 1, Étape 2, Étape 3 pour l'agriculteur).
   ### 7. DIRECTIVES & SOURCES OFFICIELLES
   (Références explicites FAO & IITA).

CONTEXTE RAG DE RÉFÉRENCE (À IGNORER TOTALEMENT SI CE N'EST PAS UNE PLANTE) :
$faoContext

Consigne utilisateur : $prompt
''';

          await session.addQueryChunk(
            Message.withImage(
              text: vlmPrompt,
              imageBytes: imageBytes,
              isUser: true,
            ),
          );

          final String response = await session.getResponse();
          dev.log(
            "Gemma VLM vision analysis response length: ${response.length}",
            name: 'GEMMA_LOCAL_SOURCE',
          );

          if (response.trim().isNotEmpty) {
            return TextSanitizer.cleanLatexAndFormatting(response);
          } else {
            throw Exception("L'analyse VLM n'a renvoyé aucun résultat.");
          }
        } catch (gemmaError, stack) {
          dev.log(
            "Gemma VLM vision evaluation error: $gemmaError",
            name: 'GEMMA_LOCAL_SOURCE',
            error: gemmaError,
            stackTrace: stack,
          );
          rethrow;
        }
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
    });
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

  Future<String> _fetchRagContextFromSqlite(String imagePath, String hint) async {
    try {
      final filename = imagePath.toLowerCase();
      String query = "manioc cassava mosaic";
      if (filename.contains("mais") ||
          filename.contains("maize") ||
          filename.contains("rust") ||
          filename.contains("rouille")) {
        query = "mais maize rouille puccinia";
      } else if (filename.contains("bean") ||
          filename.contains("haricot") ||
          filename.contains("anthracnose")) {
        query = "haricot bean anthracnose";
      } else if (filename.contains("banana") ||
          filename.contains("banane") ||
          filename.contains("bxw")) {
        query = "banane banana fletrissement bxw";
      } else if (hint.isNotEmpty) {
        query = hint;
      }

      final ragRecords = await SQLiteHelper.instance.searchFAOKnowledge(query);
      if (ragRecords.isEmpty) {
        return "Source FAO/IITA: Manuel Général de Protection des Cultures Africaines (2024).";
      }

      final buffer = StringBuffer();
      buffer.writeln("[EXTRAITS FACTUELS RETROUVÉS VIA RAG SQLITE LOCAL (NORMES FAO/IITA)]");
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
      return "Source FAO/IITA: Manuel de Santé des Récoltes (2024).";
    }
  }
}
