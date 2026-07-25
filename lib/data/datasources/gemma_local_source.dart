import 'dart:developer' as dev;
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
      if (!await imageFile.exists()) {
        throw Exception("Veuillez fournir une image de feuille valide.");
      }

      dev.log("Reading image bytes for evaluation...", name: 'GEMMA_LOCAL_SOURCE');
      final Uint8List imageBytes = await imageFile.readAsBytes();

      if (imageBytes.isEmpty) {
        throw Exception("Veuillez fournir une image de feuille valide.");
      }

      dev.log("Fetching active Gemma VLM model instance...", name: 'GEMMA_LOCAL_SOURCE');
      final model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        supportImage: true,
      );
      final session = await model.createSession();
      
      dev.log("Sending query chunk with image to Gemma session...", name: 'GEMMA_LOCAL_SOURCE');
      await session.addQueryChunk(
        Message.withImage(
          text: "You are an expert agronomist. Look closely at this image of the crop leaf. "
                "Diagnose the visible disease and offer organic local solutions. Context: $prompt",
          imageBytes: imageBytes,
          isUser: true,
        ),
      );
      
      final String response = await session.getResponse();
      dev.log("Gemma VLM evaluation response received", name: 'GEMMA_LOCAL_SOURCE');

      final lowerRes = response.toLowerCase();
      if (response.trim().isEmpty || 
          lowerRes.contains("veuillez fournir une image") ||
          lowerRes.contains("please provide an image") ||
          lowerRes.contains("processing error") ||
          lowerRes.contains("error")) {
        throw Exception("Veuillez fournir une image claire d'une feuille de culture.");
      }

      return response;
    } catch (e, stack) {
      dev.log("On-device VLM image evaluation error", name: 'GEMMA_LOCAL_SOURCE', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
