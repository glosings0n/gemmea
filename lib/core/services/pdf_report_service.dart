import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PDFReportService {
  static String _formatFrenchDate(String dateStr, {bool includeTime = false}) {
    try {
      final dt = DateTime.parse(dateStr);
      final months = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
      final monthName = months[dt.month - 1];
      final dateFormatted = "${dt.day} $monthName ${dt.year}";
      if (includeTime) {
        final hour = dt.hour.toString().padLeft(2, '0');
        final minute = dt.minute.toString().padLeft(2, '0');
        return "le $dateFormatted à $hour:$minute";
      }
      return dateFormatted;
    } catch (_) {
      return dateStr;
    }
  }

  static String _formatSlashDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return "$day/$month/${dt.year}";
    } catch (_) {
      return dateStr;
    }
  }

  static String _cleanMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*|\*|__|#|`'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static String _extractCropName(Map<String, dynamic> d) {
    final rawCrop = d['crop_name']?.toString() ?? '';
    if (rawCrop.isNotEmpty && !rawCrop.toLowerCase().contains('inconnu')) {
      return rawCrop;
    }

    final disease = (d['disease']?.toString() ?? '').toLowerCase();
    final remedy = (d['remedy']?.toString() ?? '').toLowerCase();
    final combined = "$disease $remedy";

    if (combined.contains('manioc') || combined.contains('cassava')) return 'Manioc';
    if (combined.contains('maïs') || combined.contains('mais') || combined.contains('maize') || combined.contains('corn')) return 'Maïs';
    if (combined.contains('haricot') || combined.contains('bean')) return 'Haricot';
    if (combined.contains('banan') || combined.contains('banana')) return 'Banane';
    if (combined.contains('tomate') || combined.contains('tomato')) return 'Tomate';
    if (combined.contains('café') || combined.contains('coffee')) return 'Café';
    if (combined.contains('patate')) return 'Patate Douce';
    if (combined.contains('riz') || combined.contains('rice')) return 'Riz';
    if (combined.contains('piment') || combined.contains('poivron')) return 'Piment';
    if (combined.contains('soja')) return 'Soja';
    if (combined.contains('arachide')) return 'Arachide';
    if (combined.contains('cacao')) return 'Cacao';

    return 'Plante / Feuille';
  }

  static pw.Widget _parseMarkdownToPdfWidget(
    String text, {
    double fontSize = 7.5,
    PdfColor color = PdfColors.black,
  }) {
    final lines = text.trim().split('\n');
    final List<pw.Widget> widgets = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('#')) {
        final headerText = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2, bottom: 2),
            child: pw.Text(
              headerText,
              style: pw.TextStyle(
                fontSize: fontSize + 1.0,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1B4324'),
              ),
            ),
          ),
        );
        continue;
      }

      bool isBullet = false;
      String contentLine = trimmed;
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        isBullet = true;
        contentLine = trimmed.substring(2).trim();
      }

      final List<pw.InlineSpan> spans = [];
      if (isBullet) {
        spans.add(pw.TextSpan(
          text: '• ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize, color: color),
        ));
      }

      final RegExp regex = RegExp(r'(\*\*.*?\*\*|__.*?__|[^*_]+)');
      final matches = regex.allMatches(contentLine);

      for (final match in matches) {
        final matchText = match.group(0) ?? '';
        if ((matchText.startsWith('**') && matchText.endsWith('**')) ||
            (matchText.startsWith('__') && matchText.endsWith('__'))) {
          final clean = matchText.substring(2, matchText.length - 2);
          spans.add(pw.TextSpan(
            text: clean,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: fontSize,
              color: color,
            ),
          ));
        } else {
          spans.add(pw.TextSpan(
            text: matchText,
            style: pw.TextStyle(
              fontSize: fontSize,
              color: color,
            ),
          ));
        }
      }

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.RichText(
            text: pw.TextSpan(children: spans),
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      return pw.Text(text, style: pw.TextStyle(fontSize: fontSize, color: color));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: widgets,
    );
  }

  static Future<Uint8List> generateFarmDiagnosticReport({
    required List<Map<String, dynamic>> diagnostics,
    required List<Map<String, dynamic>> calendarEvents,
    String farmerLocation = 'Bukavu, Sud-Kivu, RDC',
  }) async {
    try {
      dev.log("Generating PDF farm diagnostic report...", name: 'PDF_REPORT_SERVICE');
      final pdf = pw.Document();

      pw.Font? fontRegular;
      pw.Font? fontBold;

      try {
        final fontDataRegular = await rootBundle.load('assets/fonts/Fredoka-Regular.ttf');
        final fontDataBold = await rootBundle.load('assets/fonts/Fredoka-Bold.ttf');
        fontRegular = pw.Font.ttf(fontDataRegular);
        fontBold = pw.Font.ttf(fontDataBold);
      } catch (e) {
        dev.log("Fredoka font load note, falling back to Georgia: $e", name: 'PDF_REPORT_SERVICE');
        fontRegular = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }

      final primaryColor = PdfColor.fromHex('#1B4324');
      final accentColor = PdfColor.fromHex('#FBC02D');
      final grayColor = PdfColor.fromHex('#666666');

      final nowFormatted = _formatFrenchDate(DateTime.now().toIso8601String(), includeTime: true);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
          ),
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
                          'Gemmea - Rapport de Productivité Agricole',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 15,
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
              pw.SizedBox(height: 12),

              // Metadata Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Localisation: $farmerLocation', style: pw.TextStyle(color: grayColor, fontSize: 8)),
                  pw.Text('Généré $nowFormatted', style: pw.TextStyle(color: grayColor, fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Section 1: Executive Summary
              pw.Text(
                '1. Synthèse de Productivité & Triage Sanitaire',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F4F6F4'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Diagnostics Effectués', '${diagnostics.length}', primaryColor),
                    _buildStatItem('Alertes Actives', '${diagnostics.where((d) => d['status'] == 'new').length}', primaryColor),
                    _buildStatItem('Cycles d\'Irrigation', '${calendarEvents.length}', primaryColor),
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
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.2),
                    1: const pw.FlexColumnWidth(1.8),
                    2: const pw.FlexColumnWidth(1.0),
                    3: const pw.FlexColumnWidth(0.9),
                    4: const pw.FlexColumnWidth(5.0),
                  },
                  data: diagnostics.map((d) {
                    final confidence = (d['confidence'] as double? ?? 0.0) * 100;
                    return [
                      _extractCropName(d),
                      d['disease'] ?? 'Sain',
                      '${confidence.toStringAsFixed(0)}%',
                      d['status'] == 'new' ? 'Alerte' : 'Traité',
                      _parseMarkdownToPdfWidget(d['remedy'] ?? 'Aucun'),
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
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.3),
                    1: const pw.FlexColumnWidth(2.0),
                    2: const pw.FlexColumnWidth(1.3),
                    3: const pw.FlexColumnWidth(4.5),
                  },
                  data: calendarEvents.map((c) {
                    final rawDate = c['event_date'] ?? '';
                    final tableDate = _formatSlashDate(rawDate);
                    return [
                      tableDate,
                      c['title'] ?? '',
                      c['is_rainy'] == 1 ? 'Oui (Pause)' : 'Non (Actif)',
                      _cleanMarkdown(c['description'] ?? ''),
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                  headerDecoration: pw.BoxDecoration(color: primaryColor),
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
                  pw.Text('Propulsé par Gemmea', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                ],
              ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      dev.log("PDF generation completed (${pdfBytes.length} bytes)", name: 'PDF_REPORT_SERVICE');
      return pdfBytes;
    } catch (e, stack) {
      dev.log("Error generating PDF report", name: 'PDF_REPORT_SERVICE', error: e, stackTrace: stack);
      rethrow;
    }
  }

  static pw.Widget _buildStatItem(String label, String value, PdfColor primaryColor) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: primaryColor),
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
    String farmerLocation = 'Bukavu, Sud-Kivu, RDC',
  }) async {
    try {
      dev.log("Printing/sharing PDF report...", name: 'PDF_REPORT_SERVICE');
      final pdfBytes = await generateFarmDiagnosticReport(
        diagnostics: diagnostics,
        calendarEvents: calendarEvents,
        farmerLocation: farmerLocation,
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Rapport_Agronomique_Gemmea_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e, stack) {
      dev.log("Error sharing PDF report", name: 'PDF_REPORT_SERVICE', error: e, stackTrace: stack);
    }
  }
}
