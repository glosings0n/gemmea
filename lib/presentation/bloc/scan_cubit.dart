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
  ScanFailure(this.error);
}

class ScanCubit extends Cubit<ScanState> {
  final GemmaLocalSource localSource;

  ScanCubit(this.localSource) : super(ScanInitial());

  Future<void> analyzeCrop(File image) async {
    emit(ScanProcessing());
    try {
      final diagnosticResult = await localSource.evaluateCropImage(
        image, 
        "Analysez attentivement cette image de feuille de culture. Identifiez toute maladie potentielle de la plante (par ex. Mosaïque du manioc, Rouille du maïs, Flétrissement du bananier, etc.) visible sur l'image. Fournissez un Diagnostic Possible et un Remède Bio/Biologique Localisé très concis et adapté aux petits exploitants agricoles."
      );

      // Extract details dynamically from local Gemma response
      String cropName = "Inconnu";
      String disease = "Symptômes Analysés";
      String remedy = diagnosticResult;

      final textLower = diagnosticResult.toLowerCase();
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

      // Persist to local SQLite DB immediately upon offline inference success
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
    } catch (e) {
      emit(ScanFailure("Échec de l'exécution du modèle de vision local : $e"));
    }
  }
}
