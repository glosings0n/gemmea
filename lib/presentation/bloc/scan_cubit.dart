import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gemmea/core/utils/text_sanitizer.dart';
import 'package:gemmea/data/datasources/sqlite_helper.dart';
import '../../data/datasources/gemma_local_source.dart';

abstract class ScanState {}
class ScanInitial extends ScanState {}
class ScanProcessing extends ScanState {
  final File image;
  ScanProcessing(this.image);
}
class ScanSuccess extends ScanState {
  final String diagnosis;
  final File image;
  ScanSuccess(this.diagnosis, this.image);
}
class ScanFailure extends ScanState {
  final String error;
  final String title;
  final String userMessage;
  final bool isNotALeaf;

  ScanFailure(
    this.error, {
    String? title,
    String? userMessage,
    bool? isNotALeaf,
  })  : title = title ??
            ((error.contains("ne semble pas être une feuille") ||
                    error.contains("NOT_A_LEAF") ||
                    error.contains("clairement une feuille"))
                ? "Feuille non détectée"
                : "Une erreur est survenue"),
        userMessage = userMessage ??
            ((error.contains("ne semble pas être une feuille") ||
                    error.contains("NOT_A_LEAF") ||
                    error.contains("clairement une feuille"))
                ? "L'image capturée ne semble pas être une feuille de plante. Veuillez reprendre une photo en ciblant clairement une feuille de votre culture."
                : "L'analyse IA n'a pas pu se terminer sur votre appareil.\n\nVous pouvez réessayer en prenant une photo bien éclairée, ou fermer puis rouvrir l'application.\n\nSi le problème persiste, votre téléphone dispose peut-être de ressources mémoire trop limitées pour l'analyse IA locale."),
        isNotALeaf = isNotALeaf ??
            (error.contains("ne semble pas être une feuille") ||
                error.contains("NOT_A_LEAF") ||
                error.contains("clairement une feuille"));
}

class ScanCubit extends Cubit<ScanState> {
  final GemmaLocalSource localSource;

  ScanCubit(this.localSource) : super(ScanInitial());

  void reset() {
    emit(ScanInitial());
  }

