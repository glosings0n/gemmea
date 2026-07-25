import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:gemmea/domain/entities/calendar_event.dart';
import 'package:gemmea/domain/usecases/chat_usecases.dart';
import 'package:gemmea/domain/usecases/calendar_usecases.dart';
import 'package:gemmea/presentation/bloc/chat_cubit.dart';

class MockGetChatMessages extends Mock implements GetChatMessages {}
class MockSaveChatMessage extends Mock implements SaveChatMessage {}
class MockGetGemmaResponseStream extends Mock implements GetGemmaResponseStream {}
class MockClearChat extends Mock implements ClearChat {}
class MockAddCalendarEvent extends Mock implements AddCalendarEvent {}
class MockUpdateRainStatus extends Mock implements UpdateRainStatus {}

class FakeMessage extends Fake implements Message {}
class FakeCalendarEvent extends Fake implements CalendarEvent {}

class FakeTextResponse extends Mock implements TextResponse {
  @override
  final String token;
  FakeTextResponse(this.token);
}

void main() {
  late MockGetChatMessages mockGetChatMessages;
  late MockSaveChatMessage mockSaveChatMessage;
  late MockGetGemmaResponseStream mockGetGemmaResponseStream;
  late MockClearChat mockClearChat;
  late MockAddCalendarEvent mockAddCalendarEvent;
  late MockUpdateRainStatus mockUpdateRainStatus;
  late ChatCubit chatCubit;

  setUpAll(() {
    registerFallbackValue(FakeMessage());
    registerFallbackValue(FakeCalendarEvent());
  });

  setUp(() {
    mockGetChatMessages = MockGetChatMessages();
    mockSaveChatMessage = MockSaveChatMessage();
    mockGetGemmaResponseStream = MockGetGemmaResponseStream();
    mockClearChat = MockClearChat();
    mockAddCalendarEvent = MockAddCalendarEvent();
    mockUpdateRainStatus = MockUpdateRainStatus();

    chatCubit = ChatCubit(
      getChatMessages: mockGetChatMessages,
      saveChatMessage: mockSaveChatMessage,
      getGemmaResponseStream: mockGetGemmaResponseStream,
      clearChat: mockClearChat,
      addCalendarEvent: mockAddCalendarEvent,
      updateRainStatus: mockUpdateRainStatus,
    );
  });

  tearDown(() {
    chatCubit.close();
  });

  group('Autonomous Irrigation & Water Schedule Function Calling Tests', () {
    blocTest<ChatCubit, ChatState>(
      'sendMessage with dry/hot keywords activates autonomous irrigation Function Call and updates calendar',
      build: () {
        when(() => mockSaveChatMessage.call(any())).thenAnswer((_) async {});
        when(() => mockUpdateRainStatus.call(any(), any())).thenAnswer((_) async {});
        when(() => mockGetGemmaResponseStream.call(any(), any())).thenAnswer((_) {
          final controller = StreamController<ModelResponse>();
          scheduleMicrotask(() {
            controller.add(FakeTextResponse("Pour "));
            controller.add(FakeTextResponse("le maïs, apportez 4L d'eau par mètre carré."));
            controller.close();
          });
          return controller.stream;
        });

        chatCubit.emit(ChatLoaded(messages: [], isStreaming: false));
        return chatCubit;
      },
      act: (cubit) => cubit.sendMessage("Il fait très chaud et sec, combien d'eau faut-il pour l'arrosage ?"),
      wait: const Duration(milliseconds: 150),
      expect: () => [
        isA<ChatLoaded>().having((s) => s.messages.length, 'user msg', 1),
        isA<ChatLoaded>().having(
          (s) => s.systemNotification,
          'function call notification',
          contains("Calendrier ajusté : Arrosage régulier programmé pour temps sec."),
        ),
        isA<ChatLoaded>().having(
          (s) => s.messages.last.text,
          'token 1',
          "Pour ",
        ),
        isA<ChatLoaded>().having(
          (s) => s.messages.last.text,
          'full response',
          "Pour le maïs, apportez 4L d'eau par mètre carré.",
        ),
        isA<ChatLoaded>().having((s) => s.isStreaming, 'stream done', false),
      ],
      verify: (_) {
        verify(() => mockUpdateRainStatus.call(any(), false)).called(2);
      },
    );
  });
}
