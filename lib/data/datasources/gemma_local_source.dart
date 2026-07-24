import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';

abstract class GemmaLocalSource {
  Future<String> evaluateCropImage(File imageFile, String prompt);
}

class GemmaLocalSourceImpl implements GemmaLocalSource {
  @override
  Future<String> evaluateCropImage(File imageFile, String prompt) async {
    try {
      // 1. Convert the local file into a byte array
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // 2. Fetch the active Gemma 4 E2B LiteRT instance with image support enabled
      final model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        supportImage: true,
      );
      final session = await model.createSession();
      
      // 3. Pass BOTH the image bytes and text natively to the model in a single offline VLM pass
      await session.addQueryChunk(
        Message.withImage(
          text: "You are an expert agronomist. Look closely at this image of the crop leaf. "
                "Diagnose the visible disease and offer organic local solutions. Context: $prompt",
          imageBytes: imageBytes,
          isUser: true,
        ),
      );
      
      final String response = await session.getResponse();
      return response;
    } catch (e) {
      return "On-device processing error: ${e.toString()}";
    }
  }
}
