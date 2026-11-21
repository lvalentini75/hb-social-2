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

  /// PD4 navigation column: 240 px card inside a 20 px outer gutter.
  static const double sidebarWidth = 240.0;
  static const double pageGutter = 20.0;
  static const double headerHeight = 64.0;
  static const double mobileHeaderHeight = 56.0;
  static const double feedMaxWidth = 880.0;
  static const double feedMinWidth = 600.0;

  /// PD4 right rail: 368 px with a 16 px gap from the center column.
  static const double railWidth = 368.0;
  static const double columnGap = 16.0;

  /// Below this width the right rail disappears.
  static const double railBreakpoint = 1280.0;
}
