import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Mobile-only row of 4 quick shortcuts below the "Oggi a caccia" card. The
/// The hunting entries point to their dedicated shell routes.
class HuntingShortcutsRow extends StatelessWidget {
  const HuntingShortcutsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ShortcutTile(
            icon: Icons.menu_book_outlined,
            color: LightModeColors.lightPrimary,
            label: 'home.shortcut_diary'.tr(),
            onTap: () => context.go(AppRoutes.huntingDiary),
          ),
        ),
        Expanded(
          child: _ShortcutTile(
            icon: Icons.map_outlined,
            color: LightModeColors.lightInfo,
            label: 'home.shortcut_map'.tr(),
            onTap: () => context.go(AppRoutes.huntingMap),
          ),
        ),
        Expanded(
          child: _ShortcutTile(
            icon: Icons.pets_outlined,
            color: LightModeColors.lightAccentBrown,
            label: 'home.shortcut_dogs'.tr(),
            onTap: () => context.go(AppRoutes.huntingDogs),
          ),
        ),
        Expanded(
          child: _ShortcutTile(
            icon: Icons.storefront_outlined,
            color: LightModeColors.lightWarning,
            label: 'home.shortcut_market'.tr(),
            onTap: () => context.go(AppRoutes.marketplace),
          ),
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ShortcutTile({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), boxShadow: AppShadows.level1),
              alignment: Alignment.center,
              child: Icon(icon, size: 24, color: color),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: context.textStyles.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
