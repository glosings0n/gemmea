import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:gemmea/core/core.dart';
import 'package:gemmea/presentation/bloc/bloc.dart';
import 'package:gemmea/presentation/pages/pages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _formatSlashDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return "$day/$month/${dt.year}";
    } catch (_) {
      return dateStr;
    }
  }

  @override
  void initState() {
    super.initState();
    // Load dashboard elements on start
    context.read<HomeCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
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
                      Text("Error: ${state.error}", textAlign: TextAlign.center),
                      const SizedBox(height: AppSize.p16),
                      ElevatedButton(
                        onPressed: () => context.read<HomeCubit>().loadDashboard(),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is HomeLoaded) {
              final hasNew = state.diagnosticsHistory.any((d) => d.status == 'new');

              return RefreshIndicator(
                color: AppColors.primaryForestGreen,
                onRefresh: () => context.read<HomeCubit>().loadDashboard(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSize.p16),
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Jambo ! 👋🏾 on left, Action buttons on right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Jambo ! 👋🏾",
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textCharcoal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Votre ferme est entièrement protégée hors ligne.",
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 12.5,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Exporter le Rapport PDF',
                                onPressed: () async {
                                  final diags = state.diagnosticsHistory.map((d) => d.toMap()).toList();
                                  final events = state.calendarEvents.map((c) => c.toMap()).toList();
                                  await PDFReportService.printOrShareReport(
                                    diagnostics: diags,
                                    calendarEvents: events,
                                    farmerLocation: 'Bukavu, Sud-Kivu, RDC',
                                  );
                                },
                                icon: const HugeIcon(
                                  icon: AppIcons.pdf,
                                  color: AppColors.primaryForestGreen,
                                  size: AppSize.iconMd,
                                ),
                              ),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    tooltip: 'Historique des diagnostics',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const DiagnosticsHistoryPage(),
                                        ),
                                      );
                                    },
                                    icon: const HugeIcon(
                                      icon: AppIcons.license,
                                      color: AppColors.primaryForestGreen,
                                      size: AppSize.iconMd,
                                    ),
                                  ),
                                  if (hasNew)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: const _AnimatedDotBadge(),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSize.p24),

                    // Minimalist Grid layout summarizing metrics
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppSize.p16,
                      mainAxisSpacing: AppSize.p16,
                      childAspectRatio: 1.25,
                      children: [
                        // Grid Card 1: Last Diagnostic
                        _buildMetricCard(
                          title: "Dernier Diagnostic",
                          emoji: "🔍",
                          value: state.lastDiagnostic != null
                              ? state.lastDiagnostic!.disease.split('(')[0].trim()
                              : "Aucun scan effectué",
                          subtitle: state.lastDiagnostic != null
                              ? "${(state.lastDiagnostic!.confidence * 100).toInt()}% de confiance"
                              : "Appuyez sur scanneur",
                          color: Colors.blue.withValues(alpha: 0.06),
                        ),

                        // Grid Card 2: Water Schedule
                        _buildMetricCard(
                          title: "Programme d'Eau",
                          emoji: "💧",
                          value: state.calendarEvents.any((e) => e.isRainy)
                              ? "Pluie - Calendrier en pause"
                              : "Irrigation active",
                          subtitle: state.waterScheduleStatus,
                          color: Colors.teal.withValues(alpha: 0.06),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSize.p24),

                    // Soil Reminders Card
                    const Text(
                      "Rappels du Sol",
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    const SizedBox(height: AppSize.p12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSize.p16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: state.soilReminders.map((reminder) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("🌱 ", style: TextStyle(fontSize: 16)),
                                  Expanded(
                                    child: Text(
                                      reminder,
                                      style: const TextStyle(
                                        fontFamily: 'Fredoka',
                                        color: AppColors.textCharcoal,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSize.p24),

                    // Water Timetable autonomous adjustments
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Calendrier d'Irrigation",
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textCharcoal,
                          ),
                        ),
                        const Text(
                          "Ajustement autonome actif",
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 12,
                            color: AppColors.secondaryMint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSize.p12),
                    ...state.calendarEvents.map((event) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSize.p12),
                        child: Card(
                          child: ListTile(
                            title: Text(
                              event.title,
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.description,
                                  style: const TextStyle(fontFamily: 'Fredoka'),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Date: ${_formatSlashDate(event.eventDate)}",
                                  style: const TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "Pluie ",
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 12,
                                  ),
                                ),
                                Switch(
                                  value: event.isRainy,
                                  onChanged: (val) {
                                    context.read<HomeCubit>().toggleRain(event.eventDate, val);
                                  },
                                  activeThumbColor: AppColors.primaryForestGreen,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }
          return Container();
        },
      ),
    ),
  );
  }

  Widget _buildMetricCard({
    required String title,
    required String emoji,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSize.r16),
        border: Border.all(color: AppColors.primaryForestGreen.withValues(alpha: 0.1), width: 1),
      ),
      padding: const EdgeInsets.all(AppSize.p12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
              Text(emoji, style: const TextStyle(fontSize: 18)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textCharcoal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedDotBadge extends StatefulWidget {
  const _AnimatedDotBadge();

  @override
  State<_AnimatedDotBadge> createState() => _AnimatedDotBadgeState();
}

class _AnimatedDotBadgeState extends State<_AnimatedDotBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.6 * _controller.value),
                blurRadius: 5 * _controller.value,
                spreadRadius: 2.5 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
