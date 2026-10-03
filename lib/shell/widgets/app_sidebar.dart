import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon.dart';
import 'package:hb_social/shell/widgets/sidebar_nav_tile.dart';

/// Fixed 260px left sidebar shown on wide (web) layouts.
class AppSidebar extends StatelessWidget {
  final String currentPath;

  const AppSidebar({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: AppBreakpoints.sidebarWidth,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: ListView(
        children: [
          SidebarNavTile(
            icon: Icons.home_rounded,
            label: 'home.nav_home'.tr(),
            isActive: currentPath == AppRoutes.home,
            onTap: () => context.go(AppRoutes.home),
          ),
          SidebarNavTile(icon: Icons.groups_2_outlined, label: 'home.nav_groups'.tr(), isActive: false, onTap: () => showComingSoon(context)),
          SidebarNavTile(icon: Icons.forum_outlined, label: 'home.nav_forum'.tr(), isActive: false, onTap: () => showComingSoon(context)),
          SidebarNavTile(icon: Icons.article_outlined, label: 'home.nav_pages'.tr(), isActive: false, onTap: () => showComingSoon(context)),
          SidebarNavTile(icon: Icons.storefront_outlined, label: 'home.nav_marketplace'.tr(), isActive: false, onTap: () => showComingSoon(context)),
          SidebarNavTile(icon: Icons.event_outlined, label: 'home.nav_events'.tr(), isActive: false, onTap: () => showComingSoon(context)),
          SidebarNavTile(icon: Icons.chat_bubble_outline_rounded, label: 'home.nav_messages'.tr(), isActive: false, onTap: () => showComingSoon(context)),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              'home.section_hunting'.tr(),
              style: context.textStyles.labelMedium?.withColor(colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SidebarNavTile(icon: Icons.menu_book_outlined, label: 'home.nav_diary'.tr(), isActive: false, onTap: () => showComingSoon(context)),
          SidebarNavTile(icon: Icons.map_outlined, label: 'home.nav_map'.tr(), isActive: false, onTap: () => showComingSoon(context)),
          SidebarNavTile(icon: Icons.calendar_month_outlined, label: 'home.nav_calendar'.tr(), isActive: false, onTap: () => showComingSoon(context)),
        ],
      ),
    );
  }
}
