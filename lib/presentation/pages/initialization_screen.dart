import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:juamea/core/core.dart';
import 'package:juamea/presentation/bloc/bloc.dart';
import 'package:juamea/presentation/pages/pages.dart';

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InitializationCubit>().checkStatus();
  }

  String _getFriendlyErrorMessage(String rawError, JuameaStringsData strings) {
    if (rawError.contains('SocketException') ||
        rawError.contains('ClientException') ||
        rawError.contains('Connection closed') ||
        rawError.contains('internet') ||
        rawError.contains('connection')) {
      return strings.initErrorNetwork;
    }
    if (rawError.contains('HttpException') || rawError.contains('status')) {
      return strings.initErrorServer;
    }
    return strings.initErrorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    final localeState = context.watch<LocaleCubit>().state;
    final strings = localeState.strings;
    final activeLang = localeState.language;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<InitializationCubit, InitializationState>(
          listener: (context, state) {
            if (state is InitializationSuccess) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainNavigationHolder()),
              );
            } else if (state is InitializationFailure) {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (dialogCtx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSize.r16),
                  ),
                  title: Row(
                    children: [
                      const HugeIcon(
                        icon: AppIcons.wifiOff,
                        color: AppColors.accentYellow,
                        size: 28.0,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings.initConnectionStatusTitle,
                          style: const TextStyle(
                            fontFamily: 'Figtree',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    _getFriendlyErrorMessage(state.error, strings),
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: Text(
                        strings.okBtn,
                        style: const TextStyle(
                          fontFamily: 'Figtree',
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
            return Stack(
              children: [
                // Compact FR / EN / SW switcher top-right
                Positioned(
                  top: 8,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryForestGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: JuameaLanguage.values.map((lang) {
                        final selected = lang == activeLang;
                        return GestureDetector(
                          onTap: () => context.read<LocaleCubit>().setLanguage(lang),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryForestGreen
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              lang.shortLabel,
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? Colors.white
                                    : AppColors.primaryForestGreen,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSize.p24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryForestGreen
                                    .withValues(alpha: 0.08),
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
                          'Juamea',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: AppColors.textCharcoal,
                          ),
                        ),
                        const SizedBox(height: AppSize.p8),
                        Text(
                          strings.initSubtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 14,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 48),

                        if (state is InitializationChecking) ...[
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryForestGreen,
                            ),
                          ),
                          const SizedBox(height: AppSize.p24),
                          Text(
                            strings.initChecking,
                            style: const TextStyle(
                              fontFamily: 'Figtree',
                              color: AppColors.textGrey,
                            ),
                          ),
                        ] else if (state is InitializationCheckingConnection) ...[
                          Card(
                            elevation: 4,
                            shadowColor: Colors.black.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSize.r16),
                            ),
                            color: AppColors.cardCleanWhite,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSize.p20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          strings.initCardTitle,
                                          style: const TextStyle(
                                            fontFamily: 'Figtree',
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textCharcoal,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            AppColors.primaryForestGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSize.p12),
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(AppSize.r8),
                                    child: LinearProgressIndicator(
                                      value: 0.0,
                                      minHeight: 8,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryForestGreen,
                                      ),
                                      backgroundColor:
                                          AppColors.primaryForestGreen
                                              .withValues(alpha: 0.12),
                                    ),
                                  ),
                                  const SizedBox(height: AppSize.p16),
                                  Text(
                                    strings.initConnectingDesc,
                                    style: const TextStyle(
                                      fontFamily: 'Figtree',
                                      fontSize: 12,
                                      color: AppColors.textGrey,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: AppSize.p16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.primaryForestGreen
                                                .withValues(alpha: 0.6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppSize.r12,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            strings.initCheckingConnectionBtn,
                                            style: const TextStyle(
                                              fontFamily: 'Figtree',
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
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
                          Card(
                            elevation: 4,
                            shadowColor: Colors.black.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSize.r16),
                            ),
                            color: AppColors.cardCleanWhite,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSize.p20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          strings.initCardTitle,
                                          style: const TextStyle(
                                            fontFamily: 'Figtree',
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textCharcoal,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${(state.progress * 100).toInt()}%',
                                        style: const TextStyle(
                                          fontFamily: 'JetBrainsMono',
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryForestGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSize.p12),
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(AppSize.r8),
                                    child: LinearProgressIndicator(
                                      value: state.progress,
                                      minHeight: 8,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryForestGreen,
                                      ),
                                      backgroundColor:
                                          AppColors.primaryForestGreen
                                              .withValues(alpha: 0.12),
                                    ),
                                  ),
                                  const SizedBox(height: AppSize.p16),
                                  Text(
                                    strings.initDownloadDesc,
                                    style: const TextStyle(
                                      fontFamily: 'Figtree',
                                      fontSize: 12,
                                      color: AppColors.textGrey,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: AppSize.p16),
                                  if (state.progress > 0.0) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSize.p12,
                                        vertical: AppSize.p8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryForestGreen
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(AppSize.r8),
                                      ),
                                      child: Row(
                                        children: [
                                          const HugeIcon(
                                            icon: AppIcons.info,
                                            size: 16.0,
                                            color: AppColors.primaryForestGreen,
                                          ),
                                          const SizedBox(width: AppSize.p8),
                                          Expanded(
                                            child: Text(
                                              strings.initKeepOpenNotice,
                                              style: const TextStyle(
                                                fontFamily: 'Figtree',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors
                                                    .primaryForestGreen,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppSize.p16),
                                  ],
                                  if (state.progress == 0.0) ...[
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          context
                                              .read<InitializationCubit>()
                                              .startDownload();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryForestGreen,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppSize.r12,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          strings.initDownloadBtn,
                                          style: const TextStyle(
                                            fontFamily: 'Figtree',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSize.p8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const MainNavigationHolder(),
                                            ),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              AppColors.primaryForestGreen,
                                          side: BorderSide(
                                            color: AppColors.primaryForestGreen
                                                .withValues(alpha: 0.4),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppSize.r12,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          strings.initSkipBtn,
                                          style: const TextStyle(
                                            fontFamily: 'Figtree',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ] else if (state is InitializationFailure) ...[
                          Card(
                            elevation: 4,
                            shadowColor: Colors.black.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSize.r16),
                            ),
                            color: AppColors.cardCleanWhite,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSize.p20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          strings.initPausedTitle,
                                          style: const TextStyle(
                                            fontFamily: 'Figtree',
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textCharcoal,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        strings.initPausedBadge,
                                        style: const TextStyle(
                                          fontFamily: 'Figtree',
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSize.p12),
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(AppSize.r8),
                                    child: LinearProgressIndicator(
                                      value: 0.0,
                                      minHeight: 8,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppColors.textGrey,
                                      ),
                                      backgroundColor: AppColors.textGrey
                                          .withValues(alpha: 0.12),
                                    ),
                                  ),
                                  const SizedBox(height: AppSize.p16),
                                  Text(
                                    strings.initPausedDesc,
                                    style: const TextStyle(
                                      fontFamily: 'Figtree',
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
                                        context
                                            .read<InitializationCubit>()
                                            .startDownload();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.primaryForestGreen,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppSize.r12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        strings.initResumeBtn,
                                        style: const TextStyle(
                                          fontFamily: 'Figtree',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSize.p8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const MainNavigationHolder(),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            AppColors.primaryForestGreen,
                                        side: BorderSide(
                                          color: AppColors.primaryForestGreen
                                              .withValues(alpha: 0.4),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppSize.r12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        strings.initSkipBtn,
                                        style: const TextStyle(
                                          fontFamily: 'Figtree',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
