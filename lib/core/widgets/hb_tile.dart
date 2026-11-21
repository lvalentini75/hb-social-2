import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Borderless inset surface for content nested inside an HBCard.
class HBTile extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const HBTile({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpacing.md)});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
    child: Padding(padding: padding, child: child),
  );
}