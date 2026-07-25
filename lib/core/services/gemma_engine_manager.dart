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

  /// Force clears stale lock state and resets chat session on Hot Reload or FFI error.
  static void forceResetLockState() {
    dev.log("Force resetting GemmaEngineManager lock state and session handles.", name: 'GEMMA_ENGINE_MANAGER');
    _activeExecution = null;
    _initCompleter = null;
    resetChatSession();
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
      dev.log("Engine initialization note (FFI native engine already initialized or bound): $e", name: 'GEMMA_ENGINE_MANAGER', error: e, stackTrace: stack);
      _isInitialized = true; // Mark true to avoid repeated native init calls
      if (!(_initCompleter?.isCompleted ?? true)) {
        _initCompleter!.complete();
      }
    } finally {
      _initCompleter = null;
    }
  }

  /// Wraps a Future operation to ensure single-threaded execution on the Gemma native engine
  /// with timeout protection against Hot Reload / deadlocked isolate locks.
  static Future<T> runWithLock<T>(Future<T> Function() action) async {
    final previousExecution = _activeExecution;
    final completer = Completer<void>();
    _activeExecution = completer.future;

    if (previousExecution != null) {
      dev.log("Waiting for previous Gemma engine operation to finish (with 8s Hot Reload timeout)...", name: 'GEMMA_ENGINE_MANAGER');
      try {
        await previousExecution.timeout(const Duration(seconds: 8));
      } on TimeoutException {
        dev.log("Previous engine execution timed out (likely Hot Reload / orphaned isolate). Clearing stale lock.", name: 'GEMMA_ENGINE_MANAGER');
        forceResetLockState();
      } catch (_) {}
    }

    try {
      return await action();
    } catch (e) {
      // If a native FFI or channel error occurs, clear chat session handle
      if (e.toString().contains("channel-error") || e.toString().contains("PlatformException") || e.toString().contains("Null")) {
        forceResetLockState();
      }
      rethrow;
    } finally {
      completer.complete();
      if (_activeExecution == completer.future) {
        _activeExecution = null;
      }
    }
  }

  /// Wraps a Stream operation to ensure single-threaded execution on the Gemma native engine
  /// with timeout protection against Hot Reload / deadlocked isolate locks.
  static Stream<T> runStreamWithLock<T>(Stream<T> Function() streamFactory) async* {
    final previousExecution = _activeExecution;
    final completer = Completer<void>();
    _activeExecution = completer.future;

    if (previousExecution != null) {
      dev.log("Waiting for previous Gemma engine operation to finish before streaming (with 8s Hot Reload timeout)...", name: 'GEMMA_ENGINE_MANAGER');
      try {
        await previousExecution.timeout(const Duration(seconds: 8));
      } on TimeoutException {
        dev.log("Previous engine stream execution timed out (likely Hot Reload / orphaned isolate). Clearing stale lock.", name: 'GEMMA_ENGINE_MANAGER');
        forceResetLockState();
      } catch (_) {}
    }

    try {
      await for (final value in streamFactory()) {
        yield value;
      }
    } catch (e) {
      if (e.toString().contains("channel-error") || e.toString().contains("PlatformException") || e.toString().contains("Null")) {
        forceResetLockState();
      }
      rethrow;
    } finally {
      completer.complete();
      if (_activeExecution == completer.future) {
        _activeExecution = null;
      }
    }
  }
}

