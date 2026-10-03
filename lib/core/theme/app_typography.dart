import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

extension TextStyleExtensions on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle withColor(Color color) => copyWith(color: color);
}

/// Builds the Material [TextTheme] (Inter via google_fonts) shared by light
/// and dark themes. Brightness is accepted for parity even though both
/// themes currently use the same type scale.
TextTheme buildTextTheme(Brightness brightness) {
  return TextTheme(
    displayLarge: GoogleFonts.inter(fontSize: FontSizes.displayLarge, fontWeight: FontWeight.w600, letterSpacing: -0.5),
    displayMedium: GoogleFonts.inter(fontSize: FontSizes.displayMedium, fontWeight: FontWeight.w600, letterSpacing: -0.5),
    displaySmall: GoogleFonts.inter(fontSize: FontSizes.displaySmall, fontWeight: FontWeight.w600),
    headlineLarge: GoogleFonts.inter(fontSize: FontSizes.headlineLarge, fontWeight: FontWeight.w600, letterSpacing: -0.5, height: 1.2),
    headlineMedium: GoogleFonts.inter(fontSize: FontSizes.headlineMedium, fontWeight: FontWeight.w600, height: 1.25),
    headlineSmall: GoogleFonts.inter(fontSize: FontSizes.headlineSmall, fontWeight: FontWeight.w600, height: 1.3),
    titleLarge: GoogleFonts.inter(fontSize: FontSizes.titleLarge, fontWeight: FontWeight.w600),
    titleMedium: GoogleFonts.inter(fontSize: FontSizes.titleMedium, fontWeight: FontWeight.w600),
    titleSmall: GoogleFonts.inter(fontSize: FontSizes.titleSmall, fontWeight: FontWeight.w500),
    labelLarge: GoogleFonts.inter(fontSize: FontSizes.labelLarge, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    labelMedium: GoogleFonts.inter(fontSize: FontSizes.labelMedium, fontWeight: FontWeight.w500, letterSpacing: 0.3),
    labelSmall: GoogleFonts.inter(fontSize: FontSizes.labelSmall, fontWeight: FontWeight.w500, letterSpacing: 0.3),
    bodyLarge: GoogleFonts.inter(fontSize: FontSizes.bodyLarge, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium: GoogleFonts.inter(fontSize: FontSizes.bodyMedium, fontWeight: FontWeight.w400, height: 1.5),
    bodySmall: GoogleFonts.inter(fontSize: FontSizes.bodySmall, fontWeight: FontWeight.w400, height: 1.4),
  );
}
