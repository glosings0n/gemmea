import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
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
              const Text("Moteur de Vision Gemmea", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0D5C3A))),
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
                                CircularProgressIndicator(color: Color(0xFF0D5C3A)),
                                SizedBox(height: 12),
                                Text("Gemma analyse la matrice de la feuille hors ligne...", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ),
                        );
                      }
                      if (state is ScanSuccess) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Diagnostic et Remède Local :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                        return Text(state.error, style: const TextStyle(color: Colors.redAccent));
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
