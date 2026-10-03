import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// A reusable, explicit empty state: icon + title + one line of supporting
/// text. Used everywhere the app would otherwise show sample/fake content.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: colors.primaryContainer, shape: BoxShape.circle),
            child: Icon(icon, color: colors.primary, size: 30),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.textStyles.titleMedium?.withColor(LightModeColors.lightOnSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.withColor(colors.onSurfaceVariant),
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