  Future<void> analyzeCrop(File image) async {
    emit(ScanProcessing(image));
    try {
      dev.log("Analyzing crop image with local Gemma VLM in background...", name: 'SCAN_CUBIT');
      final diagnosticResult = await localSource.evaluateCropImage(
        image, 
        "Fournissez une analyse agronomique complète et très détaillée organisée selon les 7 rubriques FAO/IITA : Diagnostic Principal & Hypothèses, Symptômes Détaillés, Causes & Vecteurs (IITA), Remèdes Biologiques Étape par Étape, Gestion du Sol & Irrigation, Plan d'Action Immédiat, Directives & Sources Officielles FAO."
      );

      final cleanDiagnostic = TextSanitizer.cleanLatexAndFormatting(diagnosticResult);
      final textLower = cleanDiagnostic.toLowerCase().trim();

      // Check if model explicitly indicated the image is not a leaf or valid crop
      final isNonLeaf = textLower.contains("ne semble pas être une feuille") ||
          textLower.contains("ne semble pas etre une feuille") ||
          textLower.contains("ceci n'est pas une feuille") ||
          textLower.contains("ceci ne semble pas être une feuille") ||
          textLower.contains("veuillez reprendre une photo") ||
          textLower.contains("pas une feuille de plante") ||
          textLower.contains("feuille non détectée") ||
          textLower.contains("pas une feuille") ||
          textLower.contains("pas de feuille") ||
          textLower.contains("pas une plante") ||
          textLower.contains("pas de plante") ||
          textLower.contains("pas une culture") ||
          textLower.contains("non-feuille") ||
          textLower.contains("aucun végétal") ||
          textLower.contains("ceci n'est pas") ||
          textLower.contains("impossible d'identifier une feuille") ||
          textLower.contains("objet non agricole");

      if (isNonLeaf) {
        dev.log("Non-leaf detected by Gemma VLM. Aborting DB insert and emitting ScanFailure with isNotALeaf=true.", name: 'SCAN_CUBIT');
        emit(ScanFailure(
          "L'image capturée ne semble pas être une feuille de plante. Veuillez reprendre une photo en ciblant clairement une feuille de votre culture.",
          title: "Feuille non détectée",
          userMessage: "L'image capturée ne semble pas être une feuille de plante. Veuillez reprendre une photo en ciblant clairement une feuille de votre culture.",
          isNotALeaf: true,
        ));
        return;
      }

      // Extract details dynamically from local Gemma response
      String cropName = "Plante Agricole";
      String disease = "Feuille Saine";
      double confidence = 0.90;
      String remedy = cleanDiagnostic;

      // 1. Check if Gemma detected HEALTHY / NO DISEASE first
      final isHealthy = textLower.contains("aucune maladie") ||
          textLower.contains("pas de maladie") ||
          textLower.contains("feuille saine") ||
          textLower.contains("plante saine") ||
          textLower.contains("aucun symptôme") ||
          textLower.contains("aucun symptome") ||
          textLower.contains("aucun stress pathogène") ||
          textLower.contains("pas d'infection") ||
          textLower.contains("sain") ||
          textLower.contains("saine");

      // 2. Extract Crop Name
      final cropMatch = RegExp(r'Culture\s*:\s*([^\n\.\-\(\)]+)', caseSensitive: false).firstMatch(cleanDiagnostic);
      if (cropMatch != null && cropMatch.group(1) != null) {
        final extractedCrop = cropMatch.group(1)!.trim();
        if (extractedCrop.length > 2 && extractedCrop.length < 35 &&
            !extractedCrop.toLowerCase().contains("inconnue") &&
            !extractedCrop.toLowerCase().contains("plante")) {
          cropName = extractedCrop;
        }
      }

      if (cropName == "Plante Agricole" || cropName.toLowerCase().contains("inconnue")) {
        if (textLower.contains("maïs") || textLower.contains("mais") || textLower.contains("maize") || textLower.contains("céréale")) {
          cropName = "Maïs";
        } else if (textLower.contains("manioc") || textLower.contains("cassava")) {
          cropName = "Manioc";
        } else if (textLower.contains("haricot") || textLower.contains("bean")) {
          cropName = "Haricot";
        } else if (textLower.contains("bananier") || textLower.contains("banane")) {
          cropName = "Banane";
        } else if (textLower.contains("café")) {
          cropName = "Café";
        } else if (textLower.contains("tomate")) {
          cropName = "Tomate";
        } else if (textLower.contains("patate")) {
          cropName = "Patate Douce";
        } else if (textLower.contains("riz")) {
          cropName = "Riz";
        }
      }

      // 3. Extract Disease Name
      if (isHealthy) {
        disease = "Feuille Saine";
      } else {
        final diseaseMatch = RegExp(r'Maladie(?:\s*suspectée)?\s*:\s*([^\n\.\(\)]+)', caseSensitive: false).firstMatch(cleanDiagnostic);
        if (diseaseMatch != null && diseaseMatch.group(1) != null) {
          final extractedDisease = diseaseMatch.group(1)!.trim();
          if (extractedDisease.length > 2 && extractedDisease.length < 50 &&
              !extractedDisease.toLowerCase().contains("aucune") &&
              !extractedDisease.toLowerCase().contains("saine")) {
            disease = extractedDisease;
          }
        }

        if (disease == "Feuille Saine") {
          if (textLower.contains("mosaïque") || textLower.contains("mosaic")) {
            disease = cropName.contains("Manioc") ? "Mosaïque du Manioc" : "Mosaïque Virale";
          } else if (textLower.contains("rouille") || textLower.contains("rust")) {
            disease = "Rouille du Maïs";
          } else if (textLower.contains("flétrissement") || textLower.contains("blight")) {
            disease = "Flétrissement Bactérien";
          } else if (textLower.contains("strie") || textLower.contains("streak")) {
            disease = "Strie Brune";
          } else {
            disease = "Symptôme à Surveiller";
          }
        }
      }

      // 4. Extract Confidence Score
      final confidenceMatch = RegExp(r'(?:confiance|Niveau)\s*:\s*(\d{1,3})\s*%', caseSensitive: false).firstMatch(cleanDiagnostic);
      if (confidenceMatch != null && confidenceMatch.group(1) != null) {
        final parsed = double.tryParse(confidenceMatch.group(1)!);
        if (parsed != null && parsed > 0 && parsed <= 100) {
          confidence = parsed / 100.0;
        }
      }

      dev.log("Saving successful diagnostic to SQLite: $cropName - $disease ($confidence)", name: 'SCAN_CUBIT');
      // Persist to local SQLite DB ONLY on verified success
      await SQLiteHelper.instance.insertDiagnostic({
        'crop_name': cropName,
        'disease': disease,
        'confidence': confidence,
        'remedy': remedy,
        'image_path': image.path,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'new',
      });

      emit(ScanSuccess(cleanDiagnostic, image));
    } catch (e, stack) {
      dev.log("Error analyzing crop image (No DB insert made)", name: 'SCAN_CUBIT', error: e, stackTrace: stack);
      final cleanMsg = e.toString().replaceAll("Exception: ", "");
      emit(ScanFailure(cleanMsg));
    }
  }
}
