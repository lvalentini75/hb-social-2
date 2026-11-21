import 'package:flutter/material.dart';

class AppMotion {
  final Duration fast, base, medium, slow, count;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  const AppMotion._(this.fast, this.base, this.medium, this.slow, this.count);

  factory AppMotion.of(BuildContext context) => MediaQuery.maybeOf(context)?.disableAnimations ?? false
      ? const AppMotion._(Duration.zero, Duration.zero, Duration.zero, Duration.zero, Duration.zero)
      : const AppMotion._(Duration(milliseconds: 120), Duration(milliseconds: 180), Duration(milliseconds: 220), Duration(milliseconds: 260), Duration(milliseconds: 400));
}