import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/core/widgets/presence_label.dart';
import 'package:hb_social/core/services/realtime_service.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart' as profile_providers;
import 'package:hb_social/features/profile/providers/public_profile_providers.dart';
import 'package:hb_social/features/marketplace/presentation/marketplace_page.dart';
import 'package:hb_social/features/marketplace/providers/marketplace_providers.dart';
import 'package:hb_social/features/social_graph/presentation/widgets/follow_button.dart';
import 'package:hb_social/features/social_graph/presentation/widgets/friend_action_button.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/features/home/presentation/widgets/feed_post_card.dart';
import 'package:hb_social/features/home/providers/feed_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/stories/domain/story.dart';
import 'package:hb_social/features/stories/presentation/highlight_editor.dart';
import 'package:hb_social/features/stories/presentation/story_viewer.dart';
import 'package:hb_social/features/stories/providers/story_providers.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/safety/presentation/report_sheet.dart';
import 'package:hb_social/features/safety/presentation/safety_confirmations.dart';
import 'package:hb_social/features/safety/providers/safety_providers.dart';
import 'package:hb_social/features/social_graph/providers/social_graph_providers.dart';
import 'package:hb_social/features/chat/providers/chat_providers.dart';
import 'package:hb_social/features/albums/presentation/profile_albums.dart';
import 'package:hb_social/features/diary/presentation/outing_card.dart';
import 'package:hb_social/features/diary/presentation/diary_page.dart';
import 'package:hb_social/features/diary/presentation/diary_stats_panel.dart';
import 'package:hb_social/features/diary/providers/diary_providers.dart';
import 'package:hb_social/features/dogs/presentation/dog_widgets.dart';
import 'package:hb_social/features/dogs/providers/dog_providers.dart';
import 'package:hb_social/features/sightings/presentation/sighting_widgets.dart';
import 'package:hb_social/features/sightings/providers/sightings_providers.dart';
import 'package:hb_social/features/reels/presentation/profile_reels_grid.dart';
import 'package:hb_social/features/reels/providers/reels_providers.dart';
import 'package:hb_social/core/services/seo_service.dart';

/// Public profile at `/u/:username`, living inside the shell as part of the
/// Profile branch (no own Scaffold/AppBar). There is no profiles backend
/// yet, so every lookup resolves to "not found" rather than any sample
/// profile. [debugPreview] (only reachable from `/dev/design-system` in
/// debug mode) renders the full layout with every field null, shown as "—".
class PublicProfilePage extends ConsumerStatefulWidget {
  final String username;
  final bool debugPreview;
  final String? initialTab;

  const PublicProfilePage({super.key, required this.username, this.debugPreview = false, this.initialTab});

  @override
  ConsumerState<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends ConsumerState<PublicProfilePage> {
  int _tabIndex = 0;

  @override
  void initState() { super.initState(); if (widget.initialTab == 'albums') _tabIndex = 1; if (widget.initialTab == 'diary') _tabIndex = 2; }

  void _onTabChanged(int index) => setState(() => _tabIndex = index);

  @override
  Widget build(BuildContext context) {
    if (widget.debugPreview) {
      return ProfileBody(username: widget.username, user: null, tabIndex: _tabIndex, onTabChanged: _onTabChanged);
    }

    final profile = ref.watch(publicProfileProvider(widget.username));
    return profile.when(
      loading: () => const PageColumns(center: Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.lg), child: ProfileSkeleton())),
      error: (error, stackTrace) => PageColumns(
        center: HBCard(
          child: HBEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'profile.error_title'.tr(),
            message: 'profile.error_message'.tr(),
            action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(publicProfileProvider(widget.username))),
          ),
        ),
      ),
      data: (user) {
        if (user == null) {
          return PageColumns(
            center: HBCard(
              child: HBEmptyState(icon: Icons.person_search_rounded, title: 'profile.not_found_title'.tr(), message: 'profile.not_found_message'.tr()),
            ),
          );
        }
        SeoService.update(title: '${user.displayName} - HB Social', description: user.bio?.isNotEmpty == true ? user.bio! : 'seo.profile_description'.tr(), path: AppRoutes.publicProfilePath(user.username), imageUrl: user.avatarUrl);
        return ProfileBody(username: widget.username, user: user, tabIndex: _tabIndex, onTabChanged: _onTabChanged);
      },
    );
  }
}

