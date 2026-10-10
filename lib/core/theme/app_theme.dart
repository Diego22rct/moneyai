import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const Color background = Color(0xFF0E0E0E);
  static const Color surface = Color(0xFF131313);
  static const Color surfaceLow = Color(0xFF1C1B1B);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color primary = Color(0xFF4EDEA3);
  static const Color primaryContainer = Color(0xFF10B981);
  static const Color secondary = Color(0xFF4EDEA3);
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceMuted = Color(0xFFBBCABF);
  static const Color danger = Color(0xFFFFB4AB);

  static LinearGradient get neonPrimaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF4EDEA3), Color(0xFF10B981)],
  );

  static ThemeData darkTheme() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      secondary: secondary,
      surface: surface,
    );

    final TextTheme baseText = GoogleFonts.manropeTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).apply(bodyColor: onSurface, displayColor: onSurface);

    final TextTheme textTheme = baseText.copyWith(
      labelSmall: GoogleFonts.manrope(
        textStyle: baseText.labelSmall,
        color: onSurfaceMuted,
        letterSpacing: 0.3,
      ),
      labelMedium: GoogleFonts.manrope(
        textStyle: baseText.labelMedium,
        color: onSurfaceMuted,
        letterSpacing: 0.35,
      ),
      labelLarge: GoogleFonts.manrope(
        textStyle: baseText.labelLarge,
        color: onSurfaceMuted,
        letterSpacing: 0.4,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: background.withValues(alpha: 0.45),
        foregroundColor: onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surfaceHigh.withValues(alpha: 0.8),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withValues(alpha: 0.65),
        indicatorColor: primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) => GoogleFonts.inter(
            color: states.contains(WidgetState.selected)
                ? primary
                : onSurfaceMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh.withValues(alpha: 0.65),
        hintStyle: GoogleFonts.manrope(
          color: onSurfaceMuted.withValues(alpha: 0.9),
        ),
        labelStyle: GoogleFonts.manrope(color: onSurfaceMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: primary.withValues(alpha: 0.65),
            width: 2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHigh.withValues(alpha: 0.75),
        selectedColor: primaryContainer.withValues(alpha: 0.8),
        side: BorderSide.none,
        labelStyle: GoogleFonts.manrope(color: onSurface),
      ),
    );
  }
}
