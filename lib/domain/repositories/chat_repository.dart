import 'package:flutter_gemma/flutter_gemma.dart';

abstract class ChatRepository {
  Future<List<Message>> getChatMessages();
  Future<void> saveChatMessage(Message message);
  Stream<ModelResponse> getGemmaResponseStream(String text);
  Future<void> clearChat();
  Future<bool> checkModelInstalled();
  Future<void> initializeGemma(Function(double) onProgress);
}
