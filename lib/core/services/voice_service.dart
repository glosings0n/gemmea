import 'dart:developer' as dev;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  static final VoiceService instance = VoiceService._init();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeechInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  VoiceService._init();

  Future<bool> initVoice() async {
    try {
      if (!_isSpeechInitialized) {
        dev.log("Initializing SpeechToText engine...", name: 'VOICE_SERVICE');
        _isSpeechInitialized = await _speech.initialize(
          onError: (val) {
            dev.log("STT error event: ${val.errorMsg}", name: 'VOICE_SERVICE');
            _isListening = false;
          },
          onStatus: (val) {
            dev.log("STT status: $val", name: 'VOICE_SERVICE');
            if (val == 'done' || val == 'notListening') {
              _isListening = false;
            }
          },
        );
      }

      // Configure TTS defaults
      dev.log("Configuring FlutterTts settings...", name: 'VOICE_SERVICE');
      await _flutterTts.setLanguage("fr-FR");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.85); // Gentle rate for farmers

      _flutterTts.setStartHandler(() {
        dev.log("TTS playback started", name: 'VOICE_SERVICE');
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        dev.log("TTS playback completed", name: 'VOICE_SERVICE');
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        dev.log("TTS playback error: $msg", name: 'VOICE_SERVICE');
        _isSpeaking = false;
      });

      return _isSpeechInitialized;
    } catch (e, stack) {
      dev.log("Error initializing VoiceService", name: 'VOICE_SERVICE', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<void> startListening({
    required Function(String text) onResult,
    required Function() onDone,
  }) async {
    try {
      final available = await initVoice();
      if (!available) {
        dev.log("Voice STT unavailable on device", name: 'VOICE_SERVICE');
        onDone();
        return;
      }

      _isListening = true;
      dev.log("Starting STT listening session...", name: 'VOICE_SERVICE');
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
        onResult: (val) {
          onResult(val.recognizedWords);
          if (val.finalResult) {
            _isListening = false;
            onDone();
          }
        },
      );
    } catch (e, stack) {
      dev.log("Error during startListening", name: 'VOICE_SERVICE', error: e, stackTrace: stack);
      _isListening = false;
      onDone();
    }
  }

  Future<void> stopListening() async {
    try {
      if (_isListening) {
        dev.log("Stopping STT listening session...", name: 'VOICE_SERVICE');
        await _speech.stop();
        _isListening = false;
      }
    } catch (e, stack) {
      dev.log("Error during stopListening", name: 'VOICE_SERVICE', error: e, stackTrace: stack);
      _isListening = false;
    }
  }

  Future<void> speak(String text) async {
    try {
      if (text.isEmpty) return;
      await initVoice();

      // Clean markdown characters before reading out
      final cleanText = text
          .replaceAll(RegExp(r'[\*#_`~]'), '')
          .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '');

      if (_isSpeaking) {
        await stopSpeaking();
      }

      dev.log("Speaking text via TTS (${cleanText.length} chars)...", name: 'VOICE_SERVICE');
      await _flutterTts.speak(cleanText);
    } catch (e, stack) {
      dev.log("Error during speak", name: 'VOICE_SERVICE', error: e, stackTrace: stack);
      _isSpeaking = false;
    }
  }

  Future<void> stopSpeaking() async {
    try {
      dev.log("Stopping TTS playback...", name: 'VOICE_SERVICE');
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e, stack) {
      dev.log("Error during stopSpeaking", name: 'VOICE_SERVICE', error: e, stackTrace: stack);
      _isSpeaking = false;
    }
  }
}
