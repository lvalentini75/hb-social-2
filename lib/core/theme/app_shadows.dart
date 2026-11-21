import 'package:flutter/material.dart';

class AppShadows {
  static const List<BoxShadow> level1 = [BoxShadow(color: Color.fromRGBO(20, 28, 24, 0.04), offset: Offset(0, 1), blurRadius: 2)];

  /// PD4 cardShadow: 0 1 2 rgba(20,28,24,.04) + 0 8 24 rgba(20,28,24,.06)
  static const List<BoxShadow> card = [
    BoxShadow(color: Color.fromRGBO(20, 28, 24, 0.04), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color.fromRGBO(20, 28, 24, 0.06), offset: Offset(0, 8), blurRadius: 24),
  ];
  static const List<BoxShadow> level2 = card;
  static const List<BoxShadow> hover = [
    BoxShadow(color: Color.fromRGBO(20, 28, 24, 0.06), offset: Offset(0, 2), blurRadius: 4),
    BoxShadow(color: Color.fromRGBO(20, 28, 24, 0.10), offset: Offset(0, 14), blurRadius: 32),
  ];
  static const List<BoxShadow> level3 = hover;

  /// PD4 fabShadow: 0 8 20 rgba(31,74,58,.35)
  static const List<BoxShadow> fab = [BoxShadow(color: Color.fromRGBO(31, 74, 58, 0.35), offset: Offset(0, 8), blurRadius: 20)];
  static const List<BoxShadow> floating = fab;

  /// Upward shadow of the mobile bottom bar.
  static const List<BoxShadow> bottomBar = [BoxShadow(color: Color.fromRGBO(20, 28, 24, 0.06), offset: Offset(0, -2), blurRadius: 12)];
}
