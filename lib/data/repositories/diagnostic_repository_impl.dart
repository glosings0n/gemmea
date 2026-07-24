import 'dart:async';
import 'package:gemmea/data/datasources/sqlite_helper.dart';
import 'package:gemmea/domain/entities/diagnostic_result.dart';
import 'package:gemmea/domain/repositories/diagnostic_repository.dart';

class DiagnosticRepositoryImpl implements DiagnosticRepository {
  final SQLiteHelper dbHelper = SQLiteHelper.instance;

  @override
  Future<List<DiagnosticResult>> getDiagnostics() async {
    final list = await dbHelper.getDiagnostics();
    return list.map((m) => DiagnosticResult.fromMap(m)).toList();
  }

  @override
  Future<void> saveDiagnostic(DiagnosticResult result) async {
    await dbHelper.insertDiagnostic(result.toMap());
  }

  @override
  Future<DiagnosticResult> runMultimodalScan(List<int> imageBytes) async {
    // Simulate local processing latency of on-device model for realistic UI feedback
    await Future.delayed(const Duration(seconds: 2));

    // Real-time on-device scanning requires an offline multimodal model (PaliGemma or similar).
    // The installed local model (gemma.litertlm) is a text-only LLM.
    // Rather than returning fake/mock diagnostic results, we cleanly throw a professional error.
    throw Exception(
      "Visual Diagnostic Engine Offline:\n\n"
      "The active local model (gemma.litertlm) is optimized exclusively for offline text chat. "
      "Real-time visual diagnostic capabilities are currently unavailable because the on-device engine lacks "
      "an offline multimodal vision model.\n\n"
      "To obtain a high-fidelity agronomy diagnosis without fake data, please write a text description "
      "of your crop leaf symptoms directly in the AI Chat tab instead!"
    );
  }

  @override
  Future<void> markAllAsRead() async {
    await dbHelper.markAllDiagnosticsAsRead();
  }

  @override
  Future<void> deleteDiagnostic(int id) async {
    await dbHelper.deleteDiagnostic(id);
  }
}
