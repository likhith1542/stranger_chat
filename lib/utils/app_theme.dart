// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette — cyberpunk-noir dark
  static const bg = Color(0xFF0A0A0F);
  static const surface = Color(0xFF111118);
  static const surfaceHigh = Color(0xFF1A1A24);
  static const accent = Color(0xFF00FFB2); // neon mint
  static const accentDim = Color(0xFF00C48A);
  static const accentGlow = Color(0x3300FFB2);
  static const stranger = Color(0xFFFF5F87); // stranger pink
  static const strangerDim = Color(0xFFCC3D63);
  static const textPrimary = Color(0xFFEEEEFF);
  static const textSecondary = Color(0xFF888899);
  static const textMuted = Color(0xFF444455);
  static const divider = Color(0xFF1E1E2E);
  static const danger = Color(0xFFFF3A5A);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accent,
        secondary: stranger,
        error: danger,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.spaceMonoTextTheme().copyWith(
        displayLarge: GoogleFonts.orbitron(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.orbitron(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
        titleLarge: GoogleFonts.orbitron(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: GoogleFonts.orbitron(
          color: textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: GoogleFonts.spaceMono(color: textPrimary, fontSize: 14),
        bodyMedium: GoogleFonts.spaceMono(color: textSecondary, fontSize: 12),
        labelSmall: GoogleFonts.spaceMono(color: textMuted, fontSize: 10),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.orbitron(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
    );
  }
}
