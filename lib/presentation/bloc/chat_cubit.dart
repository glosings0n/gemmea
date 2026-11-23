import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:juamea/core/localization/localization.dart';
import 'package:juamea/core/services/gemma_engine_manager.dart';
import 'package:juamea/core/services/juamea_model_manager.dart';
import 'package:juamea/data/datasources/sqlite_helper.dart';
import 'package:juamea/domain/usecases/calendar_usecases.dart';
import 'package:juamea/domain/usecases/chat_usecases.dart';

const String kJuameaMissingModelPrompt =
    "Le modèle IA SautiLM-Jua-Agri n'est pas encore téléchargé sur cet appareil. Appuyez sur « Télécharger le modèle » pour activer le chat hors ligne.";

bool isJuameaMissingModelMessage(String text) {
  return text == kJuameaMissingModelPrompt ||
      text == JuameaStrings.of(JuameaLanguage.fr).chatMissingModelPrompt ||
      text == JuameaStrings.of(JuameaLanguage.en).chatMissingModelPrompt ||
      text == JuameaStrings.of(JuameaLanguage.sw).chatMissingModelPrompt;
}

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  final bool isStreaming;
  final String? systemNotification;
  final bool isModelMissing;

  ChatLoaded({
    required this.messages,
    required this.isStreaming,
    this.systemNotification,
    this.isModelMissing = false,
  });

  ChatLoaded copyWith({
    List<Message>? messages,
    bool? isStreaming,
    String? systemNotification,
    bool? isModelMissing,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      systemNotification: systemNotification,
      isModelMissing: isModelMissing ?? this.isModelMissing,
    );
  }
}

class ChatError extends ChatState {
  final String error;
  ChatError(this.error);
}

class ChatCubit extends Cubit<ChatState> {
  final GetChatMessages getChatMessages;
  final SaveChatMessage saveChatMessage;
  final GetGemmaResponseStream getGemmaResponseStream;
  final ClearChat clearChat;
  final CheckModelInstalled? checkModelInstalled;

  // To handle calendar function calling autonomously
  final AddCalendarEvent addCalendarEvent;
  final UpdateRainStatus updateRainStatus;

  StreamSubscription<ModelResponse>? _streamSubscription;

  ChatCubit({
    required this.getChatMessages,
    required this.saveChatMessage,
    required this.getGemmaResponseStream,
    required this.clearChat,
    required this.addCalendarEvent,
    required this.updateRainStatus,
    this.checkModelInstalled,
  }) : super(ChatInitial());

  Future<bool> _isModelMissingNow() async {
    final checker = checkModelInstalled;
    if (checker == null) return false;
    try {
      return !(await checker());
    } catch (_) {
      return false;
    }
  }

  JuameaStringsData get _strings => JuameaStrings.of(
        JuameaLanguageX.fromCode(SQLiteHelper.currentLanguageCode),
      );

  /// Updates the default welcome bubble immediately if the user switches app language
  /// before sending messages.
  void refreshLanguageStrings() {
    final current = state;
    if (current is! ChatLoaded || current.isStreaming) return;
    if (current.messages.length == 1 && !current.messages.first.isUser) {
      final firstText = current.messages.first.text;
      final isWelcome = firstText == JuameaStrings.of(JuameaLanguage.fr).chatWelcome ||
          firstText == JuameaStrings.of(JuameaLanguage.en).chatWelcome ||
          firstText == JuameaStrings.of(JuameaLanguage.sw).chatWelcome;
      if (isWelcome) {
        emit(current.copyWith(
          messages: [Message.text(text: _strings.chatWelcome, isUser: false)],
        ));
      }
    }
  }

  /// Refreshes local chat model availability (e.g. right after downloading or deleting weights).
  Future<void> refreshModelStatus() async {
    final current = state;
    if (current is! ChatLoaded) return;
    final missing = await _isModelMissingNow();
    if (missing != current.isModelMissing) {
      emit(current.copyWith(isModelMissing: missing));
    }
  }

