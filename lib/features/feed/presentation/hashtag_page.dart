import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_paged_sliver_list.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/home/presentation/widgets/feed_post_card.dart';
import 'package:hb_social/features/home/presentation/widgets/feed_post_skeleton.dart';
import 'package:hb_social/features/home/providers/feed_providers.dart';

class HashtagPage extends ConsumerWidget {
  final String tag;

  const HashtagPage({super.key, required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(hashtagPostsProvider(tag));
    final count = ref.watch(hashtagCountProvider(tag)).value ?? 0;
    return PageColumns(center: CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        sliver: SliverToBoxAdapter(child: Text('hashtags.title'.tr(namedArgs: {'tag': tag, 'n': '$count'}), style: context.textStyles.headlineSmall)),
      ),
      HBPagedSliverList(
        value: posts,
        itemBuilder: (context, post, index) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: FeedPostCard(post: post)),
        loading: const FeedPostSkeleton(),
        empty: HBCard(child: HBEmptyState(icon: Icons.tag_rounded, title: 'hashtags.empty_title'.tr(namedArgs: {'tag': tag}), message: 'hashtags.empty_message'.tr())),
        error: HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'feed.error_title'.tr(), message: 'feed.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(hashtagPostsProvider(tag))))),
        onRetry: () => ref.invalidate(hashtagPostsProvider(tag)),
        onLoadMore: () => ref.read(hashtagPostsProvider(tag).notifier).loadMore(),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
    ]));
  }
}