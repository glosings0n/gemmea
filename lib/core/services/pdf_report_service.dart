import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PDFReportService {
  static Future<Uint8List> generateFarmDiagnosticReport({
    required List<Map<String, dynamic>> diagnostics,
    required List<Map<String, dynamic>> calendarEvents,
    required String farmerLocation,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#1B4324');
    final secondaryColor = PdfColor.fromHex('#2E7D32');
    final accentColor = PdfColor.fromHex('#FBC02D');
    final grayColor = PdfColor.fromHex('#666666');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GEMMEA - RAPPORT DE PRODUCTIVITÉ AGRICOLE',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Rapport Agrométéorologique et Diagnostics de Santé des Cultures',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: accentColor,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      '100% HORS LIGNE',
                      style: pw.TextStyle(
                        color: primaryColor,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Metadata Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Localisation: $farmerLocation', style: pw.TextStyle(color: grayColor, fontSize: 10)),
                pw.Text('Généré le: ${DateTime.now().toString().split('.')[0]}', style: pw.TextStyle(color: grayColor, fontSize: 10)),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 12),

            // Section 1: Executive Summary
            pw.Text(
              '1. Synthèse de Productivité & Triage Sanitaire',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: secondaryColor),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F6F8F5'),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Diagnostics Effectués', '${diagnostics.length}'),
                  _buildStatItem('Alertes Actives', '${diagnostics.where((d) => d['status'] == 'new').length}'),
                  _buildStatItem('Cycles d\'Irrigation', '${calendarEvents.length}'),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Section 2: Diagnostics Table
            pw.Text(
              '2. Historique des Diagnostics de Pathologies (Gemma Vision & FAO RAG)',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor),
            ),
            pw.SizedBox(height: 8),
            if (diagnostics.isEmpty)
              pw.Text('Aucun diagnostic enregistré à ce jour.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Culture', 'Diagnostic / Pathologie', 'Confiance', 'Statut', 'Remède Recommandé (FAO)'],
                data: diagnostics.map((d) {
                  final confidence = (d['confidence'] as double? ?? 0.0) * 100;
                  return [
                    d['crop_name'] ?? 'Inconnu',
                    d['disease'] ?? 'Sain',
                    '${confidence.toStringAsFixed(0)}%',
                    d['status'] == 'new' ? 'Alerte' : 'Traité',
                    d['remedy'] ?? 'Aucun',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.all(6),
              ),

            pw.SizedBox(height: 16),

            // Section 3: Irrigation & Task Schedule
            pw.Text(
              '3. Calendrier d\'Irrigation & Tâches Agricoles',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor),
            ),
            pw.SizedBox(height: 8),
            if (calendarEvents.isEmpty)
              pw.Text('Aucun événement d\'irrigation planifié.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Tâche / Intervention', 'Pluie Détectée', 'Instructions'],
                data: calendarEvents.map((c) {
                  return [
                    c['event_date'] ?? '',
                    c['title'] ?? '',
                    c['is_rainy'] == 1 ? 'Oui (Pause)' : 'Non (Actif)',
                    c['description'] ?? '',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: secondaryColor),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.all(6),
              ),

            pw.SizedBox(height: 24),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 8),

            // Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Ancré dans les guides officiels FAO & IITA East Africa', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Propulsé par Google Gemma 2B IT & Gemma 4 E2B', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor)),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1B4324')),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static Future<void> printOrShareReport({
    required List<Map<String, dynamic>> diagnostics,
    required List<Map<String, dynamic>> calendarEvents,
    required String farmerLocation,
  }) async {
    final pdfBytes = await generateFarmDiagnosticReport(
      diagnostics: diagnostics,
      calendarEvents: calendarEvents,
      farmerLocation: farmerLocation,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Rapport_Agronomique_Gemmea_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
