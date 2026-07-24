import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gemmea/data/datasources/sqlite_helper.dart';
import 'package:gemmea/data/repositories/fao_rag_repository_impl.dart';
import 'package:gemmea/domain/entities/fao_guideline.dart';

class MockSQLiteHelper extends Mock implements SQLiteHelper {}

void main() {
  late MockSQLiteHelper mockSQLiteHelper;
  late FAORagRepositoryImpl repository;

  setUp(() {
    mockSQLiteHelper = MockSQLiteHelper();
    repository = FAORagRepositoryImpl(sqliteHelper: mockSQLiteHelper);
  });

  group('FAORagRepository Tests', () {
    final mockFaoData = [
      {
        'id': 1,
        'topic': 'Cassava Mosaic Disease (CMD)',
        'crop_name': 'Manioc',
        'keywords': 'manioc cassava mosaique',
        'content': 'La mosaïque du manioc est causée par un geminivirus.',
        'organic_remedy': '1. Éliminer les plants infectés. 2. Utiliser des boutures TME 419.',
        'estimated_loss_pct': 55.0,
        'source_citation': 'Guide FAO (2024)',
      }
    ];

    test('searchGuidelines returns mapped FAOGuideline entities from SQLite', () async {
      when(() => mockSQLiteHelper.searchFAOKnowledge('manioc'))
          .thenAnswer((_) async => mockFaoData);

      final results = await repository.searchGuidelines('manioc');

      expect(results.length, 1);
      expect(results.first.topic, 'Cassava Mosaic Disease (CMD)');
      expect(results.first.cropName, 'Manioc');
      expect(results.first.estimatedLossPct, 55.0);
      expect(results.first.sourceCitation, 'Guide FAO (2024)');
      verify(() => mockSQLiteHelper.searchFAOKnowledge('manioc')).called(1);
    });

    test('getGuidelinesByCrop queries sqlite by crop name', () async {
      when(() => mockSQLiteHelper.getFAOByCrop('Manioc'))
          .thenAnswer((_) async => mockFaoData);

      final results = await repository.getGuidelinesByCrop('Manioc');

      expect(results.length, 1);
      expect(results.first.cropName, 'Manioc');
      verify(() => mockSQLiteHelper.getFAOByCrop('Manioc')).called(1);
    });

    test('buildGroundedSystemPrompt constructs grounded prompt with FAO citations', () {
      final guidelines = [
        FAOGuideline.fromMap(mockFaoData.first),
      ];

      final prompt = repository.buildGroundedSystemPrompt(guidelines);

      expect(prompt, contains('RÈGLE ABSOLUE'));
      expect(prompt, contains('DOCUMENTS OFFICIELS FAO RETROUVÉS VIA RAG HORS LIGNE'));
      expect(prompt, contains('Cassava Mosaic Disease (CMD)'));
      expect(prompt, contains('Guide FAO (2024)'));
    });

    test('buildGroundedSystemPrompt returns default prompt when guidelines empty', () {
      final prompt = repository.buildGroundedSystemPrompt([]);

      expect(prompt, contains('GEMMEA ASSISTANT AGRONOMIQUE HORS LIGNE'));
      expect(prompt, isNot(contains('DOCUMENTS OFFICIELS FAO')));
    });
  });
}
