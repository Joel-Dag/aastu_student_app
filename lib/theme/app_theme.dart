import 'package:flutter/material.dart';

class AppColors {
  static const aastuBlue = Color(0xFF003DA5);
  static const aastuBlueDark = Color(0xFF002B75);
  static const aastuBlueLight = Color(0xFF1A5FD4);
  static const aastuGold = Color(0xFFF5B800);
  static const aastuGoldDark = Color(0xFFD49E00);
  static const aastuGoldLight = Color(0xFFFFD54F);
  static const surfaceDark = Color(0xFF0A1628);
  static const cardDark = Color(0xFF122240);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.aastuBlue,
        brightness: Brightness.dark,
        primary: AppColors.aastuBlueLight,
        secondary: AppColors.aastuGold,
        surface: AppColors.surfaceDark,
      ),
      scaffoldBackgroundColor: AppColors.surfaceDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.aastuBlueDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.aastuGold,
          foregroundColor: AppColors.aastuBlueDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.aastuBlueLight.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.aastuBlueLight.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.aastuGold, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.cardDark),
        ),
      ),
    );
  }

  static LinearGradient get heroGradient => const LinearGradient(
        colors: [AppColors.aastuBlueDark, AppColors.aastuBlue, AppColors.aastuBlueLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get goldGradient => const LinearGradient(
        colors: [AppColors.aastuGoldDark, AppColors.aastuGold, AppColors.aastuGoldLight],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
}
