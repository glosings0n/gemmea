import 'package:flutter_edge_ai/flutter_edge_ai.dart';

abstract class ChatRepository {
  Future<List<Message>> getChatMessages();
  Future<void> saveChatMessage(Message message);
  Stream<ModelResponse> getGemmaResponseStream(String text, [List<Message>? history]);
  Future<void> clearChat();
  Future<bool> checkModelInstalled();
  Future<void> initializeGemma(Function(double) onProgress);
}
