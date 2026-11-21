import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/data/paged_notifier.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_paged_sliver_list.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/ads/domain/ad_delivery.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/presentation/widgets/sponsored_card.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:hb_social/features/home/presentation/widgets/feed_composer_bar.dart';
import 'package:hb_social/features/home/presentation/widgets/feed_filter_bar.dart';
import 'package:hb_social/features/home/presentation/widgets/feed_post_card.dart';
import 'package:hb_social/features/home/presentation/widgets/feed_post_skeleton.dart';
import 'package:hb_social/features/home/presentation/widgets/home_greeting_header.dart';
import 'package:hb_social/features/home/presentation/widgets/home_hero_banner.dart';
import 'package:hb_social/features/home/presentation/widgets/hunting_shortcuts_row.dart';
import 'package:hb_social/features/home/presentation/widgets/today_hunting_card.dart';
import 'package:hb_social/features/home/providers/feed_providers.dart';
import 'package:hb_social/features/polls/providers/poll_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/stories/presentation/story_tray.dart';
import 'package:hb_social/features/settings/providers/settings_providers.dart';
import 'package:hb_social/features/live/presentation/live_home_strip.dart';
import 'package:hb_social/features/memories/presentation/memories_card.dart';
import 'package:intl/intl.dart';

class HomeFeedPage extends ConsumerStatefulWidget {
  const HomeFeedPage({super.key});

  @override
  ConsumerState<HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends ConsumerState<HomeFeedPage> {
  late final Map<FeedFilter, ScrollController> _controllers = {for (final filter in FeedFilter.values) filter: ScrollController()..addListener(() => _onScroll(filter))};

  /// UI-only chip index (0..3). The 4th chip ("Più recenti") reuses the
  /// for-you feed, which is already ordered by date: no new provider needed.
  int _chipIndex = 0;

  FeedFilter _filterForChip(int index) => switch (index) { 1 => FeedFilter.following, 2 => FeedFilter.nearby, _ => FeedFilter.forYou };

  void _onScroll(FeedFilter filter) {
    final controller = _controllers[filter]!;
    if (!controller.hasClients || controller.position.extentAfter > 600) return;
    _loadMore(filter);
  }

  Future<void> _refresh(FeedFilter filter) => switch (filter) {
    FeedFilter.forYou => ref.read(feedPostsProvider.notifier).refresh(),
    FeedFilter.following => ref.read(followingFeedProvider.notifier).refresh(),
    FeedFilter.nearby => ref.read(nearbyFeedProvider.notifier).refresh(),
  };

  void _loadMore(FeedFilter filter) {
    switch (filter) {
      case FeedFilter.forYou: ref.read(feedPostsProvider.notifier).loadMore();
      case FeedFilter.following: ref.read(followingFeedProvider.notifier).loadMore();
      case FeedFilter.nearby: ref.read(nearbyFeedProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) { controller.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;
    final filter = ref.watch(feedFilterProvider);
    final AsyncValue<PagedState<FeedPost>> posts = switch (filter) {
      FeedFilter.forYou => ref.watch(feedPostsProvider),
      FeedFilter.following => ref.watch(followingFeedProvider),
      FeedFilter.nearby => ref.watch(nearbyFeedProvider),
    };
    final session = ref.watch(authSessionProvider).value;
    final profile = ref.watch(currentProfileProvider).value;
    final pollPostIds = posts.value?.items.where((post) => post.kind == 'poll').map((post) => post.id).join(',') ?? '';
    final polls = ref.watch(pollsForPostsProvider(pollPostIds)).value ?? const {};
    final feedAds = posts.value?.items.length != null && posts.value!.items.length >= 4 ? ref.watch(deliveredAdsProvider(const AdPlacementRequest(AdPlacement.feed, count: 2))).value ?? const [] : const [];
    final filterBar = FeedFilterBar(labels: feedFilterLabels(), selectedIndex: _chipIndex, onChanged: (index) => setState(() {
      _chipIndex = index;
      ref.read(feedFilterProvider.notifier).state = _filterForChip(index);
    }), onRefresh: () => _refresh(filter));

    final scrollView = CustomScrollView(
      controller: _controllers[filter],
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(isWide ? 0 : AppSpacing.md, AppSpacing.sm, isWide ? 0 : AppSpacing.md, 0),
          sliver: SliverList.list(children: isWide
              ? const [
                  AccountDeletionBanner(),
                  HomeHeroBanner(),
                  SizedBox(height: AppSpacing.md),
                  StoryTray(),
                  SizedBox(height: AppSpacing.md),
                   LiveHomeStrip(),
                  MemoriesTodayCard(),
                  FeedComposerBar(),
                  SizedBox(height: AppSpacing.md),
                ]
              : [
                  const AccountDeletionBanner(),
                   const HomeGreetingHeader(),
                   const SizedBox(height: AppSpacing.sm),
                  const MobileTodayHuntingPanel(),
                  const SizedBox(height: AppSpacing.lg),
                  const HuntingShortcutsRow(),
                  const SizedBox(height: AppSpacing.lg),
                  Row(children: [
                    Expanded(child: Text('home.stories_title'.tr(), style: AppText.title.withColor(LightModeColors.text))),
                    InkWell(onTap: () => context.go(AppRoutes.search), child: Text('common.see_all'.tr(), style: AppText.buttonLg.withColor(LightModeColors.bosco))),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  const StoryTray(),
                  const SizedBox(height: AppSpacing.lg),
                   const LiveHomeStrip(),
                   const MemoriesTodayCard(),
                  const FeedComposerBar(),
                  const SizedBox(height: AppSpacing.lg),
                ]),
        ),
        if (isWide) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: filterBar)),
        SliverPadding(
          padding: EdgeInsets.only(bottom: AppSpacing.lg),
          sliver: HBPagedSliverList(
            value: posts,
            spacing: isWide ? AppSpacing.md : 0,
            itemBuilder: (context, post, index) {
              final adIndex = index >= 3 && (index - 3) % 8 == 0 ? (index - 3) ~/ 8 : -1;
              return Column(children: [
                FeedPostCard(post: post, poll: polls[post.id], edgeToEdge: !isWide),
                if (adIndex >= 0 && adIndex < feedAds.length) ...[const SizedBox(height: AppSpacing.md), SponsoredCard(ad: feedAds[adIndex])],
              ]);
            },
            loading: Column(children: [FeedPostSkeleton(edgeToEdge: !isWide), SizedBox(height: isWide ? AppSpacing.md : 0), FeedPostSkeleton(edgeToEdge: !isWide), SizedBox(height: isWide ? AppSpacing.md : 0), FeedPostSkeleton(edgeToEdge: !isWide)]),
            error: HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'feed.error_title'.tr(), message: 'feed.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => _refresh(filter)))),
            empty: FeedTabEmptyState(filter: filter, isAuthenticated: session != null, hasRegion: profile?.homeRegionId != null),
            onRetry: () => _refresh(filter),
            onLoadMore: () => _loadMore(filter),
          ),
        ),
      ],
    );

    final center = isWide ? scrollView : RefreshIndicator(onRefresh: () => _refresh(filter), child: scrollView);
    return PageColumns(gutter: false, center: center);
  }
}

class AccountDeletionBanner extends ConsumerWidget {
  const AccountDeletionBanner({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(myAccountDeletionProvider).maybeWhen(data: (status) {
    if (!status.pending) return const SizedBox.shrink();
    final date = status.eraseAfter == null ? '' : DateFormat.yMd(context.locale.toString()).format(status.eraseAfter!.toLocal());
    return Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: HBCard(color: LightModeColors.lightErrorContainer, child: Row(children: [const Icon(Icons.warning_amber_rounded, color: LightModeColors.lightError), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('p41.privacy.home_deletion_banner'.tr(namedArgs: {'date': date}))), HBButton.soft(label: 'p41.privacy.cancel_deletion'.tr(), onPressed: () async { await ref.read(userSettingsRepositoryProvider).cancelAccountDeletion(); ref.invalidate(myAccountDeletionProvider); })])));
  }, orElse: () => const SizedBox.shrink());
}

class FeedTabEmptyState extends StatelessWidget {
  final FeedFilter filter;
  final bool isAuthenticated;
  final bool hasRegion;

