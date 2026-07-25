import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:gemmea/core/core.dart';
import 'package:gemmea/presentation/bloc/bloc.dart';

class ScanResultModal extends StatelessWidget {
  final File capturedImage;

  const ScanResultModal({super.key, required this.capturedImage});

  Future<bool> _confirmAndCancelScan(BuildContext context) async {
    final cubit = context.read<ScanCubit>();
    if (cubit.state is! ScanProcessing) {
      return true;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardCleanWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.r16),
          ),
          title: const Row(
            children: [
              HugeIcon(
                icon: AppIcons.alert,
                color: AppColors.errorRed,
                size: 22.0,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Interrompre l'analyse ?",
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textCharcoal,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            "L'analyse IA de votre feuille est en cours. Voulez-vous vraiment annuler ? Le traitement sera interrompu et aucun diagnostic ne sera enregistré.",
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 13.5,
              color: AppColors.textCharcoal,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                "Continuer l'analyse",
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryForestGreen,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                "Oui, interrompre",
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

    if (shouldCancel == true) {
      cubit.cancelScan();
      return true;
    }
    return false;
  }

  void _handleClose(BuildContext context) async {
    final canClose = await _confirmAndCancelScan(context);
    if (canClose && context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canClose = await _confirmAndCancelScan(context);
        if (canClose && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSize.p24),
        decoration: const BoxDecoration(
          color: AppColors.cardCleanWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.r24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Analyse de Culture Gemmea",
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primaryForestGreen,
                  ),
                ),
                IconButton(
                  icon: const HugeIcon(
                    icon: AppIcons.close,
                    color: AppColors.textCharcoal,
                    size: 20.0,
                  ),
                  onPressed: () => _handleClose(context),
                ),
              ],
            ),
            const SizedBox(height: AppSize.p16),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSize.r12),
                      child: Image.file(
                        capturedImage,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: AppSize.p16),
                    BlocBuilder<ScanCubit, ScanState>(
                      builder: (context, state) {
                        if (state is ScanProcessing) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(color: AppColors.primaryForestGreen),
                                  SizedBox(height: 12),
                                  Text(
                                    "Gemma analyse l'image de la feuille hors ligne...",
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      color: AppColors.textGrey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        if (state is ScanSuccess) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Diagnostic et Remède Local :",
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.primaryForestGreen,
                                ),
                              ),
                              const SizedBox(height: AppSize.p8),
                              Container(
                                padding: const EdgeInsets.all(AppSize.p12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F7F4),
                                  borderRadius: BorderRadius.circular(AppSize.r8),
                                ),
                                child: MarkdownBody(
                                  data: state.diagnosis,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 14,
                                      color: AppColors.textCharcoal,
                                      height: 1.4,
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
                              ),
                            ],
                          );
                        }
                        if (state is ScanFailure) {
                          final isNotLeaf = state.isNotALeaf;
                          final cardBg = isNotLeaf
                              ? const Color(0xFFF8F9FA)
                              : const Color(0xFFFFF5F5);
                          final cardBorder = isNotLeaf
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFFFFCDD2);
                          final iconColor = isNotLeaf
                              ? AppColors.primaryForestGreen
                              : const Color(0xFFD32F2F);
                          final titleColor = isNotLeaf
                              ? AppColors.primaryForestGreen
                              : const Color(0xFFC62828);

                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(AppSize.r16),
                              border: Border.all(color: cardBorder, width: 1.2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    HugeIcon(
                                      icon: isNotLeaf ? AppIcons.focus : AppIcons.alert,
                                      color: iconColor,
                                      size: 24.0,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        state.title,
                                        style: TextStyle(
                                          fontFamily: 'Fredoka',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: titleColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSize.p12),
                                Text(
                                  state.userMessage,
                                  style: const TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 13.5,
                                    color: AppColors.textCharcoal,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: AppSize.p16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pop(context),
                                    icon: HugeIcon(
                                      icon: isNotLeaf ? AppIcons.scan : AppIcons.refresh,
                                      size: 18.0,
                                      color: titleColor,
                                    ),
                                    label: Text(
                                      isNotLeaf ? "Reprendre la photo" : "Fermer & Réessayer",
                                      style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: titleColor,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: cardBorder),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
