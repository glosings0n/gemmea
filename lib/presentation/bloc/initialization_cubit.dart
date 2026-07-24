import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gemmea/domain/usecases/chat_usecases.dart';

abstract class InitializationState {}

class InitializationInitial extends InitializationState {}

class InitializationChecking extends InitializationState {}

class InitializationDownloading extends InitializationState {
  final double progress;
  InitializationDownloading(this.progress);
}

class InitializationSuccess extends InitializationState {}

class InitializationCheckingConnection extends InitializationState {}

class InitializationFailure extends InitializationState {
  final String error;
  InitializationFailure(this.error);
}

class InitializationCubit extends Cubit<InitializationState> {
  final CheckModelInstalled checkModelInstalled;
  final InitializeGemma initializeGemma;

  InitializationCubit({
    required this.checkModelInstalled,
    required this.initializeGemma,
  }) : super(InitializationInitial());

  Future<void> checkStatus() async {
    emit(InitializationChecking());
    try {
      dev.log("Checking Gemma model status...", name: 'INITIALIZATION_CUBIT');
      final isInstalled = await checkModelInstalled();
      if (isInstalled) {
        dev.log("Gemma model installed and verified", name: 'INITIALIZATION_CUBIT');
        emit(InitializationSuccess());
      } else {
        dev.log("Gemma model not found locally", name: 'INITIALIZATION_CUBIT');
        emit(InitializationDownloading(0.0));
      }
    } catch (e, stack) {
      dev.log("Error checking model status", name: 'INITIALIZATION_CUBIT', error: e, stackTrace: stack);
      emit(InitializationFailure(e.toString()));
    }
  }

  Future<void> startDownload() async {
    emit(InitializationCheckingConnection());
    try {
      dev.log("Testing connection and starting download/init process...", name: 'INITIALIZATION_CUBIT');
      await Future.delayed(const Duration(milliseconds: 1200));
      await initializeGemma((progress) {
        dev.log("Model init progress: ${(progress * 100).toStringAsFixed(1)}%", name: 'INITIALIZATION_CUBIT');
        emit(InitializationDownloading(progress));
      });
      dev.log("Model download/init complete", name: 'INITIALIZATION_CUBIT');
      emit(InitializationSuccess());
    } catch (e, stack) {
      dev.log("Error during model download/init", name: 'INITIALIZATION_CUBIT', error: e, stackTrace: stack);
      emit(InitializationFailure(e.toString()));
    }
  }
}
