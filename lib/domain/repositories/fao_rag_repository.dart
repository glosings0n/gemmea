import '../entities/fao_guideline.dart';

abstract class FAORagRepository {
  Future<List<FAOGuideline>> searchGuidelines(String query);
  Future<List<FAOGuideline>> getGuidelinesByCrop(String cropName);
  String buildGroundedSystemPrompt(List<FAOGuideline> guidelines);
}
