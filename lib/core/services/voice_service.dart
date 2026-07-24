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
    if (!_isSpeechInitialized) {
      _isSpeechInitialized = await _speech.initialize(
        onError: (val) => _isListening = false,
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            _isListening = false;
          }
        },
      );
    }

    // Configure TTS defaults
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.85); // Gentle rate for farmers

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
    });

    return _isSpeechInitialized;
  }

  Future<void> startListening({
    required Function(String text) onResult,
    required Function() onDone,
  }) async {
    final available = await initVoice();
    if (!available) {
      onDone();
      return;
    }

    _isListening = true;
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
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await initVoice();

    // Clean markdown characters before reading out
    final cleanText = text
        .replaceAll(RegExp(r'[\*#_`~]'), '')
        .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '');

    if (_isSpeaking) {
      await stopSpeaking();
    }

    await _flutterTts.speak(cleanText);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }
}
