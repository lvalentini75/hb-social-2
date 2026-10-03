import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon.dart';

/// 5-slot bottom navigation bar for mobile layouts, with a raised green
/// create button in the center.
class AppBottomNav extends StatelessWidget {
  final String currentPath;

  const AppBottomNav({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _NavTile(
                  icon: Icons.home_rounded,
                  label: 'home.mobile_nav_home'.tr(),
                  isActive: currentPath == AppRoutes.home,
                  onTap: () => context.go(AppRoutes.home),
                ),
              ),
              Expanded(
                child: _NavTile(
                  icon: Icons.groups_2_outlined,
                  label: 'home.mobile_nav_groups'.tr(),
                  isActive: false,
                  onTap: () => showComingSoon(context),
                ),
              ),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => showComingSoon(context),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle, boxShadow: AppShadows.card),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _NavTile(
                  icon: Icons.storefront_outlined,
                  label: 'home.mobile_nav_market'.tr(),
                  isActive: false,
                  onTap: () => showComingSoon(context),
                ),
              ),
              Expanded(
                child: _NavTile(
                  icon: Icons.menu_rounded,
                  label: 'home.mobile_nav_more'.tr(),
                  isActive: currentPath == AppRoutes.profile,
                  onTap: () => context.go(AppRoutes.profile),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isActive ? colors.primary : LightModeColors.lightOnSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(label, style: context.textStyles.labelSmall?.withColor(color), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
