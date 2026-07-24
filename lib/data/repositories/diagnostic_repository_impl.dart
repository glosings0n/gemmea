import 'dart:async';
import 'dart:developer' as dev;
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
      await Future.delayed(const Duration(seconds: 2));

      throw Exception(
        "Visual Diagnostic Engine Offline:\n\n"
        "The active local model (gemma.litertlm) is optimized exclusively for offline text chat. "
        "Real-time visual diagnostic capabilities are currently unavailable because the on-device engine lacks "
        "an offline multimodal vision model.\n\n"
        "To obtain a high-fidelity agronomy diagnosis without fake data, please write a text description "
        "of your crop leaf symptoms directly in the AI Chat tab instead!"
      );
    } catch (e, stack) {
      dev.log("Multimodal scan thrown as expected", name: 'DIAGNOSTIC_REPO_IMPL', error: e, stackTrace: stack);
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
