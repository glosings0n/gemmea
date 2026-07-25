import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

class GemmaEngineManager {
  static bool _isInitialized = false;
  static Completer<void>? _initCompleter;
  static Future<void>? _activeExecution;
  static Function()? _onResetChatCallback;

  static bool get isInitialized => _isInitialized;
  static bool get isBusy => _activeExecution != null;

  static void setResetChatCallback(Function() callback) {
    _onResetChatCallback = callback;
  }

  static void resetChatSession() {
    if (_onResetChatCallback != null) {
      try {
        dev.log("Resetting cached chat session in GemmaEngineManager", name: 'GEMMA_ENGINE_MANAGER');
        _onResetChatCallback!();
      } catch (e) {
        dev.log("Error calling reset chat callback: $e", name: 'GEMMA_ENGINE_MANAGER');
      }
    }
  }

  static Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();
    try {
      dev.log("Initializing FlutterGemma LiteRT-LM Engine centrally...", name: 'GEMMA_ENGINE_MANAGER');
      await FlutterGemma.initialize(
        inferenceEngines: const [LiteRtLmEngine()],
      );
      _isInitialized = true;
      dev.log("FlutterGemma engine initialized successfully", name: 'GEMMA_ENGINE_MANAGER');
      _initCompleter!.complete();
    } catch (e, stack) {
      dev.log("Engine initialization note: $e", name: 'GEMMA_ENGINE_MANAGER', error: e, stackTrace: stack);
      _isInitialized = true; // Mark true to avoid repeated native init calls
      _initCompleter!.complete();
    } finally {
      _initCompleter = null;
    }
  }

  /// Wraps a Future operation to ensure single-threaded execution on the Gemma native engine.
  static Future<T> runWithLock<T>(Future<T> Function() action) async {
    final previousExecution = _activeExecution;
    final completer = Completer<void>();
    _activeExecution = completer.future;

    if (previousExecution != null) {
      dev.log("Waiting for previous Gemma engine operation to finish...", name: 'GEMMA_ENGINE_MANAGER');
      try {
        await previousExecution;
      } catch (_) {}
    }

    try {
      return await action();
    } finally {
      completer.complete();
      if (_activeExecution == completer.future) {
        _activeExecution = null;
      }
    }
  }

  /// Wraps a Stream operation to ensure single-threaded execution on the Gemma native engine.
  static Stream<T> runStreamWithLock<T>(Stream<T> Function() streamFactory) async* {
    final previousExecution = _activeExecution;
    final completer = Completer<void>();
    _activeExecution = completer.future;

    if (previousExecution != null) {
      dev.log("Waiting for previous Gemma engine operation to finish before streaming...", name: 'GEMMA_ENGINE_MANAGER');
      try {
        await previousExecution;
      } catch (_) {}
    }

    try {
      await for (final value in streamFactory()) {
        yield value;
      }
    } finally {
      completer.complete();
      if (_activeExecution == completer.future) {
        _activeExecution = null;
      }
    }
  }
}
