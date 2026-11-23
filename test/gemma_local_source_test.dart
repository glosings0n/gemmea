import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:juamea/data/datasources/gemma_local_source.dart';

class _FakeVisionClassifier implements NuruVisionClassifier {
  final NuruVisionClassification result;
  _FakeVisionClassifier(this.result);

  @override
  Future<NuruVisionClassification> classifyCropImage(
    Uint8List imageBytes,
    String userPromptHint,
  ) async {
    return result;
  }
}

void main() {
  group('Nuru -> SQLite RAG -> Jua-Agri 2-Pass Pipeline', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('gemmea_nuru_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('NuruVisionClassification parses structured triage & rejects non-plant images', () {
      final nonPlant = NuruVisionClassification.fromPassOneResponse('''
IS_LEAF: non
CROP: moto
DISEASE: none
SYMPTOMS: objet métallique
''');
      expect(nonPlant.isPlantLeaf, isFalse);

      final maize = NuruVisionClassification.fromPassOneResponse('''
IS_LEAF: oui
CROP: Maïs
DISEASE: Rouille commune
CONFIDENCE: 88%
SYMPTOMS: pustules brun-rougeâtres le long des feuilles
''');
      expect(maize.isPlantLeaf, isTrue);
      expect(maize.cropLabel, equals('Maïs'));
      expect(maize.diseaseHint, equals('Rouille commune'));
      expect(maize.confidence, closeTo(0.88, 0.01));
      expect(maize.buildRagQuery('analyse complète'), equals('Maïs Rouille commune'));
    });

    test('Pass-1 non-plant rejection aborts before SQLite RAG despite cassava filename trap', () async {
      final fakeFile = File('${tempDir.path}/cassava_mosaic_leaf.jpg');
      await fakeFile.writeAsBytes(Uint8List.fromList([1, 2, 3, 4]));

      bool ragCalled = false;
      bool synthCalled = false;

      final source = GemmaLocalSourceImpl(
        visionClassifier: _FakeVisionClassifier(
          const NuruVisionClassification(isPlantLeaf: false, cropLabel: 'non_plant'),
        ),
        ragSearch: (query) async {
          ragCalled = true;
          return [];
        },
        synthesisGenerator: ({
          required imageBytes,
          required classification,
          required faoContext,
          required userPrompt,
        }) async {
          synthCalled = true;
          return 'SHOULD NOT RUN';
        },
      );

      final result = await source.evaluateCropImage(fakeFile, 'Diagnostiquer la plante');
      expect(result, equals(kNonLeafRejectionMessage));
      expect(ragCalled, isFalse);
      expect(synthCalled, isFalse);
    });

    test('RAG queries visual pixels (Maïs Rouille), completely ignoring image filename', () async {
      // Trap filename says cassava, generic Android filename, pixels actually depict Maize Rust!
      final trapFile = File('${tempDir.path}/IMG_20261118_cassava_trap.jpg');
      await trapFile.writeAsBytes(Uint8List.fromList([9, 8, 7, 6]));

      String? capturedRagQuery;
      String? capturedFaoContext;

      final source = GemmaLocalSourceImpl(
        visionClassifier: _FakeVisionClassifier(
          const NuruVisionClassification(
            isPlantLeaf: true,
            cropLabel: 'Maïs',
            diseaseHint: 'Rouille commune',
            visualObservations: 'pustules orangées sur limbe',
            confidence: 0.91,
          ),
        ),
        ragSearch: (query) async {
          capturedRagQuery = query;
          return [
            {
              'topic': 'Rouille Commune du Maïs (Puccinia sorghi)',
              'crop_name': 'Maïs',
              'source_citation': 'Manuel IITA Maïs (2024)',
              'content': 'Pustules brunes poudreuses sur les deux faces.',
              'organic_remedy': 'Purin de prêle et rotation légumineuses.',
              'estimated_loss_pct': 25.0,
            }
          ];
        },
        synthesisGenerator: ({
          required imageBytes,
          required classification,
          required faoContext,
          required userPrompt,
        }) async {
          capturedFaoContext = faoContext;
          return '### 1. DIAGNOSTIC PRINCIPAL & HYPOTHÈSES\n- Culture : ${classification.cropLabel}\n- Maladie : ${classification.diseaseHint}';
        },
      );

      final result = await source.evaluateCropImage(trapFile, 'Analyser cette feuille');
      expect(capturedRagQuery, equals('Maïs Rouille commune'));
      expect(capturedRagQuery!.toLowerCase(), isNot(contains('manioc')));
      expect(capturedRagQuery!.toLowerCase(), isNot(contains('cassava')));
      expect(capturedFaoContext, contains('Manuel IITA Maïs (2024)'));
      expect(result, contains('Culture : Maïs'));
    });

    test('Empty RAG records explicitly warns model instead of inventing FAO citations', () async {
      final plantFile = File('${tempDir.path}/IMG_002.jpg');
      await plantFile.writeAsBytes(Uint8List.fromList([5, 4, 3, 2]));

      String? capturedFaoContext;
      final source = GemmaLocalSourceImpl(
        visionClassifier: _FakeVisionClassifier(
          const NuruVisionClassification(
            isPlantLeaf: true,
            cropLabel: 'Quinquina',
            diseaseHint: 'Tache foliaire inconnue',
            confidence: 0.65,
          ),
        ),
        ragSearch: (_) async => [],
        synthesisGenerator: ({
          required imageBytes,
          required classification,
          required faoContext,
          required userPrompt,
        }) async {
          capturedFaoContext = faoContext;
          return 'Analyse prudente hors corpus.';
        },
      );

      await source.evaluateCropImage(plantFile, 'Analyser cette feuille');
      expect(capturedFaoContext, contains('AUCUNE FICHE FAO/NARS SPÉCIFIQUE TROUVÉE'));
    });

    test('NuruTfliteDecoder & TfliteNuruVisionClassifier decode INT8 probabilities and distinguish real leaves from non-plant images', () async {
      final nonPlant = NuruTfliteDecoder.fromOutputProbabilities([0.92, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01]);
      expect(nonPlant.isPlantLeaf, isFalse);

      // Ambiguous high non_plant probability (>= 45%) or flat noise (< 30% max) still rejects
      final ambiguousNonPlant = NuruTfliteDecoder.fromOutputProbabilities([0.48, 0.22, 0.12, 0.05, 0.03, 0.03, 0.03, 0.02, 0.02]);
      expect(ambiguousNonPlant.isPlantLeaf, isFalse);
      final flatNoise = NuruTfliteDecoder.fromOutputProbabilities([0.12, 0.12, 0.12, 0.11, 0.11, 0.11, 0.11, 0.10, 0.10]);
      expect(flatNoise.isPlantLeaf, isFalse);

      // Real leaf with low non_plant (5%) and split disease certainty (42% CMD vs 25% healthy)
      // MUST NOT falsely say "Feuille non détectée"!
      final moderateLeaf = NuruTfliteDecoder.fromOutputProbabilities([0.05, 0.25, 0.42, 0.12, 0.05, 0.03, 0.03, 0.03, 0.02]);
      expect(moderateLeaf.isPlantLeaf, isTrue);
      expect(moderateLeaf.cropLabel, 'Manioc');
      expect(moderateLeaf.diseaseHint, contains('à confirmer'));
      expect(moderateLeaf.confidence, closeTo(0.42, 0.001));

      final cbsd = NuruTfliteDecoder.fromOutputProbabilities([0.01, 0.02, 0.03, 0.87, 0.02, 0.02, 0.01, 0.01, 0.01]);
      expect(cbsd.isPlantLeaf, isTrue);
      expect(cbsd.cropLabel, 'Manioc');
      expect(cbsd.diseaseHint, contains('CBSD'));

      // Verify Sigatoka (index 6) and Bean Angular Leaf Spot (index 7) match certified manifest
      expect(NuruTfliteDecoder.labels[6], 'banana_sigatoka');
      expect(NuruTfliteDecoder.labels[7], 'bean_angular_leaf_spot');
      final bananaSigatoka = NuruTfliteDecoder.fromOutputProbabilities([0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.91, 0.02, 0.01]);
      expect(bananaSigatoka.isPlantLeaf, isTrue);
      expect(bananaSigatoka.cropLabel, 'Banane');
      expect(bananaSigatoka.diseaseHint, contains('Sigatoka'));

      final beanAls = NuruTfliteDecoder.fromOutputProbabilities([0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.02, 0.91, 0.01]);
      expect(beanAls.isPlantLeaf, isTrue);
      expect(beanAls.cropLabel, 'Haricot');
      expect(beanAls.diseaseHint, contains('Tache Angulaire'));

      final classifier = TfliteNuruVisionClassifier(
        nativeInvokeOverride: (_) async => [0.01, 0.01, 0.88, 0.02, 0.02, 0.02, 0.02, 0.01, 0.01],
        fallback: _FakeVisionClassifier(const NuruVisionClassification(isPlantLeaf: false, cropLabel: 'non_plant')),
      );
      final detected = await classifier.classifyCropImage(Uint8List.fromList([1, 2, 3]), '');
      expect(detected.isPlantLeaf, isTrue);
      expect(detected.cropLabel, 'Manioc');
      expect(detected.diseaseHint, contains('CMD'));

      final detReport = GemmaLocalSourceImpl.buildDeterministicAgronomyReport(
        classification: detected,
        faoContext: 'Extrait #1 - IITA Cassava CMD: utiliser des boutures saines.',
      );
      expect(detReport, contains('Manioc'));
      expect(detReport, contains('CMD'));
      expect(detReport, contains('IITA Cassava CMD'));
      expect(
        GemmaLocalSourceImpl.buildDeterministicAgronomyReport(
          classification: const NuruVisionClassification(isPlantLeaf: false, cropLabel: 'non_plant'),
          faoContext: '',
        ),
        equals(kNonLeafRejectionMessage),
      );
    });

    test('Production evaluateCropImage defaults to deterministic SQLite card with 0 VLM calls', () async {
      final leafFile = File('${tempDir.path}/IMG_FIELD_CMD.jpg');
      await leafFile.writeAsBytes(Uint8List.fromList([7, 7, 7, 7]));

      final source = GemmaLocalSourceImpl(
        visionClassifier: _FakeVisionClassifier(
          const NuruVisionClassification(
            isPlantLeaf: true,
            cropLabel: 'Manioc',
            diseaseHint: 'Mosaïque du Manioc (CMD)',
            visualObservations: 'marbrures jaunes typiques CMD',
            confidence: 0.92,
          ),
        ),
        ragSearch: (_) async => [
          {
            'topic': 'Mosaïque du Manioc (CMD)',
            'crop_name': 'Manioc',
            'source_citation': 'IITA Cassava Manual (2024)',
            'content': 'Transmission par mouche blanche Bemisia tabaci.',
            'organic_remedy': 'Arrachage précoce et boutures saines certifiées.',
            'estimated_loss_pct': null,
          }
        ],
        // NOTE: synthesisGenerator intentionally omitted (production default!)
      );

      final report = await source.evaluateCropImage(leafFile, 'Analyser cette feuille');
      expect(report, contains('DIAGNOSTIC PRINCIPAL (SautiLM-Nuru-Agri + SQLite FTS5)'));
      expect(report, contains('IITA Cassava Manual (2024)'));
      expect(report, contains('Non quantifiée (manuel CGIAR/NARS)'));
      expect(report, isNot(contains('-1.0%')));
    });
  });
}
