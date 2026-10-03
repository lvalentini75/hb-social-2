import 'package:flutter/material.dart';

// =============================================================================
// COLORS — HB Social brand palette. Every hex value in the app lives here.
// =============================================================================

/// Light mode colors. Green is reserved for the primary action and active
/// states only; the rest of the UI stays neutral (white cards on a soft
/// off-white background), with no borders and no gradients anywhere.
class LightModeColors {
  static const lightPrimary = Color(0xFF2E7D45);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFEAF5EE);
  static const lightOnPrimaryContainer = Color(0xFF123D21);

  static const lightForest = Color(0xFF225E34);
  static const lightOnForest = Color(0xFFFFFFFF);

  static const lightSecondary = Color(0xFF66706B);
  static const lightOnSecondary = Color(0xFFFFFFFF);

  static const lightTertiary = Color(0xFFB08A3E);
  static const lightOnTertiary = Color(0xFFFFFFFF);

  static const lightError = Color(0xFFD14343);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFDAD6);
  static const lightOnErrorContainer = Color(0xFF410002);

  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF111715);
  static const lightBackground = Color(0xFFF6F7F8);
  static const lightSurfaceVariant = Color(0xFFF2F4F5);
  static const lightOnSurfaceVariant = Color(0xFF66706B);

  static const lightOutline = Color(0xFFE3E7E4);
  static const lightShadow = Color(0xFF101814);
  static const lightInversePrimary = Color(0xFFA7D4B3);

  /// Design-system tokens (see docs/DESIGN_SYSTEM.md) not covered above.
  static const lightBackgroundSoft = Color(0xFFF2F4F5);
  static const lightBackgroundHover = Color(0xFFEEF2EF);
  static const lightDivider = Color(0xFFE7EBE8);
  static const lightBorder = Color(0xFFE3E7E4);
  static const lightTextTertiary = Color(0xFF8A948F);
  static const lightPrimarySoft = Color(0xFFEAF5EE);
  static const lightPrimaryOutline = Color(0xFFA7CCB4);
  static const lightSuccess = Color(0xFF22A06B);
  static const lightWarning = Color(0xFFC98912);
  static const lightInfo = Color(0xFF2E6BDE);
  static const lightAccentBrown = Color(0xFF8A5A2B);
  static const adminSidebar = Color(0xFF151C18);
  static const adminSidebarText = Color(0xB8FFFFFF);
  static const adminSidebarMuted = Color(0x73FFFFFF);
  static const adminSidebarActive = lightPrimary;
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
