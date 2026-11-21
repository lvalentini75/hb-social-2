import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontSizes {
  static const double displayLarge = 34, displayMedium = 28, displaySmall = 32;
  static const double headlineLarge = 28, headlineMedium = 22, headlineSmall = 17;
  static const double titleLarge = 20, titleMedium = 17, titleSmall = 17;
  static const double labelLarge = 14, labelMedium = 13, labelSmall = 12;
  static const double bodyLarge = 15, bodyMedium = 14, bodySmall = 12;
}

/// Single typeface of the app (PD4): Inter, weights 400/500/600/700/800.
/// Hierarchy comes from weight and spacing, never from a second family.
TextStyle appFont(double size, FontWeight weight, {double spacing = 0, double height = 1.3, bool tabular = false, Color? color}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, letterSpacing: spacing, height: height, color: color, fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null);

/// PD4 named roles. Use these instead of inventing ad-hoc sizes.
class AppText {
  static TextStyle get hero => appFont(40, FontWeight.w700, spacing: -1, height: 1.08);
  static TextStyle get display => appFont(34, FontWeight.w800, spacing: -0.8, height: 1.08);
  static TextStyle get heading => appFont(28, FontWeight.w700, spacing: -0.5, height: 1.12);
  static TextStyle get title => appFont(20, FontWeight.w700, spacing: -0.3, height: 1.2);
  static TextStyle get cardTitle => appFont(17, FontWeight.w600, spacing: -0.2, height: 1.25);
  static TextStyle get body => appFont(15, FontWeight.w400, height: 1.5);
  static TextStyle get ui => appFont(15, FontWeight.w500, height: 1.3);
  static TextStyle get label => appFont(14, FontWeight.w500, height: 1.35);
  static TextStyle get caption => appFont(13, FontWeight.w500, height: 1.3);
  static TextStyle get small => appFont(12, FontWeight.w500, height: 1.3);
  static TextStyle get price => appFont(20, FontWeight.w700, height: 1.2, tabular: true);
  static TextStyle get kpi => appFont(22, FontWeight.w700, height: 1.2, tabular: true);
  static TextStyle get buttonLg => appFont(15, FontWeight.w600, height: 1.2);
  static TextStyle get buttonSm => appFont(14, FontWeight.w600, height: 1.2);
}

extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
  TextStyle get displayStyle => AppText.display;
  TextStyle get displayNumberStyle => appFont(32, FontWeight.w700, spacing: -0.6, height: 1.1, tabular: true);
}

extension TextStyleExtensions on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle withColor(Color color) => copyWith(color: color);
}

TextTheme buildTextTheme(Brightness brightness) {
  final ui = GoogleFonts.interTextTheme();
  return ui.copyWith(
    displayLarge: AppText.display, displayMedium: AppText.heading, displaySmall: appFont(32, FontWeight.w700, spacing: -0.6, height: 1.1, tabular: true),
    headlineLarge: AppText.heading, headlineMedium: appFont(22, FontWeight.w700, spacing: -0.4, height: 1.15), headlineSmall: AppText.cardTitle,
    titleLarge: AppText.title, titleMedium: AppText.cardTitle, titleSmall: AppText.cardTitle,
    labelLarge: appFont(14, FontWeight.w600, height: 1.3), labelMedium: AppText.caption, labelSmall: AppText.small,
    bodyLarge: AppText.body, bodyMedium: AppText.label, bodySmall: AppText.small,
  );
}
