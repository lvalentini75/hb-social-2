/// Spacing constants used throughout the app for consistent rhythm.
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Responsive layout breakpoints and fixed column widths used by the shell.
class AppBreakpoints {
  static const double mobile = 900.0;
  static const double sidebarWidth = 260.0;
  static const double headerHeight = 64.0;
  static const double feedMaxWidth = 880.0;
  static const double railWidth = 340.0;

  /// Below this width a page's right-hand [PageColumns] rail is dropped
  /// entirely (never stacked below the center column).
  static const double railBreakpoint = 1200.0;
}
