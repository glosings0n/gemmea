import 'package:gemmea/domain/entities/diagnostic_result.dart';
import 'package:gemmea/domain/repositories/diagnostic_repository.dart';

class GetDiagnostics {
  final DiagnosticRepository repository;
  GetDiagnostics(this.repository);

  Future<List<DiagnosticResult>> call() async {
    return await repository.getDiagnostics();
  }
}

class SaveDiagnostic {
  final DiagnosticRepository repository;
  SaveDiagnostic(this.repository);

  Future<void> call(DiagnosticResult result) async {
    await repository.saveDiagnostic(result);
  }
}

class RunCropScan {
  final DiagnosticRepository repository;
  RunCropScan(this.repository);

  Future<DiagnosticResult> call(List<int> imageBytes) async {
    return await repository.runMultimodalScan(imageBytes);
  }
}

class MarkDiagnosticsAsRead {
  final DiagnosticRepository repository;
  MarkDiagnosticsAsRead(this.repository);

  Future<void> call() async {
    await repository.markAllAsRead();
  }
}

class DeleteDiagnostic {
  final DiagnosticRepository repository;
  DeleteDiagnostic(this.repository);

  Future<void> call(int id) async {
    await repository.deleteDiagnostic(id);
  }
}
