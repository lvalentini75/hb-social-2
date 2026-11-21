import 'package:flutter/material.dart';

/// HB Social PD4 palette. Every literal color used by the app lives here.
///
/// Naming keeps the historical `lightX` identifiers (used across the app) and
/// adds the PD4 reference names (bosco, surfaceSoft, pageWeb, ...) as the
/// canonical tokens. Both point at the same values.
class LightModeColors {
  // --- PD4 reference tokens -------------------------------------------------
  static const bosco = Color(0xFF1F4A3A);
  static const boscoDeep = Color(0xFF17392C);
  static const boscoSoft = Color(0xFFDCE7E0);
  static const boscoTint = Color(0xFFE8F0EB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceRaised = Color(0xFFF8F9FB);
  static const surfaceSoft = Color(0xFFEEF2EF);
  static const pageWeb = Color(0xFFEAEEF3);
  static const pageMobile = Color(0xFFF8F9F8);
  static const divider = Color(0xFFE6EAE7);
  static const border = Color(0xFFE1E6E2);
  static const text = Color(0xFF141C18);
  static const textSecondary = Color(0xFF67736D);
  static const textTertiary = Color(0xFF9AA49E);
  static const danger = Color(0xFFE04B3E);
  static const dateUrgentBg = Color(0xFFFBE6E6);
  static const dateUrgentText = Color(0xFFD2403A);
  static const link = Color(0xFF5A78AD);
  static const success = Color(0xFF22A06B);
  static const accentGreen = Color(0xFF34A36A);
  static const accentBlue = Color(0xFF3B7DE0);
  static const accentOrange = Color(0xFFEE9A2D);
  static const accentPurple = Color(0xFF8B5CF6);
  static const overlay = Color(0x59141C18);
  static const overlayStrong = Color(0x99141C18);
  static const storyRingSeen = Color(0xFFC9D1CC);
  static const brandApple = Color(0xFF000000);
  static const brandGoogle = Color(0xFF4285F4);
  static const brandFacebook = Color(0xFF1877F2);
  static const brandMicrosoft = Color(0xFF737373);

  // --- Historical aliases ---------------------------------------------------
  static const lightPrimary = bosco;
  static const lightPrimaryHover = boscoDeep;
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = boscoSoft;
  static const lightOnPrimaryContainer = boscoDeep;
  static const lightForest = boscoDeep;
  static const lightOnForest = Color(0xFFFFFFFF);
  static const lightSecondary = textSecondary;
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightTertiary = accentOrange;
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightAccentBrass = Color(0xFFB08D57);
  static const lightError = danger;
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = dateUrgentBg;
  static const lightOnErrorContainer = dateUrgentText;
  static const lightSurface = surface;
  static const lightOnSurface = text;
  static const lightBackground = pageMobile;
  static const lightSurfaceVariant = surfaceSoft;
  static const lightOnSurfaceVariant = textSecondary;
  static const lightOutline = border;
  static const lightShadow = text;
  static const lightInversePrimary = boscoSoft;
  static const lightBackgroundSoft = surfaceSoft;
  static const lightBackgroundHover = boscoTint;
  static const lightDivider = divider;
  static const lightBorder = border;
  static const lightTextTertiary = textTertiary;
  static const lightPrimarySoft = boscoSoft;
  static const lightPrimaryOutline = Color(0xFFA9C4B2);
  static const lightSuccess = success;
  static const lightWarning = accentOrange;
  static const lightInfo = accentBlue;
  static const lightNeutralStatus = textTertiary;
  static const lightAccentBrown = Color(0xFF80613F);
  /// PD4b dark console/ads sidebar (mockup 3).
  static const night = Color(0xFF112623);
  static const adminSidebar = night;
  static const adminSidebarText = Color(0xFFB9C6BD);
  static const adminSidebarMuted = Color(0xFF849088);
  static const adminSidebarActive = Color(0x1AFFFFFF);
  static const scrim = Color(0x52000000);
  static const scrimSoft = Color(0x33000000);

  static const messageSenderPalette = [bosco, accentBlue, lightAccentBrown, accentOrange, Color(0xFF71528D), Color(0xFF985169)];
  static Color messageSenderColor(String userId) => messageSenderPalette[userId.codeUnits.fold<int>(0, (sum, value) => sum + value) % messageSenderPalette.length];
}

class DarkModeColors {
  static const darkPrimary = Color(0xFF8DBD9E);
  static const darkOnPrimary = Color(0xFF0F2219);
  static const darkPrimaryContainer = Color(0xFF17392C);
  static const darkOnPrimaryContainer = Color(0xFFDCE7E0);
  static const darkSecondary = Color(0xFFB9C6BD);
  static const darkOnSecondary = Color(0xFF141C18);
  static const darkTertiary = Color(0xFFD3B680);
  static const darkOnTertiary = Color(0xFF332714);
  static const darkError = Color(0xFFFFB4AC);
  static const darkOnError = Color(0xFF690005);
  static const darkErrorContainer = Color(0xFF93000A);
  static const darkOnErrorContainer = Color(0xFFFFDAD6);
  static const darkSurface = Color(0xFF0F2219);
  static const darkOnSurface = Color(0xFFF2F4F1);
  static const darkSurfaceVariant = Color(0xFF173027);
  static const darkOnSurfaceVariant = Color(0xFFB9C6BD);
  static const darkOutline = Color(0xFF415248);
  static const darkShadow = Color(0xFF000000);
  static const darkInversePrimary = Color(0xFF1F4A3A);
}
