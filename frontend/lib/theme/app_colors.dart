import 'package:flutter/material.dart';

/// All colour constants extracted from the mockups for consistent styling.
class AppColors {
  AppColors._();

  // ── Primary greens ──────────────────────────────────────────────────
  static const Color darkGreen = Color(0xFF2D4A1E);
  static const Color lightGreen = Color(0xFFEAF3DE);
  static const Color greenBorder = Color(0xFFC0DD97);
  static const Color activeGreen = Color(0xFF3B6D11);
  static const Color deepGreenText = Color(0xFF27500A);

  // ── Status colours ──────────────────────────────────────────────────
  static const Color statusGreen = Color(0xFF639922);
  static const Color statusAmber = Color(0xFFEF9F27);
  static const Color statusRed = Color(0xFFE24B4A);

  // ── Info / background colours ───────────────────────────────────────
  static const Color blueInfo = Color(0xFF378ADD);
  static const Color blueBg = Color(0xFFE6F1FB);
  static const Color amberBg = Color(0xFFFAEEDA);
  static const Color redBg = Color(0xFFFCEBEB);

  // ── Red accents ─────────────────────────────────────────────────────
  static const Color redBorder = Color(0xFFF7C1C1);
  static const Color redText = Color(0xFFA32D2D);

  // ── Hero / header text colours ──────────────────────────────────────
  static const Color heroText = Color(0xFFE8F0E1);
  static const Color heroSubtitle = Color(0xFF7FB86A);
  static const Color heroMuted = Color(0xFFA8C890);

  // ── Hero card overlay ───────────────────────────────────────────────
  static const Color heroCardOverlay = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  // ── Chip: green variant ─────────────────────────────────────────────
  static const Color chipGreenBg = Color(0xFFEAF3DE);
  static const Color chipGreenBorder = Color(0xFFC0DD97);
  static const Color chipGreenText = Color(0xFF27500A);

  // ── Chip: amber variant ─────────────────────────────────────────────
  static const Color chipAmberBg = Color(0xFFFAEEDA);
  static const Color chipAmberBorder = Color(0xFFEF9F27);
  static const Color chipAmberText = Color(0xFF7A5100);

  // ── Chip: blue variant ──────────────────────────────────────────────
  static const Color chipBlueBg = Color(0xFFE6F1FB);
  static const Color chipBlueBorder = Color(0xFF378ADD);
  static const Color chipBlueText = Color(0xFF1A4D80);

  // ── Filter chip colours ─────────────────────────────────────────────
  static const Color filterChipActiveBg = Color(0xFF2D4A1E);
  static const Color filterChipActiveText = Color(0xFFC8DDB8);
}

/// Centralised Material theme built from [AppColors].
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkGreen,
        primary: AppColors.darkGreen,
        secondary: AppColors.activeGreen,
        error: AppColors.statusRed,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.activeGreen,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.activeGreen,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightGreen,
        selectedColor: AppColors.darkGreen,
        side: const BorderSide(color: AppColors.greenBorder),
        labelStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.deepGreenText,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.deepGreenText,
        ),
        bodyMedium: TextStyle(color: Colors.black87),
        bodySmall: TextStyle(color: Colors.black54),
      ),
    );
  }
}
