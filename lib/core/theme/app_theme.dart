import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Design tokens — single source of truth for the entire app.
// Philosophy: warm neutrals, generous whitespace, zero gamification stress.
abstract final class FlickColors {
  // Backgrounds
  static const background = Color(0xFFFDF6FF); // soft lavender-cream
  static const surface    = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF3EEFF);

  // Brand
  static const primary    = Color(0xFF7B61FF); // vibrant violet
  static const primaryDim = Color(0xFFEDE8FF);

  // Semantic
  static const success    = Color(0xFF00C48C); // vibrant teal-green
  static const successDim = Color(0xFFD6F7EE);
  static const error      = Color(0xFFFF5252); // bright coral-red
  static const errorDim   = Color(0xFFFFEBEB);
  static const warning    = Color(0xFFFFAB00); // vivid amber

  // Text
  static const textPrimary   = Color(0xFF1A1040); // deep violet-navy
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted     = Color(0xFFB0A8C8);

  // Borders
  static const border        = Color(0xFFE8DEFF); // lavender-tinted border
  static const borderFocused = Color(0xFF7B61FF);
}

abstract final class FlickSpacing {
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}

abstract final class FlickRadius {
  static const sm  = Radius.circular(8);
  static const md  = Radius.circular(14);
  static const lg  = Radius.circular(20);
  static const xl  = Radius.circular(28);
  static const full = Radius.circular(999);
}

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: FlickColors.background,
    colorScheme: const ColorScheme.light(
      primary:        FlickColors.primary,
      surface:        FlickColors.surface,
      onPrimary:      Colors.white,
      onSurface:      FlickColors.textPrimary,
      error:          FlickColors.error,
      outline:        FlickColors.border,
    ),
    textTheme: GoogleFonts.quicksandTextTheme(base.textTheme).copyWith(
      // Display — lesson prompts, hero headings (Comfortaa for brand feel)
      displaySmall: GoogleFonts.comfortaa(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: FlickColors.textPrimary,
        height: 1.25,
      ),
      // Headline — card titles
      headlineMedium: GoogleFonts.comfortaa(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: FlickColors.textPrimary,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.comfortaa(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: FlickColors.textPrimary,
      ),
      // Body
      bodyLarge: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: FlickColors.textPrimary,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: FlickColors.textSecondary,
        height: 1.5,
      ),
      // Labels
      labelLarge: GoogleFonts.quicksand(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: FlickColors.textPrimary,
        letterSpacing: 0.1,
      ),
      labelSmall: GoogleFonts.quicksand(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: FlickColors.textMuted,
        letterSpacing: 0.8,
      ),
    ),
    cardTheme: CardThemeData(
      color: FlickColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(FlickRadius.lg),
        side: const BorderSide(color: FlickColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FlickColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: FlickSpacing.xl,
          vertical: FlickSpacing.md + 2,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(FlickRadius.full),
        ),
        textStyle: GoogleFonts.quicksand(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: FlickColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.comfortaa(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: FlickColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: FlickColors.textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FlickColors.surfaceDim,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(FlickRadius.lg),
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(FlickRadius.lg),
        borderSide: BorderSide(color: FlickColors.borderFocused, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: FlickSpacing.md,
        vertical: FlickSpacing.md,
      ),
      hintStyle: GoogleFonts.quicksand(
        color: FlickColors.textMuted,
        fontSize: 15,
      ),
    ),
  );
}
