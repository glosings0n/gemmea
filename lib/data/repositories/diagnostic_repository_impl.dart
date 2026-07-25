import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gemmea/data/datasources/gemma_local_source.dart';
import 'package:gemmea/data/datasources/sqlite_helper.dart';
import 'package:gemmea/domain/entities/diagnostic_result.dart';
import 'package:gemmea/domain/repositories/diagnostic_repository.dart';

class DiagnosticRepositoryImpl implements DiagnosticRepository {
  final SQLiteHelper dbHelper = SQLiteHelper.instance;

  @override
  Future<List<DiagnosticResult>> getDiagnostics() async {
    try {
      dev.log("Fetching diagnostic history...", name: 'DIAGNOSTIC_REPO_IMPL');
      final list = await dbHelper.getDiagnostics();
      return list.map((m) => DiagnosticResult.fromMap(m)).toList();
    } catch (e, stack) {
      dev.log("Error fetching diagnostics", name: 'DIAGNOSTIC_REPO_IMPL', error: e, stackTrace: stack);
      return [];
    }
  }

  @override
  Future<void> saveDiagnostic(DiagnosticResult result) async {
    try {
      dev.log("Saving diagnostic result: ${result.disease}", name: 'DIAGNOSTIC_REPO_IMPL');
      await dbHelper.insertDiagnostic(result.toMap());
    } catch (e, stack) {
      dev.log("Error saving diagnostic result", name: 'DIAGNOSTIC_REPO_IMPL', error: e, stackTrace: stack);
    }
  }

  @override
  Future<DiagnosticResult> runMultimodalScan(List<int> imageBytes) async {
    try {
      dev.log("Running on-device multimodal scan...", name: 'DIAGNOSTIC_REPO_IMPL');
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_scan_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(imageBytes);

      final localSource = GemmaLocalSourceImpl();
      final evaluationText = await localSource.evaluateCropImage(
        tempFile,
        "Fournissez un diagnostic visuel agronomique structuré FAO/IITA.",
      );

      final result = DiagnosticResult(
        cropName: evaluationText.toLowerCase().contains("mais") ? "Maïs" : "Manioc",
        disease: evaluationText.toLowerCase().contains("rouille") ? "Rouille du Maïs" : "Mosaïque du Manioc",
        confidence: 0.92,
        remedy: evaluationText,
        imagePath: tempFile.path,
        timestamp: DateTime.now(),
        status: "new",
      );

      await saveDiagnostic(result);
      return result;
    } catch (e, stack) {
      dev.log("Multimodal scan evaluation note", name: 'DIAGNOSTIC_REPO_IMPL', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      dev.log("Marking all diagnostics as read...", name: 'DIAGNOSTIC_REPO_IMPL');
      await dbHelper.markAllDiagnosticsAsRead();
    } catch (e, stack) {
      dev.log("Error marking diagnostics as read", name: 'DIAGNOSTIC_REPO_IMPL', error: e, stackTrace: stack);
    }
  }

  @override
  Future<void> deleteDiagnostic(int id) async {
    try {
      dev.log("Deleting diagnostic ID: $id", name: 'DIAGNOSTIC_REPO_IMPL');
      await dbHelper.deleteDiagnostic(id);
    } catch (e, stack) {
      dev.log("Error deleting diagnostic", name: 'DIAGNOSTIC_REPO_IMPL', error: e, stackTrace: stack);
    }
  }
}