class ProfileBody extends ConsumerWidget {
  final String username;
  final UserProfile? user;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  const ProfileBody({super.key, required this.username, required this.user, required this.tabIndex, required this.onTabChanged});

  Future<void> _safetyAction(BuildContext context, WidgetRef ref, String value, UserProfile target) async {
    if (ref.read(supabaseClientProvider).auth.currentUser == null) { context.push(AppRoutes.login); return; }
    final repository = ref.read(safetyRepositoryProvider);
    try {
      if (value == 'report') {
        if (await showReportSheet(context, targetType: 'profile', targetId: target.id) && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('safety.report_success'.tr())));
        return;
      }
      if (value == 'mute') {
        if (!await showMuteConfirmation(context, target.displayName) || !context.mounted) return;
        await repository.muteUser(target.id);
        removeAuthorFromFeeds(ref, target.id);
        ref.invalidate(relationshipProvider(target.id));
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('safety.user_muted'.tr())));
        return;
      }
      if (value == 'unmute') {
        await repository.unmuteUser(target.id);
        ref.invalidate(relationshipProvider(target.id));
        ref.invalidate(feedPostsProvider); ref.invalidate(followingFeedProvider); ref.invalidate(nearbyFeedProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('safety.user_unmuted'.tr())));
        return;
      }
      if (value == 'block') {
        if (!await showBlockConfirmation(context, target.displayName) || !context.mounted) return;
        await repository.blockUser(target.id);
        ref.read(locallyBlockedUserIdsProvider.notifier).state = {...ref.read(locallyBlockedUserIdsProvider), target.id};
        removeAuthorFromFeeds(ref, target.id);
        ref.invalidate(relationshipProvider(target.id)); ref.invalidate(peopleSuggestionsProvider); ref.invalidate(connectionsProvider);
        ref.invalidate(profile_providers.currentProfileProvider); ref.invalidate(publicProfileProvider(target.username)); ref.invalidate(storyTrayProvider);
        if (context.mounted) { context.go(AppRoutes.home); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('safety.user_blocked'.tr()))); }
      }
    } on AppException catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    }
  }

  Future<void> _message(BuildContext context, WidgetRef ref, UserProfile target) async {
    try {
      final id = await ref.read(chatRepositoryProvider).startDirect(target.id);
      ref.invalidate(conversationsProvider);
      if (context.mounted) context.go(AppRoutes.conversationDetailPath(id));
    } on AppException catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secondaryStyle = context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant);
    final displayName = user?.displayName;
    final viewerId = ref.watch(authSessionProvider).value?.user.id;
    final isOther = user != null && viewerId != user!.id;
    final isOnline = isOther && viewerId != null && (ref.watch(onlineUsersProvider).value?.contains(user!.id) ?? false);
    final relationship = isOther && viewerId != null ? ref.watch(relationshipProvider(user!.id)).value : null;

    final hasListings = user == null ? false : ref.watch(sellerHasListingsProvider(user!.id)).value ?? false;
    final reels = user == null ? const [] : ref.watch(reelsByUserProvider(user!.id)).value ?? const [];
    final showReels = user != null && (viewerId == user!.id || reels.isNotEmpty);
    final visibleDogs = user == null ? const [] : ref.watch(dogsOfProvider(user!.id)).value ?? const [];
    final labels = ['profile.tab_posts'.tr(), 'albums.tab'.tr(), 'diary.profile_tab'.tr(), 'profile.tab_media'.tr(), 'profile.tab_info'.tr(), 'dogs.profile_tab_count'.tr(namedArgs: {'count': '${visibleDogs.length}'}), 'sightings.profile_tab'.tr(), if (hasListings) 'profile.tab_listings'.tr(), if (showReels) 'reels.profile.tab'.tr()];
    final reelTabIndex = showReels ? labels.length - 1 : null;
    return PageColumns(
      center: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            sliver: SliverList.list(
              children: [
                HBCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            height: 200,
                            width: double.infinity,
                            child: user?.coverUrl == null
                                ? const ColoredBox(color: LightModeColors.lightBackgroundSoft)
                                : Image.network(user!.coverUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const ColoredBox(color: LightModeColors.lightBackgroundSoft)),
                          ),
                          Positioned(
                            left: AppSpacing.lg,
                            bottom: -48,
                             child: HBAvatar(name: displayName, imageUrl: user?.avatarUrl, size: 96, ringColor: Colors.white, showPresence: isOnline),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 56, AppSpacing.lg, AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    (displayName == null || displayName.isEmpty) ? '—' : displayName,
                                    style: context.textStyles.headlineSmall?.copyWith(fontSize: 26, fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (user?.isVerified ?? false) ...[const SizedBox(width: AppSpacing.xs), HBBadge.verification(level: user!.verificationLevel, verifiedAt: user!.verifiedAt)],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('@$username', style: secondaryStyle),
                             if (isOther) PresenceLabel(userId: user!.id, lastSeenAt: user!.lastSeenAt),
                            if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(user!.bio!, style: context.textStyles.bodyMedium),
                            ],
                            if (user != null && user!.sellerRatingCount > 0) ...[
                              const SizedBox(height: AppSpacing.sm),
                              InkWell(onTap: () => context.push(AppRoutes.marketplaceSellerPath(user!.id)), child: Text('marketplace.profile_seller_rating'.tr(namedArgs: {'rating': '${user!.sellerRatingAverageHundredths ~/ 100},${(user!.sellerRatingAverageHundredths % 100) ~/ 10}', 'n': '${user!.sellerRatingCount}'}), style: context.textStyles.bodyMedium?.copyWith(color: LightModeColors.lightPrimary, fontWeight: FontWeight.w600))),
                            ],
                            if (user != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              ProfileHighlights(owner: user!, isOwn: ref.watch(authSessionProvider).value?.user.id == user!.id),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                _StatItem(labelKey: 'profile.stat_posts', value: user?.postCount),
                                const SizedBox(width: AppSpacing.lg),
                                _StatItem(labelKey: 'profile.stat_followers', value: user?.followerCount, onTap: user == null ? null : () => context.push('${AppRoutes.publicProfilePath(username)}/connections?tab=followers')),
                                const SizedBox(width: AppSpacing.lg),
                                _StatItem(labelKey: 'profile.stat_following', value: user?.followingCount, onTap: user == null ? null : () => context.push('${AppRoutes.publicProfilePath(username)}/connections?tab=following')),
                                const SizedBox(width: AppSpacing.lg),
                                _StatItem(labelKey: 'profile.stat_friends', value: user?.friendCount, onTap: user == null ? null : () => context.push('${AppRoutes.publicProfilePath(username)}/connections?tab=friends')),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                if (user != null && ref.watch(authSessionProvider).value?.user.id == user!.id) ...[
                                  HBButton.primary(label: 'profile.edit_cta'.tr(), onPressed: () => context.go(AppRoutes.profileEdit)),
                                  HBButton.secondary(label: 'settings.title'.tr(), onPressed: () => context.go(AppRoutes.settings)),
                                  HBButton.secondary(label: 'profile.badge_cta'.tr(), onPressed: () => context.go(AppRoutes.verification)),
                                  HBButton.secondary(label: 'marketplace.mine.title'.tr(), onPressed: () => context.push(AppRoutes.marketplaceMine)),
                                ] else if (user != null) ...[
                                  FollowButton(userId: user!.id, username: user!.username),
                                  FriendActionButton(userId: user!.id, username: user!.username),
                                   if (relationship?.blockedByMe != true && relationship?.blockedMe != true) HBButton.secondary(label: 'profile.message_cta'.tr(), onPressed: () => _message(context, ref, user!)),
                                   PopupMenuButton<String>(
                                     icon: const Icon(Icons.more_horiz_rounded), onSelected: (value) => _safetyAction(context, ref, value, user!),
                                     itemBuilder: (_) => [
                                       PopupMenuItem(value: 'report', child: Text('safety.report_profile'.tr())),
                                       PopupMenuItem(value: relationship?.mutedByMe == true ? 'unmute' : 'mute', child: Text((relationship?.mutedByMe == true ? 'safety.unmute' : 'safety.mute').tr())),
                                       PopupMenuItem(value: 'block', child: Text('safety.block'.tr())),
                                     ],
                                   ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                HBSegmentedTabs(
                  variant: HBSegmentedTabsVariant.underlined,
                  labels: labels,
                  selectedIndex: tabIndex,
                  onChanged: onTabChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                _ProfileTabContent(tabIndex: tabIndex, username: username, user: user, reelTabIndex: reelTabIndex),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileHighlights extends ConsumerWidget {
  final UserProfile owner;
  final bool isOwn;

  const ProfileHighlights({super.key, required this.owner, required this.isOwn});

  Future<void> _open(BuildContext context, WidgetRef ref, StoryHighlight highlight) async {
    await showDialog<void>(context: context, useSafeArea: false, builder: (_) => Dialog.fullscreen(child: StoryViewerPage.highlight(highlight: highlight, owner: owner)));
    ref.invalidate(storyHighlightsProvider(owner.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(storyHighlightsProvider(owner.id));
    return value.when(
      loading: () => const SizedBox(height: 92, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (!isOwn && items.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('story_highlights.section_title'.tr(), style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(height: 88, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: items.length + (isOwn ? 1 : 0), separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md), itemBuilder: (context, index) {
            if (isOwn && index == 0) return NewHighlightTile(onTap: () async { if (await showHighlightEditor(context)) { ref.invalidate(storyHighlightsProvider(owner.id)); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('story_highlights.created'.tr()))); } });
            final item = items[index - (isOwn ? 1 : 0)];
            return HighlightTile(highlight: item, onTap: () => _open(context, ref, item));
          })),
        ]);
      },
    );
  }
}

class HighlightTile extends StatelessWidget {
  final StoryHighlight highlight;
  final VoidCallback onTap;

  const HighlightTile({super.key, required this.highlight, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(width: 68, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.pill), child: Column(children: [
    ClipOval(child: SizedBox.square(dimension: 64, child: highlight.coverUrl == null ? const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.auto_awesome_outlined)) : Image.network(highlight.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.auto_awesome_outlined))))),
    const SizedBox(height: 4),
    Text(highlight.title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: context.textStyles.labelSmall),
  ])));
}

class NewHighlightTile extends StatelessWidget {
  final VoidCallback onTap;

  const NewHighlightTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(width: 68, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.pill), child: Column(children: [
    CustomPaint(painter: DashedCirclePainter(), child: const SizedBox.square(dimension: 64, child: Icon(Icons.add_rounded, color: LightModeColors.lightPrimary))),
    const SizedBox(height: 4),
    Text('story_highlights.new'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall),
  ])));
}

class DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = LightModeColors.lightPrimaryOutline..style = PaintingStyle.stroke..strokeWidth = 2;
    const segments = 20;
    for (var index = 0; index < segments; index += 2) canvas.drawArc(Offset.zero & size, index * 2 * 3.141592653589793 / segments, 2 * 3.141592653589793 / segments, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) => HBCard(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        HBSkeleton(height: 200, width: double.infinity, radius: AppRadius.md),
        SizedBox(height: AppSpacing.lg),
        HBSkeleton(height: 28, width: 220),
        SizedBox(height: AppSpacing.sm),
        HBSkeleton(height: 16, width: 140),
        SizedBox(height: AppSpacing.lg),
        HBSkeleton(height: 80, width: double.infinity),
      ],
    ),
  );
}

class _StatItem extends StatelessWidget {
  final String labelKey;
  final int? value;
  final VoidCallback? onTap;

  const _StatItem({required this.labelKey, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.xs), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value == null ? '—' : '$value', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        Text(value == null ? labelKey.plural(2) : labelKey.plural(value!), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      ],
    ));
  }
}

class _ProfileTabContent extends ConsumerWidget {
  final int tabIndex;
  final String username;
  final UserProfile? user;
  final int? reelTabIndex;

  const _ProfileTabContent({required this.tabIndex, required this.username, required this.user, this.reelTabIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reelTabIndex == tabIndex && user != null) return ProfileReelsGrid(userId: user!.id, isOwn: ref.watch(authSessionProvider).value?.user.id == user!.id);
    switch (tabIndex) {
      case 0:
        if (user == null) return HBCard(child: HBEmptyState(icon: Icons.grid_on_outlined, title: 'profile.posts_empty_title'.tr(), message: 'profile.posts_empty_message'.tr()));
        return ref.watch(authorPostsProvider(user!.id)).when(
          loading: () => const ProfileSkeleton(),
          error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'feed.error_title'.tr(), message: 'feed.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(authorPostsProvider(user!.id))))),
          data: (page) => page.items.isEmpty
              ? HBCard(child: HBEmptyState(icon: Icons.grid_on_outlined, title: 'profile.posts_empty_title'.tr(), message: 'profile.posts_empty_message'.tr()))
              : Column(children: [
                  for (final post in page.items) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: FeedPostCard(post: post)),
                  if (page.hasMore) HBButton.secondary(label: page.isLoadingMore ? 'common.loading'.tr() : 'feed.load_more'.tr(), onPressed: page.isLoadingMore ? null : () => ref.read(authorPostsProvider(user!.id).notifier).loadMore()),
                ]),
        );
      case 1:
        if (user == null) return const SizedBox.shrink();
        return ProfileAlbums(owner: user!, isOwn: ref.watch(authSessionProvider).value?.user.id == user!.id);
      case 2:
        if (user == null) return const SizedBox.shrink();
        return ProfileDiary(user: user!);
      case 3:
        return HBCard(child: HBEmptyState(icon: Icons.photo_library_outlined, title: 'profile.media_empty_title'.tr(), message: 'profile.media_empty_message'.tr()));
      case 5:
        if (user == null) return const SizedBox.shrink();
        return ref.watch(dogsOfProvider(user!.id)).when(loading: () => const ProfileSkeleton(), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'dogs.error_title'.tr(), message: 'dogs.error_message'.tr())), data: (dogs) => dogs.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.pets_outlined, title: 'dogs.profile_empty'.tr(), message: 'dogs.profile_empty_message'.tr())) : DogCards(dogs: dogs, compact: true));
      case 6:
        if (user == null) return const SizedBox.shrink();
        return ref.watch(sightingsOfProvider(user!.id)).when(loading: () => const ProfileSkeleton(), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'sightings.errors.title'.tr(), message: 'sightings.errors.generic'.tr())), data: (state) => state.items.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.visibility_outlined, title: 'sightings.profile_empty.title'.tr(), message: 'sightings.profile_empty.message'.tr())) : SightingsList(items: state.items, hasMore: state.hasMore, loadingMore: state.loadingMore, onLoadMore: () => ref.read(sightingsOfProvider(user!.id).notifier).loadMore()));
      case 7:
        if (user == null) return const SizedBox.shrink();
        return ref.watch(sellerListingsProvider(user!.id)).when(
          loading: () => const ProfileSkeleton(),
          error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'marketplace.error_title'.tr(), message: 'marketplace.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(sellerListingsProvider(user!.id))))),
          data: (page) => page.isEmpty
              ? HBCard(child: HBEmptyState(icon: Icons.storefront_outlined, title: 'marketplace.empty_title'.tr(), message: 'marketplace.empty_message'.tr()))
              : LayoutBuilder(builder: (context, constraints) => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: constraints.maxWidth >= 760 ? 3 : 2, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: 0.62), itemCount: page.length, itemBuilder: (context, index) => MarketplaceListingCard(listing: page[index]))),
        );
      default:
        return ProfileInfoCard(username: username, user: user);
    }
  }
}

