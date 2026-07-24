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
      final isInstalled = await checkModelInstalled();
      if (isInstalled) {
        emit(InitializationSuccess());
      } else {
        emit(InitializationDownloading(0.0));
      }
    } catch (e) {
      emit(InitializationFailure(e.toString()));
    }
  }

  Future<void> startDownload() async {
    emit(InitializationCheckingConnection());
    // Provide a beautiful 1.2s check delay to give satisfying feedback to the user on connection testing
    await Future.delayed(const Duration(milliseconds: 1200));
    try {
      await initializeGemma((progress) {
        emit(InitializationDownloading(progress));
      });
      emit(InitializationSuccess());
    } catch (e) {
      emit(InitializationFailure(e.toString()));
    }
  }
}
