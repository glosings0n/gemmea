import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:gemmea/core/theme/app_theme.dart';
import '../bloc/scan_cubit.dart';

class ScanResultModal extends StatelessWidget {
  final File capturedImage;

  const ScanResultModal({super.key, required this.capturedImage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Analyse de Culture Gemmea", style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryForestGreen)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(capturedImage, height: 160, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<ScanCubit, ScanState>(
                    builder: (context, state) {
                      if (state is ScanProcessing) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Column(
                              children: [
                                CircularProgressIndicator(color: AppTheme.primaryForestGreen),
                                SizedBox(height: 12),
                                Text(
                                  "Gemma analyse l'image de la feuille hors ligne...",
                                  style: TextStyle(fontFamily: 'Fredoka', color: Colors.grey, fontSize: 13),
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
                              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryForestGreen),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFF4F7F4), borderRadius: BorderRadius.circular(8)),
                              child: MarkdownBody(
                                data: state.diagnosis,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 14,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                  strong: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Fredoka',
                                    color: Colors.black87,
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
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Veuillez fournir une image",
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppTheme.textCharcoal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.error,
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                  height: 1.3,
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
    );
  }
}
