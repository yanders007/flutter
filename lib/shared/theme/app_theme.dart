// ============================================================
// Anderson CVE — App Theme
// Dark terminal aesthetic: deep navy background, cyan accent,
// monospace data presentation, severity-coded colors.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Background layers
  static const bg = Color(0xFF0A0E1A);
  static const surface = Color(0xFF111827);
  static const surfaceVariant = Color(0xFF1C2333);
  static const border = Color(0xFF2A3147);

  // Accent
  static const cyan = Color(0xFF00D9F5);
  static const cyanDim = Color(0xFF0097AA);

  // Text
  static const textPrimary = Color(0xFFE8EDF5);
  static const textSecondary = Color(0xFF7B8CAA);
  static const textMono = Color(0xFF9BADC5);

  // Severity
  static const critical = Color(0xFFFF3B3B);
  static const high = Color(0xFFFF7A35);
  static const medium = Color(0xFFFFB547);
  static const low = Color(0xFF36D68A);
  static const none = Color(0xFF4A5568);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        secondary: AppColors.cyanDim,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.spaceMono(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        labelMedium: GoogleFonts.spaceMono(
          color: AppColors.textMono,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceMono(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.cyan),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: AppColors.bg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.spaceMono(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: GoogleFonts.spaceMono(
          fontSize: 10,
          color: AppColors.textMono,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

/// Returns the colour matching a severity level.
Color severityColor(SeverityLevel level) => switch (level) {
      SeverityLevel.critical => AppColors.critical,
      SeverityLevel.high => AppColors.high,
      SeverityLevel.medium => AppColors.medium,
      SeverityLevel.low => AppColors.low,
      SeverityLevel.none => AppColors.none,
    };

// Import for SeverityLevel
import 'package:anderson_cve/core/models/scan_result.dart';
