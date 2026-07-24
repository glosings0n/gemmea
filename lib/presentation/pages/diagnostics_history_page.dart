import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:gemmea/core/theme/app_theme.dart';
import 'package:gemmea/presentation/bloc/home_cubit.dart';

class DiagnosticsHistoryPage extends StatefulWidget {
  const DiagnosticsHistoryPage({super.key});

  @override
  State<DiagnosticsHistoryPage> createState() => _DiagnosticsHistoryPageState();
}

class _DiagnosticsHistoryPageState extends State<DiagnosticsHistoryPage> {
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
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppTheme.cardCleanWhite,
          title: const Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedAlertCircle,
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
                  color: AppTheme.textCharcoal,
                ),
              ),
            ],
          ),
          content: Text(
            "Êtes-vous sûr de vouloir supprimer ce diagnostic du ${log.timestamp.toString().split(' ')[0]} ? Cette action est irréversible.",
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 14,
              color: AppTheme.textGrey,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                "Annuler",
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textGrey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              backgroundColor: AppTheme.primaryForestGreen,
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryForestGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Historique des Diagnostics",
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryForestGreen,
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
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryForestGreen),
              ),
            );
          } else if (state is HomeError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      "Error: ${state.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Fredoka', color: AppTheme.textCharcoal),
                    ),
                    const SizedBox(height: 16),
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
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryForestGreen.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Text("🍃", style: TextStyle(fontSize: 48)),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Aucun diagnostic de plante",
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textCharcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Utilisez l'icône appareil photo pour scanner les feuilles de maïs ou de manioc. Vos diagnostics apparaîtront ici.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 14,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: AppTheme.primaryForestGreen,
              onRefresh: () => context.read<HomeCubit>().loadDashboard(),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: state.diagnosticsHistory.length,
                itemBuilder: (context, index) {
                  final log = state.diagnosticsHistory[index];
                  final isNew = log.status == 'new';

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isNew 
                            ? AppTheme.primaryForestGreen.withValues(alpha: 0.3) 
                            : AppTheme.primaryForestGreen.withValues(alpha: 0.05),
                        width: isNew ? 1.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ExpansionTile(
                        backgroundColor: isNew 
                            ? AppTheme.primaryForestGreen.withValues(alpha: 0.02) 
                            : Colors.transparent,
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isNew 
                                ? AppTheme.primaryForestGreen.withValues(alpha: 0.1) 
                                : AppTheme.primaryForestGreen.withValues(alpha: 0.05),
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
                                  color: AppTheme.textCharcoal,
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
                            color: AppTheme.textGrey,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (log.imagePath != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
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
                                  const SizedBox(height: 12),
                                 Container(
                                   padding: const EdgeInsets.all(12),
                                   decoration: BoxDecoration(
                                     color: Colors.amber.withValues(alpha: 0.1),
                                     borderRadius: BorderRadius.circular(10),
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
                                                 color: AppTheme.textCharcoal,
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
                                 const SizedBox(height: 12),
                                ],
                                const Text(
                                  "Actions correctives recommandées (IITA) :",
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryForestGreen,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                MarkdownBody(
                                  data: log.remedy,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(
                                      fontFamily: 'Fredoka',
                                      height: 1.4,
                                      color: AppTheme.textCharcoal,
                                      fontSize: 14,
                                    ),
                                    strong: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Fredoka',
                                      color: AppTheme.textCharcoal,
                                    ),
                                    listBullet: const TextStyle(
                                      fontFamily: 'Fredoka',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const HugeIcon(
                                          icon: HugeIcons.strokeRoundedCalendar01,
                                          color: AppTheme.textGrey,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Enregistré le : ${log.timestamp.toString().split('.')[0]}",
                                          style: const TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontSize: 11,
                                            color: AppTheme.textGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _confirmDelete(context, log),
                                      icon: const HugeIcon(
                                        icon: HugeIcons.strokeRoundedDelete02,
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
