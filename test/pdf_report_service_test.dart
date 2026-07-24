import 'package:flutter_test/flutter_test.dart';
import 'package:gemmea/core/services/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDFReportService Tests', () {
    test('generateFarmDiagnosticReport produces non-empty PDF byte array', () async {
      final diagnostics = [
        {
          'crop_name': 'Manioc',
          'disease': 'Mosaïque du Manioc (CMD)',
          'confidence': 0.95,
          'status': 'new',
          'remedy': 'Boutures TME 419 + Eau de Neem',
        }
      ];

      final calendarEvents = [
        {
          'event_date': '2026-07-25',
          'title': 'Irrigation du Manioc',
          'is_rainy': 0,
          'description': 'Irrigation régulière (3L / plant)',
        }
      ];

      final pdfBytes = await PDFReportService.generateFarmDiagnosticReport(
        diagnostics: diagnostics,
        calendarEvents: calendarEvents,
        farmerLocation: 'Bukavu, Sud-Kivu (RDC)',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, true);
      // PDF document header bytes start with %PDF
      expect(pdfBytes.take(4), equals([0x25, 0x50, 0x44, 0x46]));
    });

    test('generateFarmDiagnosticReport handles empty lists gracefully', () async {
      final pdfBytes = await PDFReportService.generateFarmDiagnosticReport(
        diagnostics: [],
        calendarEvents: [],
        farmerLocation: 'Goma, Nord-Kivu',
      );

      expect(pdfBytes.isNotEmpty, true);
      expect(pdfBytes.take(4), equals([0x25, 0x50, 0x44, 0x46]));
    });
  });
}
