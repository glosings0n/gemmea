import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:gemmea/core/theme/app_theme.dart';
import 'package:gemmea/presentation/bloc/home_cubit.dart';
import 'package:gemmea/presentation/pages/diagnostics_history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load dashboard elements on start
    context.read<HomeCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: Image.asset('assets/images/logo.png'),
            ),
            const SizedBox(width: 8),
            const Text(
              "Gemmea",
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryForestGreen,
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              bool hasNew = false;
              if (state is HomeLoaded) {
                hasNew = state.diagnosticsHistory.any((d) => d.status == 'new');
              }
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DiagnosticsHistoryPage(),
                        ),
                      );
                    },
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedLicense,
                      color: AppTheme.primaryForestGreen,
                      size: 24,
                    ),
                  ),
                  if (hasNew)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: const _AnimatedDotBadge(),
                    ),
                ],
              );
            },
          ),
        ],
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
                    Text("Error: ${state.error}", textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<HomeCubit>().loadDashboard(),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is HomeLoaded) {
            return RefreshIndicator(
              color: AppTheme.primaryForestGreen,
              onRefresh: () => context.read<HomeCubit>().loadDashboard(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Farmer greeting
                    const Text(
                      "Jambo, Agriculteur ! 👋🏾",
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Votre ferme est entièrement protégée hors ligne.",
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Minimalist Grid layout summarizing metrics
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
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
                    const SizedBox(height: 24),

                    // Soil Reminders Card
                    const Text(
                      "Rappels du Sol",
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textCharcoal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
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
                                        color: AppTheme.textCharcoal,
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
                    const SizedBox(height: 24),

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
                            color: AppTheme.textCharcoal,
                          ),
                        ),
                        const Text(
                          "Ajustement autonome actif",
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 12,
                            color: AppTheme.secondaryMint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...state.calendarEvents.map((event) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
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
                                  "Date: ${event.eventDate}",
                                  style: const TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textGrey,
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
                                  activeThumbColor: AppTheme.primaryForestGreen,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryForestGreen.withValues(alpha: 0.1), width: 1),
      ),
      padding: const EdgeInsets.all(12),
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
                  color: AppTheme.textGrey,
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
                  color: AppTheme.textCharcoal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textGrey,
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
