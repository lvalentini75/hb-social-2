import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/features/social_graph/providers/social_graph_providers.dart';
import 'package:hb_social/features/chat/providers/chat_providers.dart';
import 'package:hb_social/features/dogs/providers/dog_providers.dart';
import 'package:hb_social/core/providers/platform_providers.dart';

/// Bottom sheet opened by the mobile bottom bar's "Altro" slot: the shell
/// destinations that don't fit in the 5-slot bar, including Settings.
Future<void> showMobileMoreSheet(BuildContext context, {required int currentIndex, required ValueChanged<int> onDestinationSelected}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(child: _MoreSheetContent(currentIndex: currentIndex, onDestinationSelected: onDestinationSelected)),
    ),
  );
}

class _MoreDestination {
  final IconData icon;
  final String labelKey;
  final String path;

  const _MoreDestination({required this.icon, required this.labelKey, required this.path});
}

final List<_MoreDestination> _moreDestinations = [
  const _MoreDestination(icon: Icons.forum_outlined, labelKey: 'nav.forum', path: AppRoutes.forum),
  const _MoreDestination(icon: Icons.article_outlined, labelKey: 'nav.pages_nav', path: AppRoutes.pages),
  _MoreDestination(icon: Icons.event_outlined, labelKey: 'nav.events', path: AppRoutes.events),
  const _MoreDestination(icon: Icons.terrain_outlined, labelKey: 'nav.hunting', path: AppRoutes.hunting),
  const _MoreDestination(icon: Icons.menu_book_outlined, labelKey: 'sidebar.hunting_diary', path: AppRoutes.diary),
  const _MoreDestination(icon: Icons.map_outlined, labelKey: 'sidebar.hunting_map', path: AppRoutes.map),
  const _MoreDestination(icon: Icons.visibility_outlined, labelKey: 'sightings.nav', path: AppRoutes.sightings),
  const _MoreDestination(icon: Icons.pets_outlined, labelKey: 'sidebar.hunting_dogs', path: AppRoutes.huntingDogs),
  const _MoreDestination(icon: Icons.search_rounded, labelKey: 'dogs.search.action', path: AppRoutes.dogsSearch),
  const _MoreDestination(icon: Icons.calendar_month_outlined, labelKey: 'sidebar.hunting_calendar', path: AppRoutes.huntingCalendar),
  const _MoreDestination(icon: Icons.chat_bubble_outline_rounded, labelKey: 'nav.messages', path: AppRoutes.messages),
  const _MoreDestination(icon: Icons.notifications_none_rounded, labelKey: 'nav.notifications', path: AppRoutes.notifications),
  const _MoreDestination(icon: Icons.person_outline_rounded, labelKey: 'nav.profile', path: AppRoutes.profile),
  const _MoreDestination(icon: Icons.settings_outlined, labelKey: 'settings.title', path: AppRoutes.settings),
];

class _MoreSheetContent extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const _MoreSheetContent({required this.currentIndex, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestCount = ref.watch(pendingFriendRequestCountProvider).value ?? 0;
    final messageCount = ref.watch(unreadConversationsCountProvider).value ?? 0;
    final dogReminderCount = ref.watch(urgentDogReminderCountProvider).value ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final destination in _moreDestinations)
            _MoreSheetTile(
              icon: destination.icon,
              label: destination.labelKey.tr(),
              isActive: AppRoutes.branchIndexOf(destination.path) == currentIndex,
              trailing: destination.path == AppRoutes.messages && messageCount > 0 ? HBBadge.count(count: messageCount) : destination.path == AppRoutes.huntingDogs && dogReminderCount > 0 ? HBBadge.count(count: dogReminderCount) : null,
              onTap: () {
                 final router = GoRouter.of(context);
                 context.pop();
                   if (destination.path == AppRoutes.settings || destination.path == AppRoutes.diary || destination.path == AppRoutes.map || destination.path == AppRoutes.sightings || destination.path == AppRoutes.huntingDogs || destination.path == AppRoutes.dogsSearch || destination.path == AppRoutes.huntingCalendar) {
                   router.go(destination.path);
                 } else {
                   onDestinationSelected(AppRoutes.branchIndexOf(destination.path)!);
                 }
              },
            ),
          if (ref.watch(featureFlagsProvider).value?['reels'] == true) _MoreSheetTile(icon: Icons.video_collection_outlined, label: 'reels.title'.tr(), isActive: false, onTap: () { final router = GoRouter.of(context); context.pop(); router.go(AppRoutes.reels); }),
          if (ref.watch(featureFlagsProvider).value?['live'] == true) _MoreSheetTile(icon: Icons.live_tv_outlined, label: 'live.title'.tr(), isActive: false, onTap: () { final router = GoRouter.of(context); context.pop(); router.go(AppRoutes.live); }),
          _MoreSheetTile(icon: Icons.person_add_alt_rounded, label: 'friendship.requests_title'.tr(), isActive: false, trailing: requestCount > 0 ? HBBadge.count(count: requestCount) : null, onTap: () { final router = GoRouter.of(context); context.pop(); router.go(AppRoutes.friendRequests); }),
          if (ref.watch(authSessionProvider).value != null)
            _MoreSheetTile(icon: Icons.logout_rounded, label: 'auth.logout'.tr(), isActive: false, onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go(AppRoutes.welcome);
            }),
        ],
      ),
    );
  }
}

class _MoreSheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MoreSheetTile({required this.icon, required this.label, required this.isActive, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? LightModeColors.lightForest : LightModeColors.lightOnSurface;
    return Material(
      color: isActive ? LightModeColors.lightPrimarySoft : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: isActive ? LightModeColors.lightForest : LightModeColors.lightOnSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: context.textStyles.bodyMedium?.withColor(color).copyWith(fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
