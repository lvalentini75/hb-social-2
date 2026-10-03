import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Explicit empty state: icon + title + one line of supporting text,
/// optionally with a single action. Used everywhere a list or section has
/// no real data yet instead of any fake/sample content.
class HBEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const HBEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: LightModeColors.lightPrimarySoft, shape: BoxShape.circle),
            child: Icon(icon, color: LightModeColors.lightForest, size: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.textStyles.titleMedium?.withColor(LightModeColors.lightOnSurface).copyWith(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
