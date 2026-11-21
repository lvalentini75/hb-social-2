import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/comments/presentation/comment_thread.dart';
import 'package:hb_social/features/home/presentation/widgets/feed_post_card.dart';
import 'package:hb_social/features/home/presentation/widgets/feed_post_skeleton.dart';
import 'package:hb_social/features/home/providers/feed_providers.dart';
import 'package:hb_social/features/polls/providers/poll_providers.dart';

class PostDetailPage extends ConsumerWidget {
  final String postId;
  final String? commentId;

  const PostDetailPage({super.key, required this.postId, this.commentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(postDetailProvider(postId)).when(
    loading: () => const PageColumns(center: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: FeedPostSkeleton())),
    error: (_, __) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'feed.error_title'.tr(), message: 'feed.error_message'.tr()))),
    data: (post) {
      if (post == null) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.article_outlined, title: 'post.not_available_title'.tr(), message: 'post.not_available_message'.tr())));
      final poll = post.kind == 'poll' ? ref.watch(pollForPostProvider(postId)).value : null;
      return PageColumns(center: CustomScrollView(slivers: [
        SliverPadding(padding: const EdgeInsets.only(top: AppSpacing.lg), sliver: SliverToBoxAdapter(child: FeedPostCard(post: post, poll: poll, detailMode: true))),
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          sliver: SliverToBoxAdapter(child: HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('comments.title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md),
            CommentPanel(postId: postId, postAuthorId: post.author.id, highlightCommentId: commentId, onCountChanged: (_) => ref.invalidate(postDetailProvider(postId))),
          ]))),
        ),
      ]));
    },
  );
}