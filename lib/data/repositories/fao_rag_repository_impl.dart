import '../../domain/entities/fao_guideline.dart';
import '../../domain/repositories/fao_rag_repository.dart';
import '../datasources/sqlite_helper.dart';

class FAORagRepositoryImpl implements FAORagRepository {
  final SQLiteHelper sqliteHelper;

  FAORagRepositoryImpl({SQLiteHelper? sqliteHelper})
      : sqliteHelper = sqliteHelper ?? SQLiteHelper.instance;

  @override
  Future<List<FAOGuideline>> searchGuidelines(String query) async {
    final rawResults = await sqliteHelper.searchFAOKnowledge(query);
    return rawResults.map((map) => FAOGuideline.fromMap(map)).toList();
  }

  @override
  Future<List<FAOGuideline>> getGuidelinesByCrop(String cropName) async {
    final rawResults = await sqliteHelper.getFAOByCrop(cropName);
    return rawResults.map((map) => FAOGuideline.fromMap(map)).toList();
  }

  @override
  String buildGroundedSystemPrompt(List<FAOGuideline> guidelines) {
    if (guidelines.isEmpty) {
      return '''
[RÔLE SYSTÈME : GEMMEA ASSISTANT AGRONOMIQUE HORS LIGNE]
Vous êtes Gemmea, l'assistant agronomique IA 100% hors ligne dédié aux agriculteurs d'Afrique de l'Est et de RDC.
Fournissez des conseils agronomiques précis, bienveillants et clairs.
''';
    }

    final contextBuffer = StringBuffer();
    contextBuffer.writeln('''
[RÔLE SYSTÈME : GEMMEA ASSISTANT AGRONOMIQUE HORS LIGNE]
Vous êtes Gemmea, l'assistant agronomique IA 100% hors ligne dédié aux agriculteurs d'Afrique de l'Est et de RDC.
RÈGLE ABSOLUE : Vos réponses doivent s'appuyer strictement sur les GUIDES OFFICIELS FAO ci-dessous pour éviter toute hallucination.

[DOCUMENTS OFFICIELS FAO RETROUVÉS VIA RAG HORS LIGNE]''');

    for (int i = 0; i < guidelines.length; i++) {
      final g = guidelines[i];
      contextBuffer.writeln('''
Extrait ${i + 1} - ${g.topic} (${g.cropName}):
- Source Officielle: ${g.sourceCitation}
- Symptômes & Description: ${g.content}
- Remède Biologique Recommandé: ${g.organicRemedy}
- Risque de Perte Estimé: ${g.estimatedLossPct.toStringAsFixed(0)}% du rendement
''');
    }

    contextBuffer.writeln('''
[INSTRUCTIONS DE RAISONMENT (CHAIN-OF-THOUGHT & CITATION)]
1. Analysez le problème de l'agriculteur étape par étape.
2. Citez explicitement la source FAO utilisée (ex: "Selon le Guide FAO (2024)...").
3. Proposez des étapes concrètes, écologiques et immédiatement applicables sans réseau.
''');

    return contextBuffer.toString();
  }
}