class ProfileDiary extends ConsumerStatefulWidget {
  final UserProfile user;
  const ProfileDiary({super.key, required this.user});
  @override
  ConsumerState<ProfileDiary> createState() => _ProfileDiaryState();
}

class _ProfileDiaryState extends ConsumerState<ProfileDiary> {
  String? season;
  String? unitFilter;
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final seasons = ref.watch(diarySeasonsProvider(widget.user.id)).value ?? const [];
    if (season == null && seasons.isNotEmpty) season = seasons.first.seasonLabel;
    final selectedIndex = seasons.indexWhere((item) => item.seasonLabel == season);
    final previous = selectedIndex >= 0 && selectedIndex + 1 < seasons.length ? seasons[selectedIndex + 1].seasonLabel : null;
    final request = (userId: widget.user.id, season: season);
    final owner = ref.watch(authSessionProvider).value?.user.id == widget.user.id;
    final regionName = widget.user.homeRegionId == null ? '' : (ref.watch(regionsProvider(widget.user.countryCode)).value ?? const []).where((item) => item.id == widget.user.homeRegionId).firstOrNull?.name ?? '';
    final list = ref.watch(outingsProvider(request));
    if (seasons.isEmpty && list.value?.items.isEmpty == true) return HBCard(child: HBEmptyState(icon: Icons.menu_book_outlined, title: 'diary.profile_empty_title'.tr(), message: 'diary.profile_empty_message'.tr()));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [DiarySeasonSelector(value: season, seasons: seasons, onChanged: (value) => setState(() { season = value; unitFilter = null; })), const SizedBox(width: AppSpacing.md), Expanded(child: HBSegmentedTabs(labels: ['diary.tabs.outings'.tr(), 'diary.tabs.stats'.tr()], selectedIndex: tab, onChanged: (value) => setState(() => tab = value)))]), const SizedBox(height: AppSpacing.md), if (tab == 0) list.when(
      loading: () => const ProfileSkeleton(),
      error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'diary.error_title'.tr(), message: 'diary.error_message'.tr())),
      data: (state) {
        if (state.items.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.menu_book_outlined, title: 'diary.profile_empty_title'.tr(), message: 'diary.profile_empty_message'.tr()));
        final urls = ref.watch(diaryCoversProvider(state.items)).value ?? const <String, String>{};
        final items = unitFilter == null ? state.items : state.items.where((item) => item.unitId == unitFilter).toList();
        return Column(children: [if (unitFilter != null) Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: HBButton.ghost(label: 'diary.stats.clear_filter'.tr(), icon: Icons.close_rounded, onPressed: () => setState(() => unitFilter = null)))), for (final outing in items) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: OutingCard(outing: outing, coverUrl: urls[outing.coverThumbnailPath ?? outing.coverPath])), if (state.hasMore) HBButton.secondary(label: state.loadingMore ? 'common.loading'.tr() : 'feed.load_more'.tr(), onPressed: state.loadingMore ? null : () => ref.read(outingsProvider(request).notifier).loadMore())]);
      },
    ) else DiaryStatsPanel(userId: widget.user.id, season: season, previousSeason: previous, owner: owner, profile: owner ? widget.user : null, regionName: regionName, onPlaceSelected: (unitId) => setState(() { unitFilter = unitId; tab = 0; }))]);
  }
}

