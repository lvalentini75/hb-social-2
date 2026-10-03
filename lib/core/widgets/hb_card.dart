import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Soft, borderless surface used for every card-like block in the app
/// (feed container, rail panels, profile sections, ...). Depth comes from
/// [shadow], never from a visible border.
class HBCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<BoxShadow> shadow;
  final Color color;

  const HBCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = AppRadius.lg,
    this.shadow = AppShadows.level1,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius), boxShadow: shadow),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
