import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/shell/shell_destinations.dart';
import 'package:hb_social/shell/widgets/sidebar_nav_tile.dart';

/// Fixed 260px left sidebar shown on wide (web) layouts: a compact guest
/// profile card, then three nav sections (main, "A caccia", "I miei")
/// separated by dividers. There is no destinations param anymore — each
/// section pulls its own const list from shell_destinations.dart.
class AppSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppSidebar({super.key, required this.currentIndex, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return SizedBox(
      width: AppBreakpoints.sidebarWidth,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
        children: [
          const _SidebarProfileCard(),
          const SizedBox(height: AppSpacing.lg),
          for (final destination in sidebarMainDestinations)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: SidebarNavTile(
                icon: destination.icon,
                label: destination.labelKey.tr(),
                 isActive: location == destination.path,
                 onTap: () => context.go(destination.path),
              ),
            ),
          const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Divider(height: 1)),
          _SidebarSectionLabel(label: 'nav.hunting'.tr().toUpperCase(), isActive: location == AppRoutes.hunting || location.startsWith('${AppRoutes.hunting}/')),
          for (final destination in sidebarHuntingDestinations)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: SidebarNavTile(
                icon: destination.icon,
                label: destination.labelKey.tr(),
                isActive: location == destination.path,
                onTap: () => context.go(destination.path),
              ),
            ),
          const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Divider(height: 1)),
          _SidebarSectionLabel(label: 'sidebar.section_mine'.tr().toUpperCase()),
          for (final destination in sidebarMineDestinations)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: SidebarNavTile(
                icon: destination.icon,
                label: destination.labelKey.tr(),
                isActive: destination.branchIndex == currentIndex,
                onTap: () => onDestinationSelected(destination.branchIndex),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact guest card at the top of the sidebar, linking to /login until
/// there is a real session.
class _SidebarProfileCard extends StatelessWidget {
  const _SidebarProfileCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LightModeColors.lightBackgroundSoft,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.go(AppRoutes.login),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              const HBAvatar(avatarSize: HBAvatarSize.md, isGuest: true),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('nav.guest'.tr(), style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      'sidebar.profile_cta'.tr(),
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: LightModeColors.lightOnSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uppercase 11/700 textTertiary section label used above the "A caccia"
/// and "I miei" sidebar groups.
class _SidebarSectionLabel extends StatelessWidget {
  final String label;
  final bool isActive;

  const _SidebarSectionLabel({required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.xs),
      child: Text(
        label,
        style: context.textStyles.labelSmall?.withColor(isActive ? LightModeColors.lightPrimary : LightModeColors.lightTextTertiary).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
      ),
    );
  }
}
