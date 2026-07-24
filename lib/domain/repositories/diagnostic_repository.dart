import 'package:gemmea/domain/entities/diagnostic_result.dart';

abstract class DiagnosticRepository {
  Future<List<DiagnosticResult>> getDiagnostics();
  Future<void> saveDiagnostic(DiagnosticResult result);
  Future<DiagnosticResult> runMultimodalScan(List<int> imageBytes);
  Future<void> markAllAsRead();
  Future<void> deleteDiagnostic(int id);
}
