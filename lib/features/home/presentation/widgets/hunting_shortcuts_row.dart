import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Mobile-only row of 4 quick shortcuts below the "Oggi a caccia" card:
/// 72×72 soft tiles with a Bosco icon and a 14/600 label.
class HuntingShortcutsRow extends StatelessWidget {
  const HuntingShortcutsRow({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      HuntingShortcutTile(icon: Icons.menu_book_outlined, label: 'home.shortcut_diary'.tr(), onTap: () => context.go(AppRoutes.huntingDiary)),
      HuntingShortcutTile(icon: Icons.map_outlined, label: 'home.shortcut_map'.tr(), onTap: () => context.go(AppRoutes.huntingMap)),
      HuntingShortcutTile(icon: Icons.pets_outlined, label: 'home.shortcut_dogs'.tr(), onTap: () => context.go(AppRoutes.huntingDogs)),
      HuntingShortcutTile(icon: Icons.storefront_outlined, label: 'home.shortcut_market'.tr(), onTap: () => context.go(AppRoutes.marketplace)),
    ],
  );
}

class HuntingShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const HuntingShortcutTile({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 78,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Material(
        color: LightModeColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.cardWeb),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.cardWeb),
          onTap: onTap,
          child: SizedBox(width: 72, height: 72, child: Icon(icon, size: 28, color: LightModeColors.bosco)),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: appFont(14, FontWeight.w600, color: LightModeColors.text)),
    ]),
  );
}
