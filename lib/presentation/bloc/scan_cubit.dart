import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gemmea/data/datasources/sqlite_helper.dart';
import '../../data/datasources/gemma_local_source.dart';

abstract class ScanState {}
class ScanInitial extends ScanState {}
class ScanProcessing extends ScanState {}
class ScanSuccess extends ScanState {
  final String diagnosis;
  ScanSuccess(this.diagnosis);
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

  Future<void> analyzeCrop(File image) async {
    emit(ScanProcessing());
    try {
      dev.log("Analyzing crop image with local Gemma VLM...", name: 'SCAN_CUBIT');
      final diagnosticResult = await localSource.evaluateCropImage(
        image, 
        "Analysez attentivement cette image de feuille de culture. Identifiez toute maladie potentielle de la plante (par ex. Mosaïque du manioc, Rouille du maïs, Flétrissement du bananier, etc.) visible sur l'image. Fournissez un Diagnostic Possible et un Remède Bio/Biologique Localisé très concis et adapté aux petits exploitants agricoles."
      );

      final textLower = diagnosticResult.toLowerCase();

      // Ensure that if the model returns an error string, we treat it as failure and do NOT save to DB
      if (textLower.contains("processing error") ||
          textLower.contains("veuillez fournir une image") ||
          textLower.contains("please provide an image") ||
          textLower.contains("error")) {
        throw Exception("Veuillez fournir une image claire d'une feuille de culture.");
      }

      // Extract details dynamically from local Gemma response
      String cropName = "Culture Inconnue";
      String disease = "Diagnostics Spécifique";
      String remedy = diagnosticResult;

      if (textLower.contains("manioc") || textLower.contains("cassava")) {
        cropName = "Manioc";
      } else if (textLower.contains("maïs") || textLower.contains("maize") || textLower.contains("corn")) {
        cropName = "Maïs";
      } else if (textLower.contains("haricot") || textLower.contains("bean") || textLower.contains("cowpea")) {
        cropName = "Haricot";
      } else if (textLower.contains("bananier") || textLower.contains("banane") || textLower.contains("banana")) {
        cropName = "Banane";
      } else if (textLower.contains("café") || textLower.contains("coffee")) {
        cropName = "Café";
      } else if (textLower.contains("patate douce") || textLower.contains("sweet potato")) {
        cropName = "Patate Douce";
      }

      if (textLower.contains("mosaïque") || textLower.contains("mosaic")) {
        disease = "Mosaïque du Manioc";
      } else if (textLower.contains("rouille") || textLower.contains("rust")) {
        disease = "Rouille du Maïs";
      } else if (textLower.contains("flétrissement") || textLower.contains("blight")) {
        disease = "Flétrissement Bactérien";
      } else if (textLower.contains("sain") || textLower.contains("healthy") || textLower.contains("no disease")) {
        disease = "Feuille Saine";
      }

      dev.log("Saving successful diagnostic to SQLite: $cropName - $disease", name: 'SCAN_CUBIT');
      // Persist to local SQLite DB ONLY on verified success
      await SQLiteHelper.instance.insertDiagnostic({
        'crop_name': cropName,
        'disease': disease,
        'confidence': 0.88,
        'remedy': remedy,
        'image_path': image.path,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'new',
      });

      emit(ScanSuccess(diagnosticResult));
    } catch (e, stack) {
      dev.log("Error analyzing crop image (No DB insert made)", name: 'SCAN_CUBIT', error: e, stackTrace: stack);
      final cleanMsg = e.toString().replaceAll("Exception: ", "");
      emit(ScanFailure(cleanMsg));
    }
  }
}
