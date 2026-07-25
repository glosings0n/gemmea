import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:gemmea/domain/repositories/chat_repository.dart';

class GetChatMessages {
  final ChatRepository repository;
  GetChatMessages(this.repository);

  Future<List<Message>> call() async {
    return await repository.getChatMessages();
  }
}

class SaveChatMessage {
  final ChatRepository repository;
  SaveChatMessage(this.repository);

  Future<void> call(Message message) async {
    await repository.saveChatMessage(message);
  }
}

class ClearChat {
  final ChatRepository repository;
  ClearChat(this.repository);

  Future<void> call() async {
    await repository.clearChat();
  }
}

class CheckModelInstalled {
  final ChatRepository repository;
  CheckModelInstalled(this.repository);

  Future<bool> call() async {
    return await repository.checkModelInstalled();
  }
}

class InitializeGemma {
  final ChatRepository repository;
  InitializeGemma(this.repository);

  Future<void> call(Function(double) onProgress) async {
    await repository.initializeGemma(onProgress);
  }
}

class GetGemmaResponseStream {
  final ChatRepository repository;
  GetGemmaResponseStream(this.repository);

  Stream<ModelResponse> call(String text, [List<Message>? history]) {
    return repository.getGemmaResponseStream(text, history);
  }
}