  Future<void> loadChatHistory() async {
    emit(ChatLoading());
    try {
      dev.log("Loading chat history from database...", name: 'CHAT_CUBIT');
      final messages = await getChatMessages();
      final missing = await _isModelMissingNow();
      if (messages.isEmpty) {
        final welcome = Message.text(
          text: _strings.chatWelcome,
          isUser: false,
        );
        emit(ChatLoaded(
          messages: [welcome],
          isStreaming: false,
          isModelMissing: missing,
        ));
      } else {
        emit(ChatLoaded(
          messages: messages,
          isStreaming: false,
          isModelMissing: missing,
        ));
      }
    } catch (e, stack) {
      dev.log("Error loading chat history", name: 'CHAT_CUBIT', error: e, stackTrace: stack);
      emit(ChatError(e.toString()));
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final currentState = state;
    if (currentState is! ChatLoaded || currentState.isStreaming) return;
    final strings = _strings;

    // If model is not downloaded yet, clearly invite the user to download it instead of failing silently
    if (await _isModelMissingNow()) {
      final userMessage = Message.text(text: text, isUser: true);
      final inviteMessage = Message.text(text: strings.chatMissingModelPrompt, isUser: false);
      final updated = List<Message>.from(currentState.messages)
        ..add(userMessage)
        ..add(inviteMessage);
      emit(ChatLoaded(
        messages: updated,
        isStreaming: false,
        isModelMissing: true,
      ));
      return;
    }

    final userMessage = Message.text(text: text, isUser: true);
    final updatedMessages = List<Message>.from(currentState.messages)..add(userMessage);

    emit(ChatLoaded(
      messages: updatedMessages,
      isStreaming: true,
      isModelMissing: false,
    ));

    try {
      dev.log("Sending chat message: '$text'", name: 'CHAT_CUBIT');
      // 1. Save user message to database
      await saveChatMessage(userMessage);

      // 2. Core Function Calling: Check for autonomous calendar updates (FR, EN & SW)
      String? functionCallingNotice;
      final lowercaseText = text.toLowerCase();

      final tomorrowStr = DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0];
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      if (lowercaseText.contains("rain") ||
          lowercaseText.contains("wet") ||
          lowercaseText.contains("raining") ||
          lowercaseText.contains("pluie") ||
          lowercaseText.contains("pleut") ||
          lowercaseText.contains("humide") ||
          lowercaseText.contains("mvua") ||
          lowercaseText.contains("unanyesha")) {
        dev.log("Triggering Function Calling: Pause irrigation for rain", name: 'CHAT_CUBIT');
        await updateRainStatus(tomorrowStr, true);
        await updateRainStatus(todayStr, true);
        functionCallingNotice = strings.chatRainAdjustedNotice;
      } else if (lowercaseText.contains("dry") ||
          lowercaseText.contains("hot") ||
          lowercaseText.contains("irrigate") ||
          lowercaseText.contains("water my field") ||
          lowercaseText.contains("sec") ||
          lowercaseText.contains("chaud") ||
          lowercaseText.contains("arroser") ||
          lowercaseText.contains("arrose") ||
          lowercaseText.contains("ukame") ||
          lowercaseText.contains("kavu") ||
          lowercaseText.contains("mwagilia")) {
        dev.log("Triggering Function Calling: Resume regular irrigation for dry weather", name: 'CHAT_CUBIT');
        await updateRainStatus(tomorrowStr, false);
        await updateRainStatus(todayStr, false);
        functionCallingNotice = strings.chatDryAdjustedNotice;
      }

      // Add placeholder message for streaming model response
      final bool isAnalyzingPlant = GemmaEngineManager.isBusy;
      final String initialPlaceholder = isAnalyzingPlant
          ? strings.chatBusyPlaceholder
          : "";

      final modelPlaceholder = Message.text(text: initialPlaceholder, isUser: false);
      final streamingMessages = List<Message>.from(updatedMessages)..add(modelPlaceholder);
      emit(ChatLoaded(
        messages: streamingMessages,
        isStreaming: true,
        systemNotification: functionCallingNotice,
        isModelMissing: false,
      ));

      // 3. Initiate local stream response from SautiLM-Jua-Agri
      StringBuffer fullReply = StringBuffer();

      _streamSubscription = getGemmaResponseStream(text, updatedMessages).listen(
        (response) {
          if (response is TextResponse) {
            fullReply.write(response.token);

            final latestState = state;
            if (latestState is ChatLoaded) {
              final streamMessages = List<Message>.from(latestState.messages);
              if (streamMessages.isNotEmpty) {
                streamMessages[streamMessages.length - 1] = Message.text(
                  text: fullReply.toString(),
                  isUser: false,
                );
                emit(latestState.copyWith(messages: streamMessages));
              }
            }
          }
        },
        onError: (error, stack) {
          dev.log("Chat response stream error", name: 'CHAT_CUBIT', error: error, stackTrace: stack);
          _handleStreamError(error);
        },
        onDone: () async {
          dev.log("Chat response stream completed", name: 'CHAT_CUBIT');
          final finalState = state;
          if (finalState is ChatLoaded) {
            String responseText = fullReply.toString().trim();
            if (responseText.isEmpty) {
              responseText = _strings.chatEmptyFallback;
            }
            final finalModelMessage = Message.text(text: responseText, isUser: false);

            final updatedList = List<Message>.from(finalState.messages);
            if (updatedList.isNotEmpty && !updatedList.last.isUser) {
              updatedList[updatedList.length - 1] = finalModelMessage;
            } else {
              updatedList.add(finalModelMessage);
            }

            await saveChatMessage(finalModelMessage);
            emit(finalState.copyWith(messages: updatedList, isStreaming: false));
          }
        },
        cancelOnError: true,
      );
    } catch (e, stack) {
      dev.log("Error in sendMessage", name: 'CHAT_CUBIT', error: e, stackTrace: stack);
      _handleStreamError(e);
    }
  }

