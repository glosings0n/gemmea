import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:gemmea/core/core.dart';
import 'package:gemmea/presentation/bloc/bloc.dart';
import 'package:gemmea/presentation/pages/pages.dart';

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  @override
  void initState() {
    super.initState();
    // Start checking model file existence on start
    context.read<InitializationCubit>().checkStatus();
  }

  String _getFriendlyErrorMessage(String rawError) {
    if (rawError.contains('SocketException') || 
        rawError.contains('ClientException') ||
        rawError.contains('Connection closed') ||
        rawError.contains('internet') ||
        rawError.contains('connection')) {
      return "La connexion avec le serveur a été interrompue. Pas d'inquiétude ! Appuyez sur Reprendre pour continuer le téléchargement exactement là où il s'est arrêté.";
    }
    if (rawError.contains('HttpException') || rawError.contains('status')) {
      return "Nos serveurs de téléchargement sécurisés sont actuellement occupés. Réessayons dans quelques secondes pour récupérer le modèle IA Gemma.";
    }
    return "Un léger contretemps est survenu lors de la configuration. Veuillez appuyer sur Reprendre pour continuer le téléchargement du modèle Gemma.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<InitializationCubit, InitializationState>(
        listener: (context, state) {
          if (state is InitializationSuccess) {
            // Navigate to Main Navigation Holder once initialized successfully
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigationHolder()),
            );
          } else if (state is InitializationFailure) {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (dialogCtx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.r16)),
                title: const Row(
                  children: [
                    HugeIcon(icon: AppIcons.wifiOff, color: AppColors.accentYellow, size: 28.0),
                    SizedBox(width: 10),
                    Text(
                      "Statut de la connexion",
                      style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                content: Text(
                  _getFriendlyErrorMessage(state.error),
                  style: const TextStyle(fontFamily: 'Fredoka', fontSize: 14, height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        color: AppColors.primaryForestGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSize.p24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon with circular container
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryForestGreen.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Gemmea",
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textCharcoal,
                    ),
                  ),
                  const SizedBox(height: AppSize.p8),
                  const Text(
                    "Agronome IA 100% hors ligne pour l'Est de la RDC",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 48),

                  if (state is InitializationChecking) ...[
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryForestGreen),
                    ),
                    const SizedBox(height: AppSize.p24),
                    const Text(
                      "Vérification des ressources d'intelligence locale...",
                      style: TextStyle(fontFamily: 'Fredoka', color: AppColors.textGrey),
                    ),
                  ] else if (state is InitializationCheckingConnection) ...[
                    // Custom Card for Connection Check Phase with Button showing Loading
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.r16)),
                      color: AppColors.cardCleanWhite,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSize.p20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Initialisation du modèle IA Gemma",
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textCharcoal,
                                  ),
                                ),
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryForestGreen),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSize.p12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppSize.r8),
                              child: LinearProgressIndicator(
                                value: 0.0,
                                minHeight: 8,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryForestGreen,
                                ),
                                backgroundColor: AppColors.primaryForestGreen.withValues(alpha: 0.12),
                              ),
                            ),
                            const SizedBox(height: AppSize.p16),
                            const Text(
                              "Vérification de la connexion de téléchargement. Placez le fichier Gemma 4 au format LiteRT dans le dossier Documents pour un fonctionnement 100% hors ligne.",
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 12,
                                color: AppColors.textGrey,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: AppSize.p16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: null, // Disabled during checks
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryForestGreen.withValues(alpha: 0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSize.r12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Vérification de la connexion...",
                                      style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (state is InitializationDownloading) ...[
                    // Custom download / initialization progress card
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.r16)),
                      color: AppColors.cardCleanWhite,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSize.p20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Initialisation du modèle IA Gemma",
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textCharcoal,
                                  ),
                                ),
                                Text(
                                  "${(state.progress * 100).toInt()}%",
                                  style: const TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryForestGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSize.p12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppSize.r8),
                              child: LinearProgressIndicator(
                                value: state.progress,
                                minHeight: 8,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryForestGreen,
                                ),
                                backgroundColor: AppColors.primaryForestGreen.withValues(alpha: 0.12),
                              ),
                            ),
                            const SizedBox(height: AppSize.p16),
                            const Text(
                              "Recherche du point de contrôle local. Placez le fichier Gemma 4 au format LiteRT dans le dossier Documents pour un fonctionnement 100% hors ligne.",
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 12,
                                color: AppColors.textGrey,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: AppSize.p16),
                            if (state.progress > 0.0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSize.p12, vertical: AppSize.p8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryForestGreen.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(AppSize.r8),
                                ),
                                child: const Row(
                                  children: [
                                    HugeIcon(icon: AppIcons.info, size: 16.0, color: AppColors.primaryForestGreen),
                                    SizedBox(width: AppSize.p8),
                                    Expanded(
                                      child: Text(
                                        "Veuillez garder l'application ouverte et active jusqu'à la fin du téléchargement.",
                                        style: TextStyle(
                                          fontFamily: 'Fredoka',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primaryForestGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSize.p16),
                            ],
                            if (state.progress == 0.0)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    context.read<InitializationCubit>().startDownload();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryForestGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSize.r12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Télécharger & Initialiser le Modèle",
                                    style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (state is InitializationFailure) ...[
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.r16)),
                      color: AppColors.cardCleanWhite,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSize.p20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Configuration du modèle en pause",
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textCharcoal,
                                  ),
                                ),
                                Text(
                                  "Interrompu",
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSize.p12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppSize.r8),
                              child: LinearProgressIndicator(
                                value: 0.0,
                                minHeight: 8,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.textGrey,
                                ),
                                backgroundColor: AppColors.textGrey.withValues(alpha: 0.12),
                              ),
                            ),
                            const SizedBox(height: AppSize.p16),
                            const Text(
                              "La configuration a été interrompue. Assurez-vous que votre connexion Internet est active, puis appuyez sur Reprendre pour continuer là où vous vous étiez arrêté.",
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 12,
                                color: AppColors.textGrey,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: AppSize.p16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  context.read<InitializationCubit>().startDownload();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryForestGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSize.r12),
                                  ),
                                ),
                                child: const Text(
                                  "Reprendre le téléchargement",
                                  style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
