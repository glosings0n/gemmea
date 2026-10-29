import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:gemmea/core/services/gemma_engine_manager.dart';

void main() {
  group('FlutterEdgeAi Migration & Engine Invariants', () {
    test('GemmaEngineManager exposes initialized and lock management properties', () {
      expect(GemmaEngineManager.isBusy, isFalse);
      GemmaEngineManager.forceResetLockState();
      expect(GemmaEngineManager.isBusy, isFalse);
    });

    test('FlutterEdgeAi models and message structures maintain contract parity', () {
      final userMessage = Message.text(text: 'Habari Gemmea', isUser: true);
      expect(userMessage.text, equals('Habari Gemmea'));
      expect(userMessage.isUser, isTrue);

      final modelMessage = Message.text(text: 'Jambo fermier', isUser: false);
      expect(modelMessage.text, equals('Jambo fermier'));
      expect(modelMessage.isUser, isFalse);
    });
  });
}
