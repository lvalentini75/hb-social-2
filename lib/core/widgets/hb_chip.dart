import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Pill-shaped filter/selection chip. Selected = solid primaryDeep background
/// with white text; unselected = soft neutral background.
class HBChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  const HBChip({super.key, required this.label, required this.selected, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    final background = selected ? LightModeColors.lightForest : LightModeColors.lightBackgroundSoft;
    final foreground = selected ? Colors.white : LightModeColors.lightOnSurface;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 16, color: foreground), const SizedBox(width: AppSpacing.xs)],
              Text(label, style: context.textStyles.labelLarge?.withColor(foreground)),
            ],
          ),
        ),
      ),
    );
  }
}
