import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gemmea/core/constants/app_colors.dart';

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
      fontFamily: 'Fredoka', // Global Fredoka font connection
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
          fontFamily: 'Fredoka',
          color: AppColors.textCharcoal,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textCharcoal),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: AppColors.textCharcoal, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: TextStyle(color: AppColors.textCharcoal, fontWeight: FontWeight.w600, fontSize: 18),
        bodyLarge: TextStyle(color: AppColors.textCharcoal, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textGrey, fontSize: 14),
      ),
    );
  }
}
