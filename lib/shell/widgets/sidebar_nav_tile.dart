import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// A single row in the web sidebar, used for both the main destinations and
/// the "A caccia" section.
class SidebarNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const SidebarNavTile({super.key, required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: isActive ? colors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 22, color: isActive ? colors.primary : LightModeColors.lightOnSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodyMedium?.withColor(isActive ? colors.primary : LightModeColors.lightOnSurface).copyWith(
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
