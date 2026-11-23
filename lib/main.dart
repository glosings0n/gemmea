import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:juamea/core/core.dart';
import 'package:juamea/data/data.dart';
import 'package:juamea/domain/domain.dart';
import 'package:juamea/presentation/presentation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep system status bar icons dark in light mode
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  // Force the app to stay in portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Non-blocking Shorebird OTA patch check for production releases
  ShorebirdService().checkForUpdatesAndDownload();

  // Create repository instances
  final chatRepo = ChatRepositoryImpl();
  final diagnosticRepo = DiagnosticRepositoryImpl();
  final calendarRepo = CalendarRepositoryImpl();

  runApp(
    JuameaApp(
      chatRepo: chatRepo,
      diagnosticRepo: diagnosticRepo,
      calendarRepo: calendarRepo,
    ),
  );
}

class JuameaApp extends StatelessWidget {
  final ChatRepositoryImpl chatRepo;
  final DiagnosticRepositoryImpl diagnosticRepo;
  final CalendarRepositoryImpl calendarRepo;

  const JuameaApp({
    super.key,
    required this.chatRepo,
    required this.diagnosticRepo,
    required this.calendarRepo,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocaleCubit>(
          create: (context) => LocaleCubit()..loadSavedLanguage(),
        ),
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
            checkModelInstalled: CheckModelInstalled(chatRepo),
          ),
        ),
        BlocProvider<ScanCubit>(
          create: (context) => ScanCubit(GemmaLocalSourceImpl()),
        ),
      ],
      child: MaterialApp(
        title: 'Juamea',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const InitializationScreen(),
      ),
    );
  }
}
