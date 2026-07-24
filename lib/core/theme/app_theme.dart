import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color primaryForestGreen = Color(0xFF1B4324);
  static const Color secondaryMint = Color(0xFF2E7D32);
  static const Color backgroundOffWhite = Color(0xFFF6F8F5);
  static const Color cardCleanWhite = Color(0xFFFFFFFF);
  static const Color textCharcoal = Color(0xFF1E2721);
  static const Color textGrey = Color(0xFF6B7A70);
  static const Color accentYellow = Color(0xFFFBC02D);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundOffWhite,
      primaryColor: primaryForestGreen,
      colorScheme: const ColorScheme.light(
        primary: primaryForestGreen,
        secondary: secondaryMint,
        surface: cardCleanWhite,
        onPrimary: cardCleanWhite,
        onSecondary: cardCleanWhite,
      ),
      fontFamily: 'Fredoka', // Global Fredoka font connection
      cardTheme: CardThemeData(
        color: cardCleanWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2EBE5), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundOffWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Keep system status bar icons dark!
        titleTextStyle: TextStyle(
          fontFamily: 'Fredoka',
          color: textCharcoal,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textCharcoal),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: textCharcoal, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: TextStyle(color: textCharcoal, fontWeight: FontWeight.w600, fontSize: 18),
        bodyLarge: TextStyle(color: textCharcoal, fontSize: 16),
        bodyMedium: TextStyle(color: textGrey, fontSize: 14),
      ),
    );
  }
}
