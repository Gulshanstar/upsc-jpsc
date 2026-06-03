import 'package:flutter/material.dart';

class AppColors {
  // Base - Warm Ivory Claude-like Palette
  static const Color background = Color(0xFFFBF9F6);      // Warm ivory background
  static const Color surface = Color(0xFFFFFFFF);         // Clean white cards
  static const Color surfaceElevated = Color(0xFFF5F2EB); // Slightly warmer/darker ivory for inputs
  static const Color surfaceHighlight = Color(0xFFEFECE5); // Focused / hovered surface
  static const Color border = Color(0xFFE6E1D6);          // Elegant thin warm grey border
  static const Color borderLight = Color(0xFFF0EDE6);

  // Text - Charcoal & Dark Warm Brown
  static const Color textPrimary = Color(0xFF1D1816);     // Dark charcoal with a touch of warm brown
  static const Color textSecondary = Color(0xFF6B6661);   // Medium warm grey for subtitles
  static const Color textMuted = Color(0xFF9E9892);       // Muted warm grey for captions
  static const Color textDisabled = Color(0xFFC8C4BE);    // Disabled grey

  // Accent — Unified Sage Green Brand Color (replaced Gold/Terracotta)
  static const Color gold = Color(0xFF4C7F60);            // Sage Green Brand Color
  static const Color goldLight = Color(0xFF6E9F80);       // Lighter Sage Green
  static const Color goldDark = Color(0xFF385E47);        // Deep Sage Green
  static const Color goldSurface = Color(0xFFEAF2EE);     // Soft warm Sage background for highlights

  // Success — Soft Sage Green
  static const Color green = Color(0xFF4C7F60);           // Sage Green
  static const Color greenLight = Color(0xFF6E9F80);
  static const Color greenSurface = Color(0xFFEAF2EE);

  // Progress / Info — Dusty Blue
  static const Color blue = Color(0xFF4A76A8);            // Dusty Blue
  static const Color blueLight = Color(0xFF6A94C4);
  static const Color blueSurface = Color(0xFFEEF3F8);

  // Warning / Revision — Peaceful Slate Blue (completely replaced Orange/Bronze)
  static const Color orange = Color(0xFF4A76A8);          // Muted slate blue for revisions
  static const Color orangeLight = Color(0xFF6A94C4);     // Light slate blue
  static const Color orangeSurface = Color(0xFFEEF3F8);   // Soft slate blue highlight

  // Error / Not read
  static const Color red = Color(0xFFC04E4D);             // Soft clay red
  static const Color redLight = Color(0xFFDC6F6E);
  static const Color redSurface = Color(0xFFFDF1F1);

  // Status colors
  static const Color statusNotStarted = Color(0xFF9E9892);
  static const Color statusInProgress = Color(0xFF4A76A8);
  static const Color statusCompleted = Color(0xFF4C7F60);
  static const Color statusNeedsRevision = Color(0xFF4A76A8);

  // Chart colors
  static const List<Color> chartPalette = [
    Color(0xFF4C7F60),
    Color(0xFF4A76A8),
    Color(0xFF8A6B9B),
    Color(0xFF9EA355),
    Color(0xFF4A908A),
    Color(0xFFC04E4D),
    Color(0xFFD4B47D),
    Color(0xFF8E8E93),
  ];

  // Heatmap - Sage green progress indicators
  static const Color heatmap0 = Color(0xFFEBE8E0);        // Light grey-ivory for 0 reading
  static const Color heatmap1 = Color(0xFFD4E6D9);        // Very soft sage
  static const Color heatmap2 = Color(0xFFA3CBB0);        // Soft sage
  static const Color heatmap3 = Color(0xFF6E9F80);        // Sage
  static const Color heatmap4 = Color(0xFF4C7F60);        // Rich academic Sage green
}
