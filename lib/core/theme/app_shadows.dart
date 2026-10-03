import 'package:flutter/material.dart';

/// Soft, borderless shadows used on every card-like surface. Never use a
/// visible border where a shadow level can express elevation instead.
class AppShadows {
  /// Cards (default elevation).
  static const List<BoxShadow> level1 = [
    BoxShadow(color: Color.fromRGBO(16, 24, 20, 0.04), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color.fromRGBO(16, 24, 20, 0.03), offset: Offset(0, 6), blurRadius: 20),
  ];

  /// Hover states, menus.
  static const List<BoxShadow> level2 = [
    BoxShadow(color: Color.fromRGBO(16, 24, 20, 0.05), offset: Offset(0, 2), blurRadius: 8),
    BoxShadow(color: Color.fromRGBO(16, 24, 20, 0.04), offset: Offset(0, 12), blurRadius: 30),
  ];

  /// Modals, docked panels.
  static const List<BoxShadow> level3 = [
    BoxShadow(color: Color.fromRGBO(16, 24, 20, 0.08), offset: Offset(0, 8), blurRadius: 30),
    BoxShadow(color: Color.fromRGBO(16, 24, 20, 0.06), offset: Offset(0, 20), blurRadius: 60),
  ];

  static const List<BoxShadow> card = level1;
}
