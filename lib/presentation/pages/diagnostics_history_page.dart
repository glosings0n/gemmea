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
                                    p: const TextStyle(
                                      fontFamily: 'Fredoka',
                                      height: 1.4,
                                      color: AppColors.textCharcoal,
                                      fontSize: 14,
                                    ),
                                    strong: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Fredoka',
                                      color: AppColors.textCharcoal,
                                    ),
                                    listBullet: const TextStyle(
                                      fontFamily: 'Fredoka',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSize.p12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const HugeIcon(
                                          icon: AppIcons.calendar,
                                          color: AppColors.textGrey,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Enregistré le : ${_formatFrenchDate(log.timestamp.toString())}",
                                          style: const TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontSize: 11,
                                            color: AppColors.textGrey,
                                          ),
                                        ),
                                      ],
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
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