  void _handleStreamError(Object error) {
    final errorMsg = error.toString();
    final isMissingModel = error is ModelNotInstalledException ||
        errorMsg.contains('SautiLM-Jua-Agri') ||
        errorMsg.contains('pas encore téléchargé') ||
        errorMsg.contains('introuvable');

    final currentState = state;
    if (currentState is ChatLoaded) {
      final streamMessages = List<Message>.from(currentState.messages);
      if (streamMessages.isNotEmpty && !streamMessages.last.isUser && streamMessages.last.text.isEmpty) {
        streamMessages.removeLast();
      }
      if (isMissingModel) {
        streamMessages.add(Message.text(text: _strings.chatMissingModelPrompt, isUser: false));
        emit(currentState.copyWith(
          messages: streamMessages,
          isStreaming: false,
          isModelMissing: true,
        ));
        return;
      }
      final errorModelMessage = Message.text(
        text: _strings.chatErrorFallback,
        isUser: false,
      );
      streamMessages.add(errorModelMessage);
      saveChatMessage(errorModelMessage);
      emit(currentState.copyWith(messages: streamMessages, isStreaming: false));
    } else {
      emit(ChatError(errorMsg));
    }
  }

  Future<void> clearConversation() async {
    emit(ChatLoading());
    try {
      dev.log("Clearing chat conversation...", name: 'CHAT_CUBIT');
      await clearChat();
      final missing = await _isModelMissingNow();
      final welcome = Message.text(
        text: _strings.chatWelcome,
        isUser: false,
      );
      emit(ChatLoaded(
        messages: [welcome],
        isStreaming: false,
        isModelMissing: missing,
      ));
    } catch (e, stack) {
      dev.log("Error clearing conversation", name: 'CHAT_CUBIT', error: e, stackTrace: stack);
      emit(ChatError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
