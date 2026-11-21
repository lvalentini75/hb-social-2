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
            style: context.textStyles.headlineMedium?.withColor(LightModeColors.lightOnSurface).copyWith(fontSize: 24, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant),
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
