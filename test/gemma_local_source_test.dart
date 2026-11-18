import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemmea/data/datasources/gemma_local_source.dart';

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

    test('NuruTfliteDecoder & TfliteNuruVisionClassifier decode INT8 probabilities and enforce abstention', () async {
      final nonPlant = NuruTfliteDecoder.fromOutputProbabilities([0.92, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01]);
      expect(nonPlant.isPlantLeaf, isFalse);

      final lowConf = NuruTfliteDecoder.fromOutputProbabilities([0.10, 0.25, 0.35, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05]);
      expect(lowConf.isPlantLeaf, isFalse);

      final cbsd = NuruTfliteDecoder.fromOutputProbabilities([0.01, 0.02, 0.03, 0.87, 0.02, 0.02, 0.01, 0.01, 0.01]);
      expect(cbsd.isPlantLeaf, isTrue);
      expect(cbsd.cropLabel, 'Manioc');
      expect(cbsd.diseaseHint, contains('CBSD'));

      final classifier = TfliteNuruVisionClassifier(
        nativeInvokeOverride: (_) async => [0.01, 0.01, 0.88, 0.02, 0.02, 0.02, 0.02, 0.01, 0.01],
        fallback: _FakeVisionClassifier(const NuruVisionClassification(isPlantLeaf: false, cropLabel: 'non_plant')),
      );
      final detected = await classifier.classifyCropImage(Uint8List.fromList([1, 2, 3]), '');
      expect(detected.isPlantLeaf, isTrue);
      expect(detected.cropLabel, 'Manioc');
      expect(detected.diseaseHint, contains('CMD'));
    });
  });
}
