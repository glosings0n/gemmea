import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:juamea/core/constants/app_colors.dart';

class AppFonts {
  AppFonts._();

  /// Primary body, titles, cards, buttons & dialogs.
  static const String body = 'Figtree';

  /// Tabular numeric values, dates, percentages & clinical/agronomic metrics.
  static const String mono = 'JetBrainsMono';

  /// Brand wordmark ("Juamea").
  static const String brand = 'Urbanist';
}

class AppTheme {
  static const Color primaryForestGreen = AppColors.primaryForestGreen;
  static const Color secondaryMint = AppColors.secondaryMint;
  static const Color backgroundOffWhite = AppColors.backgroundOffWhite;
  static const Color cardCleanWhite = AppColors.cardCleanWhite;
  static const Color textCharcoal = AppColors.textCharcoal;
  static const Color textGrey = AppColors.textGrey;
  static const Color accentYellow = AppColors.accentYellow;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundOffWhite,
      primaryColor: AppColors.primaryForestGreen,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryForestGreen,
        secondary: AppColors.secondaryMint,
        surface: AppColors.cardCleanWhite,
        onPrimary: AppColors.cardCleanWhite,
        onSecondary: AppColors.cardCleanWhite,
      ),
      fontFamily: AppFonts.body,
      cardTheme: CardThemeData(
        color: AppColors.cardCleanWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSoft, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundOffWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Keep system status bar icons dark!
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.body,
          color: AppColors.textCharcoal,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textCharcoal),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontFamily: AppFonts.body, color: AppColors.textCharcoal, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: TextStyle(fontFamily: AppFonts.body, color: AppColors.textCharcoal, fontWeight: FontWeight.w600, fontSize: 18),
        bodyLarge: TextStyle(fontFamily: AppFonts.body, color: AppColors.textCharcoal, fontSize: 16),
        bodyMedium: TextStyle(fontFamily: AppFonts.body, color: AppColors.textGrey, fontSize: 14),
      ),
    );
  }
}
