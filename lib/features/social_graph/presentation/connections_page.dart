import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/data/paged_notifier.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_paged_sliver_list.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/core/services/realtime_service.dart';
import 'package:hb_social/features/profile/providers/public_profile_providers.dart';
import 'package:hb_social/features/social_graph/domain/social_connection.dart';
import 'package:hb_social/features/social_graph/presentation/widgets/follow_button.dart';
import 'package:hb_social/features/social_graph/providers/social_graph_providers.dart';

class ConnectionsPage extends ConsumerStatefulWidget {
  final String username;
  final String initialTab;

  const ConnectionsPage({super.key, required this.username, this.initialTab = 'followers'});

  @override
  ConsumerState<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends ConsumerState<ConnectionsPage> {
  late int _tab = const {'followers': 0, 'following': 1, 'friends': 2}[widget.initialTab] ?? 0;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(publicProfileProvider(widget.username));
    return profile.when(
      loading: () => const CustomScrollView(slivers: [SliverPadding(padding: EdgeInsets.all(AppSpacing.lg), sliver: SliverToBoxAdapter(child: HBListSkeleton()))]),
      error: (_, __) => ConnectionsState(messageKey: 'connections.error', onRetry: () => ref.invalidate(publicProfileProvider(widget.username))),
      data: (user) {
        if (user == null) return const ConnectionsState(messageKey: 'profile.not_found_message');
        return CustomScrollView(slivers: [
          SliverPadding(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md), sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('connections.title'.tr(namedArgs: {'name': user.displayName}), style: context.textStyles.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            HBSegmentedTabs(labels: ['connections.followers_count'.tr(namedArgs: {'n': '${user.followerCount}'}), 'connections.following_count'.tr(namedArgs: {'n': '${user.followingCount}'}), 'connections.friends_count'.tr(namedArgs: {'n': '${user.friendCount}'})], selectedIndex: _tab, onChanged: (index) => setState(() => _tab = index)),
          ]))),
          if (_tab < 2) _connectionList(user.id, _tab == 0) else _friendsList(user.id),
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
        ]);
      },
    );
  }

  Widget _connectionList(String userId, bool followers) {
    final query = (userId: userId, followers: followers);
    final value = ref.watch(connectionsProvider(query));
    return SliverPadding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), sliver: HBPagedSliverList<SocialConnection>(
      value: value,
      loading: const HBListSkeleton(),
      empty: HBCard(child: HBEmptyState(icon: Icons.people_outline, title: (followers ? 'connections.empty_followers' : 'connections.empty_following').tr(), message: 'connections.empty_message'.tr())),
      error: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'connections.error'.tr(), message: 'connections.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(connectionsProvider(query))))),
      onRetry: () => ref.invalidate(connectionsProvider(query)),
      onLoadMore: () => ref.read(connectionsProvider(query).notifier).loadMore(),
      itemBuilder: (_, item, __) => ConnectionRow(profile: item.profile),
    ));
  }

  Widget _friendsList(String userId) {
    final value = ref.watch(friendsProvider(userId));
    return SliverPadding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), sliver: HBPagedSliverList<FriendProfile>(
      value: value,
      loading: const HBListSkeleton(),
      empty: HBCard(child: HBEmptyState(icon: Icons.group_outlined, title: 'connections.empty_friends'.tr(), message: 'connections.empty_message'.tr())),
      error: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'connections.error'.tr(), message: 'connections.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(friendsProvider(userId))))),
      onRetry: () => ref.invalidate(friendsProvider(userId)), onLoadMore: () => ref.read(friendsProvider(userId).notifier).loadMore(),
      itemBuilder: (_, item, __) => ConnectionRow(profile: item.profile, isFriend: item.mutual),
    ));
  }
}

class ConnectionRow extends ConsumerWidget {
  final SocialProfile profile;
  final bool isFriend;

  const ConnectionRow({super.key, required this.profile, this.isFriend = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownId = ref.watch(authSessionProvider).value?.user.id;
    final isOnline = ownId != null && (ref.watch(onlineUsersProvider).value?.contains(profile.id) ?? false);
    final relationship = ownId == null || ownId == profile.id ? null : ref.watch(relationshipProvider(profile.id)).value;
    final showFriend = isFriend || relationship?.isFriend == true;
    return HBCard(padding: const EdgeInsets.all(AppSpacing.md), child: InkWell(onTap: () => context.push(AppRoutes.publicProfilePath(profile.username)), child: Row(children: [
      HBAvatar(name: profile.displayName, imageUrl: profile.avatarUrl, size: 44, showPresence: isOnline), const SizedBox(width: AppSpacing.md),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Flexible(child: Text(profile.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall)), if (profile.isVerified) ...[const SizedBox(width: 4), HBBadge.verification(level: profile.verificationLevel, verifiedAt: profile.verifiedAt)]]), Text('@${profile.username}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), if (showFriend) ...[const SizedBox(height: 4), HBChip(label: 'friendship.friend'.tr(), selected: false)] ])),
      if (ownId != profile.id) FollowButton(userId: profile.id, username: profile.username, size: HBButtonSize.sm),
    ])));
  }
}

class ConnectionsState extends StatelessWidget {
  final String messageKey;
  final VoidCallback? onRetry;

  const ConnectionsState({super.key, required this.messageKey, this.onRetry});

  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.all(AppSpacing.lg), sliver: SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.people_outline, title: messageKey.tr(), message: 'connections.error_message'.tr(), action: onRetry == null ? null : HBButton.secondary(label: 'common.retry'.tr(), onPressed: onRetry)))))]);
}