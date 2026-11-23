import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:juamea/core/core.dart';
import 'package:juamea/presentation/bloc/bloc.dart';

/// Modal bottom sheet allowing the farmer to switch Juamea between FR, EN, and SW.
class LanguageSelectorModal {
  const LanguageSelectorModal._();

  static Future<void> show(BuildContext context) {
    final localeCubit = context.read<LocaleCubit>();
    final homeCubit = context.read<HomeCubit>();
    final chatCubit = context.read<ChatCubit>();

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardCleanWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return BlocBuilder<LocaleCubit, LocaleState>(
          bloc: localeCubit,
          builder: (_, localeState) {
            final strings = localeState.strings;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      strings.selectLanguageTitle,
                      style: const TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.selectLanguageSubtitle,
                      style: const TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 12.5,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...JuameaLanguage.values.map((lang) {
                      final isSelected = lang == localeState.language;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            await localeCubit.setLanguage(lang);
                            homeCubit.loadDashboard(isSilent: true);
                            chatCubit.refreshLanguageStrings();
                            if (sheetCtx.mounted) {
                              Navigator.of(sheetCtx).pop();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryForestGreen.withValues(alpha: 0.08)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryForestGreen
                                    : Colors.grey.shade200,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryForestGreen
                                        : AppColors.primaryForestGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    lang.shortLabel,
                                    style: TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.primaryForestGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lang.nativeName,
                                        style: const TextStyle(
                                          fontFamily: 'Figtree',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textCharcoal,
                                        ),
                                      ),
                                      Text(
                                        lang.regionTag,
                                        style: const TextStyle(
                                          fontFamily: 'Figtree',
                                          fontSize: 11.5,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const HugeIcon(
                                    icon: AppIcons.check,
                                    color: AppColors.primaryForestGreen,
                                    size: 20,
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
          },
        );
      },
    );
  }
}
