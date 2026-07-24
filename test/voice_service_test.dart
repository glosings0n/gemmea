import 'package:flutter_test/flutter_test.dart';
import 'package:gemmea/core/services/voice_service.dart';

void main() {
  group('VoiceService Tests', () {
    test('instance is a singleton', () {
      final v1 = VoiceService.instance;
      final v2 = VoiceService.instance;
      expect(v1, same(v2));
    });

    test('isListening and isSpeaking default to false', () {
      final voice = VoiceService.instance;
      expect(voice.isListening, false);
      expect(voice.isSpeaking, false);
    });
  });
}
