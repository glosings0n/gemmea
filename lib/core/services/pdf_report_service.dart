import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:gemmea/core/utils/text_sanitizer.dart';
import 'package:path_provider/path_provider.dart';
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
    final sanitized = TextSanitizer.cleanLatexAndFormatting(text);
    return sanitized
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

  static List<pw.Widget> _parseMarkdownToPdfWidgets(
    String text, {
    double fontSize = 7.5,
    PdfColor color = PdfColors.black,
  }) {
    final sanitized = TextSanitizer.cleanLatexAndFormatting(text);
    final lines = sanitized.trim().split('\n');
    final List<pw.Widget> widgets = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 2));
        continue;
      }

      if (trimmed.startsWith('#')) {
        final headerText = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
            child: pw.Text(
              headerText,
              style: pw.TextStyle(
                fontSize: fontSize + 1.5,
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
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: fontSize,
            color: PdfColor.fromHex('#1B4324'),
          ),
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
          padding: const pw.EdgeInsets.only(bottom: 2.5),
          child: pw.RichText(
            text: pw.TextSpan(children: spans),
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      return [pw.Text(text, style: pw.TextStyle(fontSize: fontSize, color: color))];
    }

    return widgets;
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

              // Section 2: Diagnostics Table (Synthèse)
              pw.Text(
                '2. Historique des Diagnostics de Pathologies (Gemma Vision & FAO RAG)',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor),
              ),
              pw.SizedBox(height: 8),
              if (diagnostics.isEmpty)
                pw.Text('Aucun diagnostic enregistré à ce jour.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
              else ...[
                pw.TableHelper.fromTextArray(
                  headers: ['Culture', 'Diagnostic / Pathologie', 'Confiance', 'Statut', 'Synthèse du Traitement'],
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.2),
                    1: const pw.FlexColumnWidth(1.8),
                    2: const pw.FlexColumnWidth(1.0),
                    3: const pw.FlexColumnWidth(0.9),
                    4: const pw.FlexColumnWidth(3.5),
                  },
                  data: diagnostics.map((d) {
                    final confidence = (d['confidence'] as double? ?? 0.0) * 100;
                    final rawRemedy = _cleanMarkdown(d['remedy'] ?? '');
                    final shortRemedy = rawRemedy.length > 110
                        ? '${rawRemedy.substring(0, 110)}...'
                        : (rawRemedy.isEmpty ? 'Aucun' : rawRemedy);
                    return [
                      _extractCropName(d),
                      d['disease'] ?? 'Sain',
                      '${confidence.toStringAsFixed(0)}%',
                      d['status'] == 'new' ? 'Alerte' : 'Traité',
                      shortRemedy,
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                  headerDecoration: pw.BoxDecoration(color: primaryColor),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  cellPadding: const pw.EdgeInsets.all(6),
                ),
                pw.SizedBox(height: 12),

                // Detailed Protocol Cards (Flowing line-by-line across pages)
                ...diagnostics.expand((d) {
                  final cropName = _extractCropName(d);
                  final disease = d['disease'] ?? 'Sain';
                  final remedy = d['remedy'] ?? '';

                  return [
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#E8F5E9'),
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColor.fromHex('#A5D6A7')),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Fiche Médicale Détaillée : $cropName - $disease',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                          ),
                          pw.Text(
                            d['status'] == 'new' ? 'Alerte Active' : 'Traité',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    ..._parseMarkdownToPdfWidgets(remedy, fontSize: 8),
                    pw.SizedBox(height: 6),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                  ];
                }),
              ],

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

  static Future<String> downloadReportToDocuments({
    required List<Map<String, dynamic>> diagnostics,
    required List<Map<String, dynamic>> calendarEvents,
    String farmerLocation = 'Bukavu, Sud-Kivu, RDC',
  }) async {
    try {
      dev.log("Generating PDF for download...", name: 'PDF_REPORT_SERVICE');
      final pdfBytes = await generateFarmDiagnosticReport(
        diagnostics: diagnostics,
        calendarEvents: calendarEvents,
        farmerLocation: farmerLocation,
      );

      final filename = 'Rapport_Agronomique_Gemmea_${DateTime.now().millisecondsSinceEpoch}.pdf';
      List<String> savedPaths = [];

      if (Platform.isAndroid) {
        final publicDirs = [
          Directory('/storage/emulated/0/Documents/Gemmea'),
          Directory('/storage/emulated/0/Documents'),
          Directory('/storage/emulated/0/Download'),
        ];

        for (final dir in publicDirs) {
          try {
            if (!await dir.exists()) {
              await dir.create(recursive: true);
            }
            final file = File('${dir.path}/$filename');
            await file.writeAsBytes(pdfBytes);
            savedPaths.add(file.path);
            dev.log("PDF saved to public directory: ${file.path}", name: 'PDF_REPORT_SERVICE');

            // Notify Android MediaScanner & MediaStore indexing immediately
            try {
              const channel = MethodChannel('com.gemmea.app/media_scanner');
              await channel.invokeMethod('scanFile', {'path': file.path});
              dev.log("Notified Android MediaScanner for ${file.path}", name: 'PDF_REPORT_SERVICE');
            } catch (scanErr) {
              dev.log("MediaScanner notification note: $scanErr", name: 'PDF_REPORT_SERVICE');
            }
          } catch (e) {
            dev.log("Could not write to ${dir.path}: $e", name: 'PDF_REPORT_SERVICE');
          }
        }
      }

      if (savedPaths.isEmpty) {
        Directory? targetDir;
        try {
          targetDir = await getDownloadsDirectory();
        } catch (_) {}
        targetDir ??= await getApplicationDocumentsDirectory();

        final file = File('${targetDir.path}/$filename');
        await file.writeAsBytes(pdfBytes);
        savedPaths.add(file.path);

        try {
          if (Platform.isAndroid) {
            const channel = MethodChannel('com.gemmea.app/media_scanner');
            await channel.invokeMethod('scanFile', {'path': file.path});
          }
        } catch (_) {}
      }

      dev.log("PDF downloaded successfully to ${savedPaths.first}", name: 'PDF_REPORT_SERVICE');
      return savedPaths.first;
    } catch (e, stack) {
      dev.log("Error downloading PDF report", name: 'PDF_REPORT_SERVICE', error: e, stackTrace: stack);
      rethrow;
    }
  }

  static Future<void> shareReport({
    required List<Map<String, dynamic>> diagnostics,
    required List<Map<String, dynamic>> calendarEvents,
    String farmerLocation = 'Bukavu, Sud-Kivu, RDC',
  }) async {
    try {
      dev.log("Sharing PDF report...", name: 'PDF_REPORT_SERVICE');
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
      rethrow;
    }
  }

  static Future<void> printOrShareReport({
    required List<Map<String, dynamic>> diagnostics,
    required List<Map<String, dynamic>> calendarEvents,
    String farmerLocation = 'Bukavu, Sud-Kivu, RDC',
  }) async {
    await shareReport(
      diagnostics: diagnostics,
      calendarEvents: calendarEvents,
      farmerLocation: farmerLocation,
    );
  }

  static Future<Uint8List> generateSingleDiagnosticReport({
    required Map<String, dynamic> diagnostic,
    String farmerLocation = 'Bukavu, Sud-Kivu, RDC',
  }) async {
    try {
      dev.log("Generating single diagnostic PDF report...", name: 'PDF_REPORT_SERVICE');
      final pdf = pw.Document();

      pw.Font? fontRegular;
      pw.Font? fontBold;

      try {
        final fontDataRegular = await rootBundle.load('assets/fonts/Fredoka-Regular.ttf');
        final fontDataBold = await rootBundle.load('assets/fonts/Fredoka-Bold.ttf');
        fontRegular = pw.Font.ttf(fontDataRegular);
        fontBold = pw.Font.ttf(fontDataBold);
      } catch (e) {
        fontRegular = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }

      final primaryColor = PdfColor.fromHex('#1B4324');
      final accentColor = PdfColor.fromHex('#FBC02D');
      final grayColor = PdfColor.fromHex('#666666');

      final crop = _extractCropName(diagnostic);
      final disease = diagnostic['disease']?.toString() ?? 'Pathologie Inconnue';
      final confidenceVal = (diagnostic['confidence'] as num?)?.toDouble() ?? 0.0;
      final confidence = (confidenceVal * 100).toInt();
      final status = diagnostic['status'] == 'new' ? 'Alerte Active' : 'Traité';
      final rawDate = diagnostic['timestamp']?.toString() ?? DateTime.now().toIso8601String();
      final formattedDate = _formatFrenchDate(rawDate, includeTime: true);
      final remedy = diagnostic['remedy']?.toString() ?? '';

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
              // Header Banner
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
                          'Gemmea - Diagnostic Agronomique Individuel',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Fiche Pathologique & Traitement FAO / IITA',
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
                  pw.Text('Diagnostic du $formattedDate', style: pw.TextStyle(color: grayColor, fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Summary Stats
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
                    _buildStatItem('Culture', crop, primaryColor),
                    _buildStatItem('Pathologie', disease, primaryColor),
                    _buildStatItem('Confiance IA', '$confidence%', primaryColor),
                    _buildStatItem('Statut', status, primaryColor),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Economic Impact Card
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFF8E1'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#FFE082')),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Estimation d\'Impact Économique & Pertes Évitées (FAO)',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '• Perte potentielle sans intervention : 40% à 70% du rendement parcellaire.\n'
                      '• Gain estimé après traitement FAO / IITA : +120\$ à +350\$/hectare.',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.brown800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Detailed Protocol Section
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#E8F5E9'),
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColor.fromHex('#A5D6A7')),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Actions Correctives & Traitement Recommandé (FAO / IITA)',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor),
                    ),
                    pw.Text(
                      '100% Hors-Ligne',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              ..._parseMarkdownToPdfWidgets(remedy, fontSize: 8.5),

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
      dev.log("Single PDF report generated (${pdfBytes.length} bytes)", name: 'PDF_REPORT_SERVICE');
      return pdfBytes;
    } catch (e, stack) {
      dev.log("Error generating single PDF report", name: 'PDF_REPORT_SERVICE', error: e, stackTrace: stack);
      rethrow;
    }
  }

  static Future<String> downloadSingleReportToDocuments({
    required Map<String, dynamic> diagnostic,
    String farmerLocation = 'Bukavu, Sud-Kivu, RDC',
  }) async {
    try {
      final pdfBytes = await generateSingleDiagnosticReport(
        diagnostic: diagnostic,
        farmerLocation: farmerLocation,
      );

      final crop = _extractCropName(diagnostic);
      final filename = 'Diagnostic_${crop}_Gemmea_${DateTime.now().millisecondsSinceEpoch}.pdf';
      List<String> savedPaths = [];

      if (Platform.isAndroid) {
        final publicDirs = [
          Directory('/storage/emulated/0/Documents/Gemmea'),
          Directory('/storage/emulated/0/Documents'),
          Directory('/storage/emulated/0/Download'),
        ];

        for (final dir in publicDirs) {
          try {
            if (!await dir.exists()) {
              await dir.create(recursive: true);
            }
            final file = File('${dir.path}/$filename');
            await file.writeAsBytes(pdfBytes);
            savedPaths.add(file.path);

            try {
              const channel = MethodChannel('com.gemmea.app/media_scanner');
              await channel.invokeMethod('scanFile', {'path': file.path});
            } catch (_) {}
          } catch (_) {}
        }
      }

      if (savedPaths.isEmpty) {
        Directory? targetDir;
        try {
          targetDir = await getDownloadsDirectory();
        } catch (_) {}
        targetDir ??= await getApplicationDocumentsDirectory();

        final file = File('${targetDir.path}/$filename');
        await file.writeAsBytes(pdfBytes);
        savedPaths.add(file.path);

        try {
          if (Platform.isAndroid) {
            const channel = MethodChannel('com.gemmea.app/media_scanner');
            await channel.invokeMethod('scanFile', {'path': file.path});
          }
        } catch (_) {}
      }

      return savedPaths.first;
    } catch (e, stack) {
      dev.log("Error downloading single PDF report", name: 'PDF_REPORT_SERVICE', error: e, stackTrace: stack);
      rethrow;
    }
  }

  static Future<void> shareSingleReport({
    required Map<String, dynamic> diagnostic,
    String farmerLocation = 'Bukavu, Sud-Kivu, RDC',
  }) async {
    try {
      final pdfBytes = await generateSingleDiagnosticReport(
        diagnostic: diagnostic,
        farmerLocation: farmerLocation,
      );

      final crop = _extractCropName(diagnostic);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Diagnostic_${crop}_Gemmea_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e, stack) {
      dev.log("Error sharing single PDF report", name: 'PDF_REPORT_SERVICE', error: e, stackTrace: stack);
      rethrow;
    }
  }

  static Future<void> openPdfFile(String filePath) async {
    try {
      dev.log("Opening PDF file directly: $filePath", name: 'PDF_REPORT_SERVICE');
      if (Platform.isAndroid) {
        const channel = MethodChannel('com.gemmea.app/media_scanner');
        await channel.invokeMethod('openFile', {'path': filePath});
      } else {
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          await Printing.layoutPdf(onLayout: (_) async => bytes);
        }
      }
    } catch (e, stack) {
      dev.log("Error opening PDF file", name: 'PDF_REPORT_SERVICE', error: e, stackTrace: stack);
    }
  }
}