  const FeedTabEmptyState({super.key, required this.filter, required this.isAuthenticated, required this.hasRegion});

  @override
  Widget build(BuildContext context) {
    late final String titleKey;
    String? actionKey;
    String? route;
    if (filter == FeedFilter.following && !isAuthenticated) {
      titleKey = 'feed.following_guest'; actionKey = 'profile.signed_out_cta'; route = AppRoutes.login;
    } else if (filter == FeedFilter.following) {
      titleKey = 'feed.following_empty'; actionKey = 'feed.find_people'; route = AppRoutes.search;
    } else if (filter == FeedFilter.nearby && !isAuthenticated) {
      titleKey = 'feed.nearby_guest'; actionKey = 'profile.signed_out_cta'; route = AppRoutes.login;
    } else if (filter == FeedFilter.nearby && !hasRegion) {
      titleKey = 'feed.nearby_no_region'; actionKey = 'feed.set_region'; route = AppRoutes.settings;
    } else if (filter == FeedFilter.nearby) {
      titleKey = 'feed.nearby_empty';
    } else {
      titleKey = 'feed.empty_title'; actionKey = 'feed.empty_cta'; route = AppRoutes.search;
    }
    return HBCard(child: HBEmptyState(icon: Icons.dynamic_feed_outlined, title: titleKey.tr(), message: 'feed.empty_message'.tr(), action: actionKey == null ? null : HBButton.primary(label: actionKey.tr(), onPressed: () => context.go(route!))));
  }
}
