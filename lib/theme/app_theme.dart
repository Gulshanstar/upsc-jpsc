import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.gold,             // Terracotta
        onPrimary: Colors.white,             // White text on terracotta
        secondary: AppColors.green,          // Sage green
        onSecondary: Colors.white,
        surface: AppColors.surface,          // Pure white surface
        onSurface: AppColors.textPrimary,    // Warm charcoal text
        error: AppColors.red,
        onError: Colors.white,
        outline: AppColors.border,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Dark status bar icons on warm cream background
        titleTextStyle: GoogleFonts.instrumentSerif(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.goldSurface,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
        linearTrackColor: AppColors.surfaceElevated,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(color: AppColors.background),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.instrumentSerif(
        fontSize: 57, color: AppColors.textPrimary, fontWeight: FontWeight.w400),
      displayMedium: GoogleFonts.instrumentSerif(
        fontSize: 45, color: AppColors.textPrimary, fontWeight: FontWeight.w400),
      displaySmall: GoogleFonts.instrumentSerif(
        fontSize: 36, color: AppColors.textPrimary, fontWeight: FontWeight.w400),
      headlineLarge: GoogleFonts.instrumentSerif(
        fontSize: 32, color: AppColors.textPrimary, fontWeight: FontWeight.w400),
      headlineMedium: GoogleFonts.instrumentSerif(
        fontSize: 28, color: AppColors.textPrimary, fontWeight: FontWeight.w400),
      headlineSmall: GoogleFonts.instrumentSerif(
        fontSize: 24, color: AppColors.textPrimary, fontWeight: FontWeight.w400),
      titleLarge: GoogleFonts.inter(
        fontSize: 22, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(
        fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.inter(
        fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.inter(
        fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      labelMedium: GoogleFonts.inter(
        fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.inter(
        fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
    );
  }
}

// Spacing constants
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

// Border radius constants
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 100;
}
