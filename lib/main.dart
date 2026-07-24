import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:gemmea/core/theme/app_theme.dart';
import 'package:gemmea/data/repositories/calendar_repository_impl.dart';
import 'package:gemmea/data/repositories/chat_repository_impl.dart';
import 'package:gemmea/data/repositories/diagnostic_repository_impl.dart';
import 'package:gemmea/domain/usecases/calendar_usecases.dart';
import 'package:gemmea/domain/usecases/chat_usecases.dart';
import 'package:gemmea/domain/usecases/diagnostic_usecases.dart';
import 'package:gemmea/presentation/bloc/chat_cubit.dart';
import 'package:gemmea/presentation/bloc/home_cubit.dart';
import 'package:gemmea/presentation/bloc/initialization_cubit.dart';
import 'package:gemmea/presentation/pages/initialization_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep system status bar icons dark in light mode
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  // Initialize FlutterGemma plugin immediately on startup with LiteRT-LM engine
  try {
    await FlutterGemma.initialize(
      inferenceEngines: const [LiteRtLmEngine()],
    );
  } catch (e) {
    dev.log("Error initializing FlutterGemma", error: e, name: "main");
  }

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
