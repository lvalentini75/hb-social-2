import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/home/presentation/widgets/feed_composer_bar.dart';
import 'package:hb_social/features/home/presentation/widgets/feed_post_skeleton.dart';
import 'package:hb_social/features/home/presentation/widgets/home_greeting_header.dart';
import 'package:hb_social/features/home/presentation/widgets/hunting_shortcuts_row.dart';
import 'package:hb_social/features/home/presentation/widgets/stories_row.dart';
import 'package:hb_social/features/home/presentation/widgets/today_hunting_card.dart';
import 'package:hb_social/features/home/providers/feed_providers.dart';
import 'package:hb_social/shell/widgets/right_rail.dart';

/// Center column of the Home screen: greeting, "Oggi a caccia", stories,
/// the composer (web only) and the feed itself. No posts exist yet (no
/// backend), so the feed renders its loading, error and empty states rather
/// than any sample content.
class HomeFeedPage extends ConsumerWidget {
  const HomeFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;
    final filter = ref.watch(feedFilterProvider);
    final posts = ref.watch(feedPostsProvider);

    final tabs = HBSegmentedTabs(
      labels: ['home.filter_for_you'.tr(), 'home.filter_following'.tr(), 'home.filter_nearby'.tr()],
      selectedIndex: FeedFilter.values.indexOf(filter),
      onChanged: (index) => ref.read(feedFilterProvider.notifier).state = FeedFilter.values[index],
    );

    return PageColumns(
      rail: const RightRail(),
      center: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            sliver: SliverList.list(
              children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(child: HomeGreetingHeader()),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(width: 300, child: tabs),
                  ],
                )
              else
                const HomeGreetingHeader(showAvatar: true),
              const SizedBox(height: AppSpacing.lg),
              TodayHuntingCard(isWide: isWide),
              const SizedBox(height: AppSpacing.md),
              if (!isWide) ...[const HuntingShortcutsRow(), const SizedBox(height: AppSpacing.md)],
              const StoriesRow(),
              const SizedBox(height: AppSpacing.md),
              if (isWide) ...[const FeedComposerBar(), const SizedBox(height: AppSpacing.md)],
              if (!isWide) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'home.community_title'.tr(),
                        style: context.textStyles.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(width: 180, child: tabs),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              posts.when(
                loading: () => Column(
                  children: const [
                    FeedPostSkeleton(),
                    SizedBox(height: AppSpacing.md),
                    FeedPostSkeleton(),
                    SizedBox(height: AppSpacing.md),
                    FeedPostSkeleton(),
                  ],
                ),
                error: (error, stackTrace) => HBCard(
                  child: HBEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'feed.error_title'.tr(),
                    message: 'feed.error_message'.tr(),
                    action: HBButton.secondary(
                      label: 'common.retry'.tr(),
                      onPressed: () => ref.invalidate(feedPostsProvider),
                    ),
                  ),
                ),
                data: (items) => HBCard(
                  child: HBEmptyState(
                    icon: Icons.dynamic_feed_outlined,
                    title: 'feed.empty_title'.tr(),
                    message: 'feed.empty_message'.tr(),
                    action: HBButton.primary(
                      label: 'feed.empty_cta'.tr(),
                      onPressed: () => context.go(AppRoutes.search),
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
