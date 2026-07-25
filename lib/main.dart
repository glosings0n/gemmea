import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gemmea/core/core.dart';
import 'package:gemmea/data/data.dart';
import 'package:gemmea/domain/domain.dart';
import 'package:gemmea/presentation/presentation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep system status bar icons dark in light mode
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  // Force the app to stay in portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Create repository instances
  final chatRepo = ChatRepositoryImpl();
  final diagnosticRepo = DiagnosticRepositoryImpl();
  final calendarRepo = CalendarRepositoryImpl();

  runApp(
    GemmeaApp(
      chatRepo: chatRepo,
      diagnosticRepo: diagnosticRepo,
      calendarRepo: calendarRepo,
    ),
  );
}

class GemmeaApp extends StatelessWidget {
  final ChatRepositoryImpl chatRepo;
  final DiagnosticRepositoryImpl diagnosticRepo;
  final CalendarRepositoryImpl calendarRepo;

  const GemmeaApp({
    super.key,
    required this.chatRepo,
    required this.diagnosticRepo,
    required this.calendarRepo,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<InitializationCubit>(
          create: (context) => InitializationCubit(
            checkModelInstalled: CheckModelInstalled(chatRepo),
            initializeGemma: InitializeGemma(chatRepo),
          ),
        ),
        BlocProvider<HomeCubit>(
          create: (context) => HomeCubit(
            getDiagnostics: GetDiagnostics(diagnosticRepo),
            getCalendarEvents: GetCalendarEvents(calendarRepo),
            runCropScan: RunCropScan(diagnosticRepo),
            updateRainStatus: UpdateRainStatus(calendarRepo),
            markDiagnosticsAsRead: MarkDiagnosticsAsRead(diagnosticRepo),
            deleteDiagnosticUsecase: DeleteDiagnostic(diagnosticRepo),
          ),
        ),
        BlocProvider<ChatCubit>(
          create: (context) => ChatCubit(
            getChatMessages: GetChatMessages(chatRepo),
            saveChatMessage: SaveChatMessage(chatRepo),
            getGemmaResponseStream: GetGemmaResponseStream(chatRepo),
            clearChat: ClearChat(chatRepo),
            addCalendarEvent: AddCalendarEvent(calendarRepo),
            updateRainStatus: UpdateRainStatus(calendarRepo),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Gemmea',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const InitializationScreen(),
      ),
    );
  }
}
