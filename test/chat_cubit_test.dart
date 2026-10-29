import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
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

  group('ChatCubit Tests', () {
    test('initial state is ChatInitial', () {
      expect(chatCubit.state, isA<ChatInitial>());
    });

    blocTest<ChatCubit, ChatState>(
      'loadChatHistory emits ChatLoading then ChatLoaded with welcome message when empty',
      build: () {
        when(() => mockGetChatMessages.call()).thenAnswer((_) async => []);
        return chatCubit;
      },
      act: (cubit) => cubit.loadChatHistory(),
      expect: () => [
        isA<ChatLoading>(),
        isA<ChatLoaded>().having(
          (s) => s.messages.first.text,
          'welcome message text',
          contains("Jambo 👋🏾 ! Je suis Gemmea"),
        ),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'loadChatHistory emits ChatLoading then ChatLoaded with list of messages when not empty',
      build: () {
        final messages = [
          Message.text(text: "Hello", isUser: true),
          Message.text(text: "Hi there!", isUser: false),
        ];
        when(() => mockGetChatMessages.call()).thenAnswer((_) async => messages);
        return chatCubit;
      },
      act: (cubit) => cubit.loadChatHistory(),
      expect: () => [
        isA<ChatLoading>(),
        isA<ChatLoaded>().having((s) => s.messages.length, 'messages count', 2),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'clearChatHistory clears and emits welcome state',
      build: () {
        when(() => mockClearChat.call()).thenAnswer((_) async {});
        return chatCubit;
      },
      act: (cubit) => cubit.clearConversation(),
      expect: () => [
        isA<ChatLoading>(),
        isA<ChatLoaded>().having(
          (s) => s.messages.first.text,
          'welcome message text',
          contains("Jambo 👋🏾 ! Je suis Gemmea"),
        ),
      ],
    );


    blocTest<ChatCubit, ChatState>(
      'sendMessage with "pleut" (rain keyword) triggers updateRainStatus function-calling flow and streams token',
      build: () {
        when(() => mockSaveChatMessage.call(any())).thenAnswer((_) async {});
        when(() => mockUpdateRainStatus.call(any(), any())).thenAnswer((_) async {});
        when(() => mockGetGemmaResponseStream.call(any(), any())).thenAnswer((_) {
          final controller = StreamController<ModelResponse>();
          scheduleMicrotask(() {
            controller.add(FakeTextResponse("En "));
            controller.add(FakeTextResponse("effet."));
            controller.close();
          });
          return controller.stream;
        });

        // Initialize to ChatLoaded first
        chatCubit.emit(ChatLoaded(messages: [], isStreaming: false));
        return chatCubit;
      },
      act: (cubit) => cubit.sendMessage("Il pleut aujourd'hui"),
      wait: const Duration(milliseconds: 150),
      expect: () => [
        // 1. Appends user message
        isA<ChatLoaded>().having((s) => s.messages.length, 'user msg appended', 1),
        // 2. Starts function calling notification + appends placeholder
        isA<ChatLoaded>().having(
          (s) => s.systemNotification,
          'system notice',
          contains("Calendrier ajusté : Arrosage mis en pause suite au signalement de pluie."),
        ),
        // 3. Receives first token
        isA<ChatLoaded>().having(
          (s) => s.messages.last.text,
          'first token stream',
          "En ",
        ),
        // 4. Receives second token
        isA<ChatLoaded>().having(
          (s) => s.messages.last.text,
          'full stream',
          "En effet.",
        ),
        // 5. Done streaming, finalizes state
        isA<ChatLoaded>().having((s) => s.isStreaming, 'done streaming', false),
      ],
      verify: (_) {
        verify(() => mockUpdateRainStatus.call(any(), true)).called(2);
        verify(() => mockSaveChatMessage.call(any())).called(2); // user and model final responses
      },
    );
  });
}
