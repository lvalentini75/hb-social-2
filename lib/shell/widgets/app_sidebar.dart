import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/composer_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_marketing_image.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/home/providers/community_stats_provider.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/shell/shell_destinations.dart';
import 'package:hb_social/shell/widgets/sidebar_nav_tile.dart';
import 'package:hb_social/features/chat/providers/chat_providers.dart';
import 'package:hb_social/features/notifications/providers/notification_providers.dart';
import 'package:hb_social/core/providers/platform_providers.dart';

/// PD4 web navigation panel: a 240 px column holding a raised card with the
/// user row, the main destinations, the hunting tools and the create button,
/// followed by the community card.
class AppSidebar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppSidebar({super.key, required this.currentIndex, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final messageCount = ref.watch(unreadConversationsCountProvider).value ?? 0;
    final notificationCount = ref.watch(unreadNotificationCountProvider).value ?? 0;
    final flags = ref.watch(featureFlagsProvider).value ?? const <String, bool>{};
    int? badgeFor(String path) {
      if (path == AppRoutes.messages && messageCount > 0) return messageCount;
      if (path == AppRoutes.notifications && notificationCount > 0) return notificationCount;
      return null;
    }

    return SizedBox(
      width: AppBreakpoints.sidebarWidth,
      child: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: LightModeColors.surfaceRaised, borderRadius: BorderRadius.circular(AppRadius.cardWeb), boxShadow: AppShadows.card),
            child: Column(children: [
              const SidebarProfileRow(),
              const SizedBox(height: AppSpacing.sm),
              for (final destination in sidebarMainDestinations)
                SidebarNavTile(
                  icon: destination.icon,
                  label: destination.labelKey.tr(),
                  isActive: location == destination.path,
                  badgeCount: badgeFor(destination.path),
                  onTap: () => context.go(destination.path),
                ),
              if (flags['reels'] == true) SidebarNavTile(icon: Icons.video_collection_outlined, label: 'reels.title'.tr(), isActive: location == AppRoutes.reels, onTap: () => context.go(AppRoutes.reels)),
              if (flags['live'] == true) SidebarNavTile(icon: Icons.live_tv_outlined, label: 'live.title'.tr(), isActive: location == AppRoutes.live, onTap: () => context.go(AppRoutes.live)),
              const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Divider(height: 1, color: LightModeColors.divider)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, AppSpacing.md, 14, AppSpacing.sm),
                child: Align(alignment: Alignment.centerLeft, child: Text('sidebar.hunting_tools'.tr(), style: AppText.caption.withColor(LightModeColors.textSecondary))),
              ),
              for (final destination in sidebarHuntingDestinations)
                SidebarNavTile(
                  icon: destination.icon,
                  label: destination.labelKey.tr(),
                  isActive: location == destination.path,
                  onTap: () => context.go(destination.path),
                ),
              const SizedBox(height: AppSpacing.sm),
              const SidebarCreateButton(),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          const SidebarCommunityCard(),
        ],
      ),
    );
  }
}

/// Full-width Bosco pill opening the existing create menu.
class SidebarCreateButton extends StatelessWidget {
  const SidebarCreateButton({super.key});

  @override
  Widget build(BuildContext context) => Material(
    color: LightModeColors.bosco,
    borderRadius: BorderRadius.circular(AppRadius.pill),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: () => showCreateMenu(context),
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(children: [
            const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text('sidebar.create_content'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.buttonLg.withColor(Colors.white))),
            const Icon(Icons.expand_more_rounded, size: 18, color: Colors.white),
          ]),
        ),
      ),
    ),
  );
}

/// Soft 72 px row at the top of the navigation card, linking to the profile.
class SidebarProfileRow extends ConsumerWidget {
  const SidebarProfileRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authSessionProvider).value != null;
    final profile = ref.watch(currentProfileProvider).value;
    return Material(
      color: LightModeColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadius.inner),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.inner),
        onTap: () => context.go(isAuthenticated ? AppRoutes.profile : AppRoutes.login),
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(children: [
              HBAvatar(size: 44, isGuest: !isAuthenticated, name: profile?.displayName, imageUrl: profile?.avatarUrl),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(profile?.displayName ?? 'nav.guest'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.ui.copyWith(fontWeight: FontWeight.w600, color: LightModeColors.text)),
                Text(isAuthenticated ? '@${profile?.username ?? ''}' : 'sidebar.profile_cta'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.withColor(LightModeColors.textSecondary)),
              ])),
              const Icon(Icons.chevron_right_rounded, size: 18, color: LightModeColors.textSecondary),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Community card under the navigation panel: marketing image + three real
/// counters from `hb_community_stats()`. Hidden when the RPC fails.
class SidebarCommunityCard extends ConsumerWidget {
  const SidebarCommunityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(communityStatsProvider).value;
    if (stats == null || stats.isEmpty) return const SizedBox.shrink();
    final compact = NumberFormat.compact(locale: context.locale.toString());
    return Container(
      decoration: BoxDecoration(color: LightModeColors.surface, borderRadius: BorderRadius.circular(AppRadius.cardWeb), boxShadow: AppShadows.card),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        HBMarketingImage(
          asset: 'assets/images/community.jpg', height: 96, radius: 0,
          overlayChild: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Align(alignment: Alignment.bottomLeft, child: Text('home.community_card_title'.tr(), maxLines: 2, overflow: TextOverflow.ellipsis, style: appFont(16, FontWeight.w700, height: 1.2, color: Colors.white))),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            CommunityStatCell(value: compact.format(stats.hunters), label: 'home.community_hunters'.tr()),
            CommunityStatCell(value: compact.format(stats.groups), label: 'home.community_groups'.tr()),
            CommunityStatCell(value: compact.format(stats.listings), label: 'home.community_listings'.tr()),
          ]),
        ),
      ]),
    );
  }
}

class CommunityStatCell extends StatelessWidget {
  final String value;
  final String label;

  const CommunityStatCell({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(value, style: AppText.kpi.withColor(LightModeColors.text)),
    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.withColor(LightModeColors.textSecondary)),
  ]);
}
