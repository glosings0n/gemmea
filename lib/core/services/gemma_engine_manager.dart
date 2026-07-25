import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

class GemmaEngineManager {
  static bool _isInitialized = false;
  static Completer<void>? _initCompleter;

  static bool get isInitialized => _isInitialized;

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
}
