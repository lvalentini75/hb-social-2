import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Spacing constants used throughout the app for consistent rhythm.
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius constants. Cards always use a soft, generous radius.
class AppRadius {
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double card = 20.0;
  static const double lg = 22.0;
  static const double pill = 999.0;
}

/// Responsive layout breakpoints and fixed column widths used by the shell.
class AppBreakpoints {
  static const double mobile = 900.0;
  static const double sidebarWidth = 260.0;
  static const double headerHeight = 64.0;
  static const double feedMaxWidth = 880.0;
  static const double railWidth = 340.0;
}

/// Soft, borderless shadows used on every card-like surface.
class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color.fromRGBO(16, 24, 20, 0.04), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color.fromRGBO(16, 24, 20, 0.03), offset: Offset(0, 6), blurRadius: 20),
  ];
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

// =============================================================================
// COLORS — HB Social brand palette
// =============================================================================

/// Light mode colors. Green is reserved for the primary action and active
/// states only; the rest of the UI stays neutral (white cards on a soft
/// off-white background), with no borders and no gradients anywhere.
class LightModeColors {
  static const lightPrimary = Color(0xFF2E7D45);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFDCECE0);
  static const lightOnPrimaryContainer = Color(0xFF123D21);

  static const lightForest = Color(0xFF225E34);
  static const lightOnForest = Color(0xFFFFFFFF);

  static const lightSecondary = Color(0xFF66706B);
  static const lightOnSecondary = Color(0xFFFFFFFF);

  static const lightTertiary = Color(0xFFB08A3E);
  static const lightOnTertiary = Color(0xFFFFFFFF);

  static const lightError = Color(0xFFBA1A1A);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFDAD6);
  static const lightOnErrorContainer = Color(0xFF410002);

  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF111715);
  static const lightBackground = Color(0xFFF6F7F8);
  static const lightSurfaceVariant = Color(0xFFF0F2F1);
  static const lightOnSurfaceVariant = Color(0xFF66706B);

  static const lightOutline = Color(0xFFE2E5E3);
  static const lightShadow = Color(0xFF101814);
  static const lightInversePrimary = Color(0xFFA7D4B3);
}

/// Dark mode colors keep the same green accent on a deep, neutral charcoal.
class DarkModeColors {
  static const darkPrimary = Color(0xFF4FA568);
  static const darkOnPrimary = Color(0xFF0B2A14);
  static const darkPrimaryContainer = Color(0xFF1C4A2C);
  static const darkOnPrimaryContainer = Color(0xFFDCECE0);

  static const darkSecondary = Color(0xFFA9B2AC);
  static const darkOnSecondary = Color(0xFF1A1F1C);

  static const darkTertiary = Color(0xFFD1B06E);
  static const darkOnTertiary = Color(0xFF2E2407);

  static const darkError = Color(0xFFFFB4AB);
  static const darkOnError = Color(0xFF690005);
  static const darkErrorContainer = Color(0xFF93000A);
  static const darkOnErrorContainer = Color(0xFFFFDAD6);

  static const darkSurface = Color(0xFF14181A);
  static const darkOnSurface = Color(0xFFE4E7E4);
  static const darkSurfaceVariant = Color(0xFF1D2224);
  static const darkOnSurfaceVariant = Color(0xFFA9B2AC);

  static const darkOutline = Color(0xFF2A3030);
  static const darkShadow = Color(0xFF000000);
  static const darkInversePrimary = Color(0xFF2E7D45);
}

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

// =============================================================================
// THEMES
// =============================================================================

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: LightModeColors.lightPrimary,
    onPrimary: LightModeColors.lightOnPrimary,
    primaryContainer: LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
    secondary: LightModeColors.lightSecondary,
    onSecondary: LightModeColors.lightOnSecondary,
    tertiary: LightModeColors.lightTertiary,
    onTertiary: LightModeColors.lightOnTertiary,
    error: LightModeColors.lightError,
    onError: LightModeColors.lightOnError,
    errorContainer: LightModeColors.lightErrorContainer,
    onErrorContainer: LightModeColors.lightOnErrorContainer,
    surface: LightModeColors.lightSurface,
    onSurface: LightModeColors.lightOnSurface,
    surfaceContainerHighest: LightModeColors.lightSurfaceVariant,
    onSurfaceVariant: LightModeColors.lightOnSurfaceVariant,
    outline: LightModeColors.lightOutline,
    shadow: LightModeColors.lightShadow,
    inversePrimary: LightModeColors.lightInversePrimary,
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: LightModeColors.lightBackground,
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: LightModeColors.lightOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: CardThemeData(
    color: LightModeColors.lightSurface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
  ),
  dividerTheme: const DividerThemeData(color: LightModeColors.lightOutline, thickness: 1, space: 1),
  textTheme: _buildTextTheme(Brightness.light),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: DarkModeColors.darkPrimary,
    onPrimary: DarkModeColors.darkOnPrimary,
    primaryContainer: DarkModeColors.darkPrimaryContainer,
    onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
    secondary: DarkModeColors.darkSecondary,
    onSecondary: DarkModeColors.darkOnSecondary,
    tertiary: DarkModeColors.darkTertiary,
    onTertiary: DarkModeColors.darkOnTertiary,
    error: DarkModeColors.darkError,
    onError: DarkModeColors.darkOnError,
    errorContainer: DarkModeColors.darkErrorContainer,
    onErrorContainer: DarkModeColors.darkOnErrorContainer,
    surface: DarkModeColors.darkSurface,
    onSurface: DarkModeColors.darkOnSurface,
    surfaceContainerHighest: DarkModeColors.darkSurfaceVariant,
    onSurfaceVariant: DarkModeColors.darkOnSurfaceVariant,
    outline: DarkModeColors.darkOutline,
    shadow: DarkModeColors.darkShadow,
    inversePrimary: DarkModeColors.darkInversePrimary,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: DarkModeColors.darkSurface,
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: DarkModeColors.darkOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: CardThemeData(
    color: DarkModeColors.darkSurfaceVariant,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
  ),
  dividerTheme: const DividerThemeData(color: DarkModeColors.darkOutline, thickness: 1, space: 1),
  textTheme: _buildTextTheme(Brightness.dark),
);

TextTheme _buildTextTheme(Brightness brightness) {
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
