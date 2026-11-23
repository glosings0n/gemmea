import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:juamea/core/core.dart';
import 'package:juamea/domain/entities/eac_country_profile.dart';
import 'package:juamea/presentation/bloc/bloc.dart';
import 'package:juamea/presentation/pages/pages.dart';
import 'package:juamea/presentation/widgets/widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Widget _buildEacCountrySelector(
    BuildContext context,
    String activeCode,
    JuameaLanguage lang,
  ) {
    final activeProfile = EacCountryProfile.byCode(activeCode);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSize.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: EacCountryProfile.supportedCountries.length,
              separatorBuilder: (c, idx) => const SizedBox(width: 6),
              itemBuilder: (context, idx) {
                final country = EacCountryProfile.supportedCountries[idx];
                final isSelected = country.code == activeProfile.code;
                return GestureDetector(
                  onTap: () =>
                      context.read<HomeCubit>().setEacCountry(country.code),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryForestGreen
                          : AppColors.primaryForestGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${country.shortLabel(lang)} · ${country.narsInstitute}',
                      style: TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.primaryForestGreen,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${activeProfile.fullName(lang)} (${activeProfile.narsInstitute}) : ${activeProfile.rainfallSummary(lang)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Figtree',
              fontSize: 11,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

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
    final localeState = context.watch<LocaleCubit>().state;
    final lang = localeState.language;
    final strings = localeState.strings;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryForestGreen,
                  ),
                ),
              );
            } else if (state is HomeError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSize.p24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const HugeIcon(
                        icon: AppIcons.alert,
                        color: AppColors.errorRed,
                        size: AppSize.iconXl,
                      ),
                      const SizedBox(height: AppSize.p16),
                      Text(
                        "Error: ${state.error}",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSize.p16),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<HomeCubit>().loadDashboard(),
                        child: Text(strings.retryBtn),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is HomeLoaded) {
              final hasNew = state.diagnosticsHistory.any(
                (d) => d.status == 'new',
              );
              final activeProfile = EacCountryProfile.byCode(
                state.selectedCountryCode,
              );

              return Column(
                spacing: AppSize.p12,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSize.p16,
                      vertical: AppSize.p8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Juamea",
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: AppColors.primaryForestGreen,
                                ),
                              ),
                              Text(
                                strings.homeGreeting,
                                style: const TextStyle(
                                  fontFamily: 'Figtree',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textCharcoal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                strings.homeSubtitle,
                                style: const TextStyle(
                                  fontFamily: 'Figtree',
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: const Key('home_language_button'),
                                onTap: () => LanguageSelectorModal.show(context),
                                borderRadius: BorderRadius.circular(10),
                                child: Tooltip(
                                  message: strings.languageTooltip,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryForestGreen
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const HugeIcon(
                                          icon: AppIcons.globe,
                                          color: AppColors.primaryForestGreen,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          lang.shortLabel,
                                          style: const TextStyle(
                                            fontFamily: 'JetBrainsMono',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryForestGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => JuameaModelModal.show(context),
                                borderRadius: BorderRadius.circular(10),
                                child: Tooltip(
                                  message: strings.modelsTooltip,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryForestGreen
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const HugeIcon(
                                      icon: AppIcons.download,
                                      color: AppColors.primaryForestGreen,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  final diags = state.diagnosticsHistory
                                      .map((d) => d.toMap())
                                      .toList();
                                  final events = state.calendarEvents
                                      .map((c) => c.toMap())
                                      .toList();
                                  _showPdfOptionsBottomSheet(
                                    context,
                                    diags,
                                    events,
                                    activeProfile.reportLocation(lang),
                                    strings,
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Tooltip(
                                  message: strings.pdfTooltip,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryForestGreen
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const HugeIcon(
                                      icon: AppIcons.pdf,
                                      color: AppColors.primaryForestGreen,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const DiagnosticsHistoryPage(),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Tooltip(
                                  message: strings.historyTooltip,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryForestGreen
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        const HugeIcon(
                                          icon: AppIcons.license,
                                          color: AppColors.primaryForestGreen,
                                          size: 20,
                                        ),
                                        if (hasNew)
                                          const Positioned(
                                            right: -3,
                                            top: -3,
                                            child: _AnimatedDotBadge(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // East Africa 6-Country Agronomic Selector Strip
                  _buildEacCountrySelector(
                    context,
                    state.selectedCountryCode,
                    lang,
                  ),

                  // Fixed Non-scrollable Metrics Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSize.p16,
                    ),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppSize.p16,
                      mainAxisSpacing: AppSize.p16,
                      childAspectRatio: 1.25,
                      children: [
                        // Grid Card 1: Last Diagnostic
                        _buildMetricCard(
                          title: strings.lastDiagnosticTitle,
                          emoji: "🔍",
                          value: state.lastDiagnostic != null
                              ? state.lastDiagnostic!.disease
                                    .split('(')[0]
                                    .trim()
                              : strings.noScanYet,
                          subtitle: state.lastDiagnostic != null
                              ? "${(state.lastDiagnostic!.confidence * 100).toInt()}% ${strings.confidenceSuffix}"
                              : strings.tapScannerHint,
                          color: Colors.grey.withValues(alpha: 0.06),
                        ),

                        // Grid Card 2: Water Schedule
                        _buildMetricCard(
                          title: strings.waterScheduleTitle,
                          emoji: "💧",
                          value: state.calendarEvents.any((e) => e.isRainy)
                              ? strings.rainPausedTitle
                              : strings.irrigationActiveTitle,
                          subtitle: state.waterScheduleStatus,
                          color: Colors.blue.withValues(alpha: 0.06),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Body Content (Starts at Reminders)
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primaryForestGreen,
                      onRefresh: () {
                        return context.read<HomeCubit>().loadDashboard();
                      },
                      child: ListView(
                        primary: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSize.p16,
                        ),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          const SizedBox(height: AppSize.p8),

                          // Soil Reminders Card
                          Text(
                            strings.soilRemindersTitle,
                            style: const TextStyle(
                              fontFamily: 'Figtree',
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6.0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "🌱 ",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        Expanded(
                                          child: Text(
                                            reminder,
                                            style: const TextStyle(
                                              fontFamily: 'Figtree',
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
                              Expanded(
                                child: Text(
                                  strings.irrigationCalendarTitle,
                                  style: const TextStyle(
                                    fontFamily: 'Figtree',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textCharcoal,
                                  ),
                                ),
                              ),
                              Text(
                                strings.autonomousAdjustLabel,
                                style: const TextStyle(
                                  fontFamily: 'Figtree',
                                  fontSize: 12,
                                  color: AppColors.secondaryMint,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSize.p12),
                          ...state.calendarEvents.map((event) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSize.p12,
                              ),
                              child: Card(
                                child: ListTile(
                                  title: Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontFamily: 'Figtree',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.description,
                                        style: const TextStyle(
                                          fontFamily: 'Figtree',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text.rich(
                                        TextSpan(
                                          style: const TextStyle(
                                            fontFamily: 'Figtree',
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textGrey,
                                          ),
                                          children: [
                                            TextSpan(text: strings.dateLabel),
                                            TextSpan(
                                              text: _formatSlashDate(event.eventDate),
                                              style: const TextStyle(
                                                fontFamily: 'JetBrainsMono',
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                                color: AppColors.textCharcoal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        strings.rainSwitchLabel,
                                        style: const TextStyle(
                                          fontFamily: 'Figtree',
                                          fontSize: 12,
                                        ),
                                      ),
                                      Switch(
                                        value: event.isRainy,
                                        onChanged: (val) {
                                          context.read<HomeCubit>().toggleRain(
                                            event.eventDate,
                                            val,
                                          );
                                        },
                                        activeThumbColor:
                                            AppColors.primaryForestGreen,
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
                  ),
                ],
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
        border: Border.all(
          color: AppColors.primaryForestGreen.withValues(alpha: 0.1),
          width: 1,
        ),
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
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPdfOptionsBottomSheet(
    BuildContext context,
    List<Map<String, dynamic>> diags,
    List<Map<String, dynamic>> events,
    String farmerLocation,
    JuameaStringsData strings,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.pdfSheetTitle,
                style: const TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textCharcoal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.pdfSheetSubtitle,
                style: const TextStyle(
                  fontFamily: 'Figtree',
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
                    final path =
                        await PDFReportService.downloadReportToDocuments(
                          diagnostics: diags,
                          calendarEvents: events,
                          farmerLocation: farmerLocation,
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
                                  "${strings.pdfSavedSnackPrefix} :\n$filename",
                                  style: const TextStyle(
                                    fontFamily: 'Figtree',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                  PDFReportService.openPdfFile(path);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    strings.pdfOpenBtn,
                                    style: const TextStyle(
                                      fontFamily: 'Figtree',
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 6),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${strings.pdfDownloadErrorPrefix}: $e"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryForestGreen.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryForestGreen.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryForestGreen.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const HugeIcon(
                          icon: AppIcons.download,
                          color: AppColors.primaryForestGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.pdfDownloadTitle,
                              style: const TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textCharcoal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.pdfDownloadSubtitle,
                              style: const TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const HugeIcon(
                        icon: AppIcons.arrowRight,
                        color: AppColors.textGrey,
                        size: 18,
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
                    await PDFReportService.shareReport(
                      diagnostics: diags,
                      calendarEvents: events,
                      farmerLocation: farmerLocation,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${strings.pdfShareErrorPrefix}: $e"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryForestGreen.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryForestGreen.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryForestGreen.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const HugeIcon(
                          icon: AppIcons.share,
                          color: AppColors.primaryForestGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.pdfShareTitle,
                              style: const TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textCharcoal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.pdfShareSubtitle,
                              style: const TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const HugeIcon(
                        icon: AppIcons.arrowRight,
                        color: AppColors.textGrey,
                        size: 18,
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
}

class _AnimatedDotBadge extends StatefulWidget {
  const _AnimatedDotBadge();

  @override
  State<_AnimatedDotBadge> createState() => _AnimatedDotBadgeState();
}

class _AnimatedDotBadgeState extends State<_AnimatedDotBadge>
    with SingleTickerProviderStateMixin {
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
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(
                  alpha: 0.6 * _controller.value,
                ),
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
