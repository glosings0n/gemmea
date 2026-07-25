import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:gemmea/core/core.dart';
import 'package:gemmea/presentation/bloc/bloc.dart';

class DiagnosticsHistoryPage extends StatefulWidget {
  const DiagnosticsHistoryPage({super.key});

  @override
  State<DiagnosticsHistoryPage> createState() => _DiagnosticsHistoryPageState();
}

class _DiagnosticsHistoryPageState extends State<DiagnosticsHistoryPage> {
  int? _expandedIndex;
  final Map<int, ExpansibleController> _controllers = {};

  String _formatFrenchDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return "$day/$month/$year à ${hour}h$minute";
    } catch (_) {
      return dateStr;
    }
  }

  @override
  void initState() {
    super.initState();
    // Mark all diagnostics as read when entering the history page
    context.read<HomeCubit>().markAllAsRead();
  }

  Future<void> _confirmDelete(BuildContext context, dynamic log) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.r20),
          ),
          backgroundColor: AppColors.cardCleanWhite,
          title: const Row(
            children: [
              HugeIcon(
                icon: AppIcons.alert,
                color: Colors.redAccent,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                "Supprimer ?",
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.textCharcoal,
                ),
              ),
            ],
          ),
          content: Text(
            "Êtes-vous sûr de vouloir supprimer ce diagnostic du ${_formatFrenchDate(log.timestamp.toString())} ? Cette action est irréversible.",
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: AppSize.p16, vertical: AppSize.p12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                "Annuler",
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSize.r12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSize.p16, vertical: AppSize.p8),
              ),
              child: const Text(
                "Supprimer",
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      if (log.id != null) {
        await context.read<HomeCubit>().deleteDiagnostic(log.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Diagnostic supprimé avec succès.",
                style: TextStyle(fontFamily: 'Fredoka'),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: AppColors.primaryForestGreen,
            ),
          );
        }
      }
    }
  }

  void _showSinglePdfOptionsBottomSheet(BuildContext context, dynamic log) {
    final Map<String, dynamic> diagMap = log is Map<String, dynamic> ? log : log.toMap();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardCleanWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppSize.r24),
              topRight: Radius.circular(AppSize.r24),
            ),
          ),
          padding: const EdgeInsets.all(AppSize.p24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textGrey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Exporter Diagnostic PDF (${diagMap['crop_name'] ?? 'Plante'})",
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textCharcoal,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Choisissez une option pour sauvegarder ou partager ce diagnostic.",
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 13,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 20),
              
              // Option 1: Download
              InkWell(
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  try {
                    final path = await PDFReportService.downloadSingleReportToDocuments(
                      diagnostic: diagMap,
                      farmerLocation: 'Bukavu, Sud-Kivu, RDC',
                    );
                    if (context.mounted) {
                      final filename = path.split('/').last;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const HugeIcon(
                                icon: AppIcons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Diagnostic PDF enregistré dans vos Documents :\n$filename",
                                  style: const TextStyle(fontFamily: 'Fredoka', fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  PDFReportService.openPdfFile(path);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "Ouvrir",
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryForestGreen,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.primaryForestGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 6),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Erreur lors du téléchargement du PDF: $e"),
                          backgroundColor: AppColors.errorRed,
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(AppSize.r12),
                child: Container(
                  padding: const EdgeInsets.all(AppSize.p16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryForestGreen.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppSize.r12),
                    border: Border.all(
                      color: AppColors.primaryForestGreen.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryForestGreen,
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: AppIcons.download,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Télécharger le PDF",
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textCharcoal,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Enregistre le document dans le dossier Documents",
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 2: Share
              InkWell(
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  try {
                    await PDFReportService.shareSingleReport(
                      diagnostic: diagMap,
                      farmerLocation: 'Bukavu, Sud-Kivu, RDC',
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Erreur lors du partage du PDF: $e"),
                          backgroundColor: AppColors.errorRed,
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(AppSize.r12),
                child: Container(
                  padding: const EdgeInsets.all(AppSize.p16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryMint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSize.r12),
                    border: Border.all(
                      color: AppColors.primaryForestGreen.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryForestGreen,
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: AppIcons.share,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Partager ou Imprimer le PDF",
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textCharcoal,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Envoyer via WhatsApp, Email ou imprimer directement",
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const HugeIcon(icon: AppIcons.back, color: AppColors.primaryForestGreen, size: 22.0),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Historique des Diagnostics",
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
            color: AppColors.primaryForestGreen,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryForestGreen),
              ),
            );
          } else if (state is HomeError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSize.p24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HugeIcon(icon: AppIcons.alert, color: AppColors.errorRed, size: AppSize.iconXl),
                    const SizedBox(height: AppSize.p16),
                    Text(
                      "Error: ${state.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Fredoka', color: AppColors.textCharcoal),
                    ),
                    const SizedBox(height: AppSize.p16),
                    ElevatedButton(
                      onPressed: () => context.read<HomeCubit>().loadDashboard(),
                      child: const Text("Réessayer", style: TextStyle(fontFamily: 'Fredoka')),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is HomeLoaded) {
            if (state.diagnosticsHistory.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSize.p24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSize.p24),
                        decoration: BoxDecoration(
                          color: AppColors.primaryForestGreen.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Text("🍃", style: TextStyle(fontSize: 48)),
                      ),
                      const SizedBox(height: AppSize.p24),
                      const Text(
                        "Aucun diagnostic de plante",
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textCharcoal,
                        ),
                      ),
                      const SizedBox(height: AppSize.p8),
                      const Text(
                        "Utilisez l'icône appareil photo pour scanner les feuilles de maïs ou de manioc. Vos diagnostics apparaîtront ici.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primaryForestGreen,
              onRefresh: () => context.read<HomeCubit>().loadDashboard(),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSize.p16),
                itemCount: state.diagnosticsHistory.length,
                itemBuilder: (context, index) {
                  final log = state.diagnosticsHistory[index];
                  final isNew = log.status == 'new';

                  final isExpanded = _expandedIndex == index;

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: AppSize.p12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSize.r16),
                      side: BorderSide(
                        color: isNew 
                            ? AppColors.primaryForestGreen.withValues(alpha: 0.3) 
                            : AppColors.primaryForestGreen.withValues(alpha: 0.05),
                        width: isNew ? 1.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSize.r16),
                      child: ExpansionTile(
                        key: Key('diagnostic_${log.id}'),
                        controller: _controllers[index] ??= ExpansibleController(),
                        initiallyExpanded: isExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            if (expanded) {
                              if (_expandedIndex != null && _expandedIndex != index) {
                                _controllers[_expandedIndex]?.collapse();
                              }
                              _expandedIndex = index;
                            } else if (_expandedIndex == index) {
                              _expandedIndex = null;
                            }
                          });
                        },
                        backgroundColor: isNew 
                            ? AppColors.primaryForestGreen.withValues(alpha: 0.02) 
                            : Colors.transparent,
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isNew 
                                ? AppColors.primaryForestGreen.withValues(alpha: 0.1) 
                                : AppColors.primaryForestGreen.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text("🍃", style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                log.disease,
                                style: const TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textCharcoal,
                                ),
                              ),
                            ),
                            if (isNew)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "NOUVEAU",
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          "Culture : ${log.cropName} • ${(log.confidence * 100).toInt()}% de confiance",
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppSize.p16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (log.imagePath != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppSize.r12),
                                    child: log.imagePath!.startsWith('assets')
                                        ? Image.asset(
                                            log.imagePath!,
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(log.imagePath!),
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/images/logo.png',
                                                height: 200,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                  ),
                                  const SizedBox(height: AppSize.p12),
                                  Container(
                                    padding: const EdgeInsets.all(AppSize.p12),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppSize.r8),
                                      border: Border.all(color: Colors.amber.shade600.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text("💰 ", style: TextStyle(fontSize: 18)),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Estimation d'Impact Économique & Perte Evitée",
                                                style: TextStyle(
                                                  fontFamily: 'Fredoka',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textCharcoal,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "Risque de perte non traité : ~40% à 70% du rendement par hectare.\nGain estimé après application du traitement FAO : +120\$ à +350\$/ha.",
                                                style: TextStyle(
                                                  fontFamily: 'Fredoka',
                                                  fontSize: 11,
                                                  color: Colors.brown.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSize.p12),
                                ],
                                const Text(
                                  "Actions correctives recommandées (IITA) :",
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryForestGreen,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: AppSize.p8),
                                MarkdownBody(
                                  data: log.remedy,
                                  styleSheet: MarkdownStyleSheet(
                                    h1: const TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.primaryForestGreen,
                                    ),
                                    h2: const TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.primaryForestGreen,
                                    ),
                                    h3: const TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.primaryForestGreen,
                                    ),
                                    h4: const TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: AppColors.primaryForestGreen,
                                    ),
                                    p: const TextStyle(
                                      fontFamily: 'Fredoka',
                                      height: 1.45,
                                      color: AppColors.textCharcoal,
                                      fontSize: 13.5,
                                    ),
                                    strong: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Fredoka',
                                      color: AppColors.textCharcoal,
                                    ),
                                    em: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontFamily: 'Fredoka',
                                      color: AppColors.textCharcoal,
                                    ),
                                    listBullet: const TextStyle(
                                      fontFamily: 'Fredoka',
                                      color: AppColors.primaryForestGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSize.p12),
                                Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     TextButton.icon(
                                       onPressed: () => _showSinglePdfOptionsBottomSheet(context, log),
                                       icon: const HugeIcon(
                                         icon: AppIcons.pdf,
                                         color: AppColors.primaryForestGreen,
                                         size: 16,
                                       ),
                                       label: const Text(
                                         "Exporter PDF",
                                         style: TextStyle(
                                           fontFamily: 'Fredoka',
                                           fontSize: 12,
                                           color: AppColors.primaryForestGreen,
                                           fontWeight: FontWeight.bold,
                                         ),
                                       ),
                                       style: TextButton.styleFrom(
                                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                         minimumSize: Size.zero,
                                         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                       ),
                                     ),
                                     Text(
                                       _formatFrenchDate(log.timestamp.toString()),
                                       style: const TextStyle(
                                         fontFamily: 'Fredoka',
                                         fontSize: 11,
                                         color: AppColors.textGrey,
                                       ),
                                     ),
                                     TextButton.icon(
                                       onPressed: () => _confirmDelete(context, log),
                                       icon: const HugeIcon(
                                         icon: AppIcons.delete,
                                         color: Colors.redAccent,
                                         size: 16,
                                       ),
                                       label: const Text(
                                         "Supprimer",
                                         style: TextStyle(
                                           fontFamily: 'Fredoka',
                                           fontSize: 12,
                                           color: Colors.redAccent,
                                           fontWeight: FontWeight.bold,
                                         ),
                                       ),
                                       style: TextButton.styleFrom(
                                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                         minimumSize: Size.zero,
                                         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                       ),
                                     ),
                                   ],
                                 ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
          return Container();
        },
      ),
    );
  }
}