/// Displays the public profile fields in the Info tab.
class ProfileInfoCard extends ConsumerWidget {
  final String username;
  final UserProfile? user;

  const ProfileInfoCard({super.key, required this.username, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberSince = user?.createdAt;
    final unavailable = 'common.unavailable'.tr();
    final regions = user == null ? null : ref.watch(regionsProvider(user!.countryCode));
    final municipality = user?.homeMunicipalityId == null ? null : ref.watch(municipalityProvider(user!.homeMunicipalityId!));
    final regionName = regions?.when(
      loading: () => 'common.loading'.tr(),
      error: (_, __) => unavailable,
      data: (items) => items.where((item) => item.id == user!.homeRegionId).firstOrNull?.name ?? unavailable,
    );
    return HBCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('profile.tab_info'.tr(), style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'profile.info_username_label'.tr(), value: '@$username'),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(label: 'profile.info_bio_label'.tr(), value: (user?.bio == null || user!.bio!.isEmpty) ? unavailable : user!.bio!),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(label: 'profile.info_region_label'.tr(), value: regionName ?? unavailable),
          const SizedBox(height: AppSpacing.sm),
          if (user?.homeMunicipalityId != null) ...[_InfoRow(label: 'profile.info_municipality_label'.tr(), value: municipality?.value?.compactName ?? unavailable), const SizedBox(height: AppSpacing.sm)],
          _InfoRow(
            label: 'profile.info_member_since_label'.tr(),
            value: memberSince == null ? unavailable : DateFormat.yMMMd(context.locale.languageCode).format(memberSince.toLocal()),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: context.textStyles.labelMedium?.withColor(LightModeColors.lightTextTertiary)),
        ),
        Expanded(child: Text(value, style: context.textStyles.bodyMedium)),
      ],
    );
  }
}
