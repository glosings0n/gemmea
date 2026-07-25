import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:image/image.dart' as img;

abstract class GemmaLocalSource {
  Future<String> evaluateCropImage(File imageFile, String prompt);
}

class GemmaLocalSourceImpl implements GemmaLocalSource {
  static bool _isEngineInitialized = false;

  static Future<void> _ensureEngineInitialized() async {
    if (!_isEngineInitialized) {
      try {
        dev.log("Initializing FlutterGemma LiteRT-LM Engine for VLM...", name: 'GEMMA_LOCAL_SOURCE');
        await FlutterGemma.initialize(
          inferenceEngines: const [LiteRtLmEngine()],
        );
        _isEngineInitialized = true;
      } catch (e, stack) {
        dev.log("VLM Engine initialization note: $e", name: 'GEMMA_LOCAL_SOURCE', error: e, stackTrace: stack);
      }
    }
  }

  @override
  Future<String> evaluateCropImage(File imageFile, String prompt) async {
    try {
      await _ensureEngineInitialized();
      if (!await imageFile.exists()) {
        throw Exception("L'image capturée ne semble pas être une feuille de plante. Veuillez reprendre une photo en ciblant clairement une feuille de votre culture.");
      }

      dev.log("Reading image bytes for evaluation: ${imageFile.path}", name: 'GEMMA_LOCAL_SOURCE');
      Uint8List imageBytes = await imageFile.readAsBytes();

      if (imageBytes.isEmpty) {
        throw Exception("L'image capturée ne semble pas être une feuille de plante. Veuillez reprendre une photo en ciblant clairement une feuille de votre culture.");
      }

      // Preprocess image bytes to fit Gemma VLM patch/tensor dimensions safely (max 384x384)
      try {
        final img.Image? decoded = img.decodeImage(imageBytes);
        if (decoded != null) {
          const int maxDim = 384;
          if (decoded.width > maxDim || decoded.height > maxDim) {
            final img.Image resized = img.copyResize(
              decoded,
              width: decoded.width >= decoded.height ? maxDim : null,
              height: decoded.height > decoded.width ? maxDim : null,
              interpolation: img.Interpolation.linear,
            );
            imageBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
            dev.log("Preprocessed and resized image to ${resized.width}x${resized.height} (${imageBytes.length} bytes) for Gemma VLM", name: 'GEMMA_LOCAL_SOURCE');
          }
        }
      } catch (e) {
        dev.log("Image preprocessing note: $e", name: 'GEMMA_LOCAL_SOURCE');
      }

      InferenceModel model;
      try {
        dev.log("Attempting CPU backend initialization for VLM evaluation...", name: 'GEMMA_LOCAL_SOURCE');
        model = await FlutterGemma.getActiveModel(
          preferredBackend: PreferredBackend.cpu,
          maxTokens: 1024,
          supportImage: true,
        );
      } catch (e) {
        dev.log("CPU VLM init failed, trying fallback default backend...", name: 'GEMMA_LOCAL_SOURCE', error: e);
        model = await FlutterGemma.getActiveModel(
          maxTokens: 1024,
          supportImage: true,
        );
      }
      final session = await model.createSession();
      
      // Send preprocessed image bytes to Gemma VLM engine with agronomy evaluation prompt
      await session.addQueryChunk(
        Message.withImage(
          text: "Look closely at this image. Is this a crop leaf? If yes, diagnose any visible plant disease, identify the crop, and provide localized organic remedies. If it is NOT a crop leaf or not a plant, reply strictly 'NOT_A_LEAF'. Prompt: $prompt",
          imageBytes: imageBytes,
          isUser: true,
        ),
      );
      
      final String response = await session.getResponse();
      dev.log("Gemma VLM evaluation response: $response", name: 'GEMMA_LOCAL_SOURCE');

      final lowerResp = response.toLowerCase();

      // Check if Gemma identified that the image is not a leaf or plant
      if (response.contains("NOT_A_LEAF") || 
          lowerResp.contains("not a leaf") || 
          lowerResp.contains("pas une feuille") ||
          lowerResp.contains("pas une plante") ||
          lowerResp.contains("ce n'est pas une feuille")) {
        throw Exception("L'image capturée ne semble pas être une feuille de plante. Veuillez reprendre une photo en ciblant clairement une feuille de votre culture.");
      }

      if (response.trim().isEmpty || lowerResp.contains("processing error") || lowerResp.contains("veuillez fournir")) {
        throw Exception("L'image capturée ne semble pas être une feuille de plante. Veuillez reprendre une photo en ciblant clairement une feuille de votre culture.");
      }

      return response;
    } catch (e, stack) {
      dev.log("On-device VLM image evaluation error", name: 'GEMMA_LOCAL_SOURCE', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
