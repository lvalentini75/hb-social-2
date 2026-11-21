import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_rich_text.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/translatable_text.dart';
import 'package:hb_social/core/providers/translation_providers.dart';
import 'package:hb_social/features/feed/domain/reaction.dart' show ReactionSummary, ReactionTypeUi;
import 'package:hb_social/features/feed/presentation/widgets/reaction_button.dart';
import 'package:hb_social/features/feed/presentation/widgets/reactions_sheet.dart';
import 'package:hb_social/features/feed/presentation/widgets/share_sheet.dart';
import 'package:hb_social/features/feed/presentation/widgets/post_media_grid.dart';
import 'package:hb_social/features/feed/providers/reaction_providers.dart';
import 'package:hb_social/features/composer/providers/composer_providers.dart';
import 'package:hb_social/features/comments/domain/post_comment.dart';
import 'package:hb_social/features/comments/presentation/comment_thread.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:hb_social/features/home/providers/feed_providers.dart';
import 'package:hb_social/features/polls/domain/poll.dart';
import 'package:hb_social/features/polls/presentation/widgets/poll_card.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/profile/providers/public_profile_providers.dart';
import 'package:hb_social/features/pages/providers/page_providers.dart';
import 'package:hb_social/features/safety/presentation/report_sheet.dart';
import 'package:hb_social/features/safety/presentation/safety_confirmations.dart';
import 'package:hb_social/features/safety/providers/safety_providers.dart';
import 'package:hb_social/features/social_graph/providers/social_graph_providers.dart';
import 'package:hb_social/features/stories/providers/story_providers.dart';
import 'package:hb_social/features/ads/presentation/boost_sheet.dart';
import 'package:hb_social/features/dogs/domain/dog.dart';
import 'package:hb_social/features/dogs/presentation/dog_tag_selector.dart';
import 'package:hb_social/features/dogs/providers/dog_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hb_social/features/pages/articles/presentation/page_articles.dart';

class FeedPostCard extends ConsumerStatefulWidget {
  final FeedPost post;
  final Poll? poll;
  final bool detailMode;

  /// Narrow layouts render the card full-bleed (no radius, no shadow) so the
  /// media is the protagonist, like a native social feed.
  final bool edgeToEdge;

  const FeedPostCard({super.key, required this.post, this.poll, this.detailMode = false, this.edgeToEdge = false});

  @override
  ConsumerState<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends ConsumerState<FeedPostCard> {
  late FeedPost _post = widget.post;
  bool _commentsOpen = false;
  bool _hidden = false;

  void _openDetail() => context.push(AppRoutes.postPath(_post.id));

  void _commentCountChanged(int delta) {
    final updated = _post.copyWith(commentCount: (_post.commentCount + delta).clamp(0, 1 << 30));
    setState(() => _post = updated);
    replacePostInFeeds(ref, updated);
    ref.invalidate(postDetailProvider(_post.id));
  }

  void _commentCreated(Comment comment) {
    final preview = [..._post.previewComments];
    if (comment.parentId == null) {
      preview.add(comment);
      preview.sort((a, b) {
        final reactions = b.reactionCount.compareTo(a.reactionCount);
        return reactions != 0 ? reactions : b.createdAt.compareTo(a.createdAt);
      });
    }
    final updated = _post.copyWith(commentCount: _post.commentCount + 1, previewComments: preview.take(2).toList());
    setState(() => _post = updated);
    replacePostInFeeds(ref, updated);
    ref.invalidate(postDetailProvider(_post.id));
  }

  String _reactionLabel() {
    final total = _post.reactionCount;
    final name = _post.reactionDisplayName;
    final mine = _post.myReaction != null;
    if (mine && total == 1) return 'reactions.summary_you'.tr();
    if (name == null || name.isEmpty) return '$total';
    if (mine && total == 2) return 'reactions.summary_you_and_name'.tr(namedArgs: {'name': name});
    if (mine && total > 2) {
      final others = 'reactions.others'.plural(total - 2);
      return 'reactions.summary_you_name_more'.tr(namedArgs: {'name': name, 'others': others});
    }
    if (!mine && total == 1) return name;
    final others = 'reactions.others'.plural(total - 1);
    return 'reactions.summary_name_more'.tr(namedArgs: {'name': name, 'others': others});
  }

  void _openComments() {
    if (MediaQuery.sizeOf(context).width >= 900) {
      setState(() => _commentsOpen = !_commentsOpen);
      return;
    }
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: LightModeColors.lightSurface,
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.96, minChildSize: 0.6, maxChildSize: 0.96,
        builder: (context, controller) => Column(children: [
          Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [Expanded(child: Text('comments.sheet_title'.tr(namedArgs: {'n': '${_post.commentCount}'}), style: context.textStyles.titleLarge)), HBButton.icon(icon: Icons.close_rounded, onPressed: () => context.pop())])),
          const Divider(height: 1, color: LightModeColors.lightDivider),
          Expanded(child: CommentPanel(postId: _post.id, postAuthorId: _post.author.id, onCountChanged: _commentCountChanged, onCommentCreated: _commentCreated, fixedComposer: true)),
        ]),
      ),
    );
  }

  Future<void> _edit() async {
    final result = await showDialog<({String content, Set<String> dogIds})>(context: context, builder: (_) => EditPostDialog(initialContent: _post.content ?? '', initialDogIds: _post.dogs.map((dog) => dog.id).toSet()));
    if (result == null || !mounted) return;
    try {
      await ref.read(composerRepositoryProvider).updatePost(_post.id, result.content);
      ref.read(translationServiceProvider).invalidate('post', _post.id);
      await ref.read(dogsRepositoryProvider).tagPostDogs(_post.id, result.dogIds.toList());
      final refreshed = await ref.read(feedRepositoryProvider).getById(_post.id);
      final updated = refreshed ?? _post.copyWith(content: result.content.trim(), clearContent: result.content.trim().isEmpty);
      setState(() => _post = updated);
      replacePostInFeeds(ref, updated);
      ref.invalidate(postDetailProvider(_post.id));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('post.updated'.tr())));
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(context: context, builder: (_) => const DeletePostDialog()) ?? false;
    if (!confirmed || !mounted) return;
    try {
      await ref.read(composerRepositoryProvider).deletePost(_post.id);
      final media = ref.read(mediaUploadServiceProvider);
      for (final item in _post.media) {
        try { await media.delete('post-media', media.pathFromPublicUrl('post-media', item.url) ?? item.url); } catch (_) {}
      }
      removePostFromFeeds(ref, _post.id);
      ref.invalidate(currentProfileProvider);
      if (widget.detailMode && mounted) context.go(AppRoutes.home);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('post.deleted'.tr())));
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    }
  }

  Future<void> _hide() async {
    final messenger = ScaffoldMessenger.of(context);
    final indexes = postIndexesInFeeds(ref, _post.id);
    final repository = ref.read(safetyRepositoryProvider);
    final forYou = ref.read(feedPostsProvider.notifier);
    final following = ref.read(followingFeedProvider.notifier);
    final nearby = ref.read(nearbyFeedProvider.notifier);
    try {
      await repository.hidePost(_post.id);
      if (!mounted) return;
      setState(() => _hidden = true);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      removePostFromFeeds(ref, _post.id);
      messenger.showSnackBar(SnackBar(content: Text('safety.post_hidden'.tr()), action: SnackBarAction(label: 'safety.undo'.tr(), onPressed: () async {
        try {
          await repository.unhidePost(_post.id);
          if (indexes[FeedFilter.forYou] case final index?) forYou.restorePost(_post, index);
          if (indexes[FeedFilter.following] case final index?) following.restorePost(_post, index);
          if (indexes[FeedFilter.nearby] case final index?) nearby.restorePost(_post, index);
        } catch (_) {}
      })));
    } on AppException catch (error) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    }
  }

  Future<void> _mute() async {
    if (!await showMuteConfirmation(context, _post.author.displayName) || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(safetyRepositoryProvider);
    final active = ref.read(feedFilterProvider);
    final activeNotifier = switch (active) {
      FeedFilter.forYou => ref.read(feedPostsProvider.notifier),
      FeedFilter.following => ref.read(followingFeedProvider.notifier),
      FeedFilter.nearby => ref.read(nearbyFeedProvider.notifier),
    };
    try {
      await repository.muteUser(_post.author.id);
      removeAuthorFromFeeds(ref, _post.author.id);
      messenger.showSnackBar(SnackBar(content: Text('safety.user_muted'.tr()), action: SnackBarAction(label: 'safety.undo'.tr(), onPressed: () async {
        try {
          await repository.unmuteUser(_post.author.id);
          await activeNotifier.refresh();
        } catch (_) {}
      })));
    } on AppException catch (error) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    }
  }

  Future<void> _block() async {
    if (!await showBlockConfirmation(context, _post.author.displayName) || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(safetyRepositoryProvider).blockUser(_post.author.id);
      ref.read(locallyBlockedUserIdsProvider.notifier).state = {...ref.read(locallyBlockedUserIdsProvider), _post.author.id};
      removeAuthorFromFeeds(ref, _post.author.id);
      ref.invalidate(relationshipProvider(_post.author.id));
      ref.invalidate(peopleSuggestionsProvider);
      ref.invalidate(connectionsProvider);
      ref.invalidate(currentProfileProvider);
      ref.invalidate(publicProfileProvider(_post.author.username));
      ref.invalidate(storyTrayProvider);
      messenger.showSnackBar(SnackBar(content: Text('safety.user_blocked'.tr())));
    } on AppException catch (error) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    }
  }

  Future<void> _report() async {
    if (await showReportSheet(context, targetType: 'post', targetId: _post.id) && mounted) {
      setState(() => _hidden = true);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      removePostFromFeeds(ref, _post.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('safety.report_success'.tr())));
    }
  }

  void _handleOtherMenu(String value) {
    if (ref.read(supabaseClientProvider).auth.currentUser == null) { context.push(AppRoutes.login); return; }
    if (value == 'hide') _hide();
    if (value == 'mute') _mute();
    if (value == 'report') _report();
    if (value == 'block') _block();
  }

  void _handleOwnerMenu(String value) {
    if (value == 'boost') { showBoostSheet(context, targetType: 'post', targetId: _post.id); return; }
    if (value == 'edit') { _edit(); return; }
    _delete();
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(postLiveUpdatesProvider.select((updates) => updates[_post.id]));
    if (live != null) {
      _post = _post.copyWith(
        reactionCount: live.reactionCount,
        commentCount: live.commentCount,
        shareCount: live.shareCount,
        reactionSummary: live.reactionSummary,
        reactionDisplayName: live.reactionDisplayName,
        clearReactionDisplayName: live.reactionSummary != null && live.reactionDisplayName == null,
      );
      if (live.status != 'published') return const AnimatedSize(duration: Duration(milliseconds: 180), child: SizedBox.shrink());
    }
    final author = _post.author;
    final page = _post.page;
    final pageRole = page == null ? null : ref.watch(pageStudioSummaryProvider(page.id)).value?.myRole;
    final isOwner = page == null && ref.watch(supabaseClientProvider).auth.currentUser?.id == author.id;
    final canDeletePagePost = page != null && pageRole != null;
    final canBoost = _post.visibility == 'public' && (isOwner || canDeletePagePost);
    final identityName = page?.name ?? author.displayName;
    final identityAvatar = page?.avatarUrl ?? author.avatarUrl;
    final identityPath = page == null ? AppRoutes.publicProfilePath(author.username) : AppRoutes.pageDetailPath(page.slug);
    final relativeDate = relativeTime(context, _post.createdAt);
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;
    final edge = widget.edgeToEdge;
    return AnimatedSize(duration: const Duration(milliseconds: 180), child: _hidden ? const SizedBox.shrink() : HBCard(
      padding: EdgeInsets.zero,
      radius: edge ? 0 : (isWide ? AppRadius.cardWeb : AppRadius.cardMobile),
      shadow: edge ? const [] : AppShadows.card,
      hoverable: !edge,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
          child: Row(children: [
             InkWell(onTap: () => context.push(identityPath), child: HBAvatar(name: identityName, imageUrl: identityAvatar, size: 44)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                 Flexible(child: InkWell(onTap: () => context.push(identityPath), child: Text(identityName, maxLines: 1, overflow: TextOverflow.ellipsis, style: appFont(16, FontWeight.w600, color: LightModeColors.text)))),
                 if (page?.isVerified == true) ...[const SizedBox(width: AppSpacing.xs), Tooltip(message: 'pages.verified_tooltip'.tr(), child: const HBBadge(kind: HBBadgeKind.verified))] else if (author.isVerified) ...[const SizedBox(width: AppSpacing.xs), HBBadge.verification(level: author.verificationLevel, verifiedAt: author.verifiedAt)],
                if (_post.group != null) ...[const SizedBox(width: AppSpacing.xs), Flexible(child: InkWell(onTap: () => context.push(AppRoutes.groupDetailPath(_post.group!.slug)), child: Text('▸ ${_post.group!.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))))],
              ]),
                Row(children: [if (page != null) ...[Flexible(child: Text('pages.category.${page.category}'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.withColor(LightModeColors.textSecondary))), Text(' · ', style: AppText.caption.withColor(LightModeColors.textSecondary))] , Flexible(child: InkWell(onTap: _openDetail, child: Text(_post.locationName == null ? relativeDate : '$relativeDate · ${_post.locationName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.withColor(LightModeColors.textSecondary)))), if (_post.visibility == 'group') ...[const SizedBox(width: AppSpacing.xs), Tooltip(message: 'groups.post_members_only'.tr(), child: const Icon(Icons.lock_outline_rounded, size: 14, color: LightModeColors.textSecondary))], if (canBoost) ...[const SizedBox(width: AppSpacing.xs), BoostStatusControl(targetType: 'post', targetId: _post.id)]]),
            ])),
            if (isOwner)
              PopupMenuButton<String>(
                constraints: const BoxConstraints(minWidth: 160), iconSize: 22, padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_horiz_rounded),
                 onSelected: _handleOwnerMenu,
                 itemBuilder: (context) => [if (canBoost) PopupMenuItem(value: 'boost', child: Row(children: [const Icon(Icons.rocket_launch_outlined), const SizedBox(width: AppSpacing.sm), Text('boost.action'.tr())])), PopupMenuItem(value: 'edit', child: Text('post.edit'.tr())), PopupMenuItem(value: 'delete', child: Text('post.delete'.tr()))],
              ),
            if (canDeletePagePost)
              SizedBox(width: 40, height: 40, child: PopupMenuButton<String>(padding: EdgeInsets.zero, icon: const Icon(Icons.more_horiz_rounded), onSelected: _handleOwnerMenu, itemBuilder: (_) => [if (canBoost) PopupMenuItem(value: 'boost', child: Text('boost.action'.tr())), PopupMenuItem(value: 'delete', child: Text('post.delete'.tr()))])),
            if (!isOwner && !canDeletePagePost)
              SizedBox(width: 40, height: 40, child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded), onSelected: _handleOtherMenu,
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'hide', child: Text('safety.hide_post'.tr())),
                  if (page == null) PopupMenuItem(value: 'mute', child: Text('safety.mute_named'.tr(namedArgs: {'name': author.displayName}))),
                  PopupMenuItem(value: 'report', child: Text('safety.report_post'.tr())),
                  if (page == null) PopupMenuItem(value: 'block', child: Text('safety.block_named'.tr(namedArgs: {'name': author.displayName}))),
                ],
              )),
          ]),
        ),
        if (_post.kind == 'checkin' && _post.locationName != null)
          CheckinLocationRow(post: _post),
        if (_post.kind != 'article' && (_post.content?.isNotEmpty ?? false))
          InkWell(onTap: widget.detailMode ? null : _openDetail, child: Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm), child: TranslatableText(type: 'post', id: _post.id, field: 'content', text: _post.content!, richText: true, style: context.textStyles.bodyLarge, maxLines: widget.detailMode ? null : 8))),
        if (_post.dogs.isNotEmpty) PostDogsRow(dogs: _post.dogs),
        if (_post.kind == 'share')
          Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md), child: _post.sharedPost == null ? const SharedPostUnavailable() : SharedPostCard(post: _post.sharedPost!))
         else if (_post.kind == 'reel' && _post.reelVideo != null)
          ReelFeedCard(post: _post)
        else if (_post.kind == 'article' && _post.article != null)
          Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm), child: ArticleFeedCard(article: _post.article!))
        else if (_post.media.isNotEmpty)
          Padding(
            padding: edge ? EdgeInsets.zero : const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: SensitivePostMedia(post: _post, radius: edge ? BorderRadius.zero : BorderRadius.circular(AppRadius.md)),
          ),
        if (_post.kind == 'poll' && widget.poll != null) PollCard(poll: widget.poll!),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
          child: SizedBox(height: 48, child: Row(children: [
            ReactionButton(
              postId: _post.id,
              compact: true,
              initialReaction: _post.myReaction,
              initialCount: _post.reactionCount,
              onToggle: (type) => ref.read(reactionRepositoryProvider).toggle(_post.id, type),
              onChanged: (result) {
                applyOptimisticReaction(ref, _post.id, result.reactionCount);
                setState(() => _post = _post.copyWith(reactionCount: result.reactionCount, myReaction: result.myReaction, clearReaction: result.myReaction == null));
              },
            ),
            PostCountAction(icon: Icons.chat_bubble_outline_rounded, count: _post.commentCount, onTap: widget.detailMode ? null : _openComments),
            PostCountAction(icon: Icons.repeat_rounded, count: _post.shareCount, onTap: () => showShareSheet(context, _post)),
            const Spacer(),
            PostCountAction(icon: Icons.bookmark_border_rounded, label: isWide ? 'feed.save'.tr() : null, onTap: () => showShareSheet(context, _post)),
          ])),
        ),
        if (!widget.detailMode && _post.commentCount > 0 && _post.previewComments.isNotEmpty)
          PostCommentsPreview(comments: _post.previewComments, commentCount: _post.commentCount, onTap: _openComments),
        if (_commentsOpen && !widget.detailMode) ...[
          const Divider(height: 1, color: LightModeColors.lightDivider),
          Padding(padding: const EdgeInsets.all(AppSpacing.md), child: CommentPanel(postId: _post.id, postAuthorId: _post.author.id, maxRootComments: 3, onCountChanged: _commentCountChanged, onCommentCreated: _commentCreated, onViewAll: _openDetail)),
        ],
      ]),
    ));
  }
}

class ReelFeedCard extends StatelessWidget {
  final FeedPost post;
  const ReelFeedCard({super.key, required this.post});
  @override Widget build(BuildContext context) {
    final video = post.reelVideo!;
    return InkWell(onTap: () => context.push(AppRoutes.reelPath(post.id)), child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 420), child: AspectRatio(aspectRatio: 9 / 16, child: Stack(fit: StackFit.expand, children: [
      if (video.thumbnailUrl != null) Image.network(video.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.surfaceSoft)) else const ColoredBox(color: LightModeColors.surfaceSoft),
      const Center(child: Icon(Icons.play_circle_fill_rounded, size: 64, color: Colors.white)),
      Positioned(top: AppSpacing.sm, left: AppSpacing.sm, child: HBBadge.label(label: 'reels.badge'.tr(), emphasized: true)),
      if (video.durationSeconds != null) Positioned(right: AppSpacing.sm, bottom: AppSpacing.sm, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: LightModeColors.overlay, borderRadius: BorderRadius.circular(AppRadius.pill)), child: Text('${video.durationSeconds! ~/ 60}:${(video.durationSeconds! % 60).toString().padLeft(2, '0')}', style: AppText.small.copyWith(color: Colors.white)))),
    ]))));
  }
}

/// PD4 borderless post action: a 22 px monochrome icon with an optional
/// counter or label beside it.
class PostCountAction extends StatelessWidget {
  final IconData icon;
  final int? count;
  final String? label;
  final VoidCallback? onTap;

  const PostCountAction({super.key, required this.icon, this.count, this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.pill),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 22, color: LightModeColors.textSecondary),
        if (count != null && count! > 0) ...[const SizedBox(width: AppSpacing.xs), Text('$count', style: AppText.ui.withColor(LightModeColors.textSecondary))],
        if (label != null) ...[const SizedBox(width: AppSpacing.xs), Text(label!, style: AppText.ui.withColor(LightModeColors.textSecondary))],
      ]),
    ),
  );
}

/// Compact, full-width action used in the post action bar (comment, share).
/// The icon and the label shrink gracefully instead of being truncated to
/// "Comm…" on narrow phones.
class PostActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const PostActionButton({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 18, color: LightModeColors.lightPrimary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelMedium?.withColor(LightModeColors.lightPrimary))),
      ]),
    ),
  );
}

class PostCommentsPreview extends StatelessWidget {
  final List<Comment> comments;
  final int commentCount;
  final VoidCallback onTap;

  const PostCommentsPreview({super.key, required this.comments, required this.commentCount, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (commentCount > 2) InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Text('comments.view_all_count'.plural(commentCount), style: context.textStyles.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: LightModeColors.lightOnSurfaceVariant))),
      ),
      for (final comment in comments.take(2)) PostCommentPreviewRow(comment: comment, onTap: onTap),
    ]),
  );
}

class PostCommentPreviewRow extends StatelessWidget {
  final Comment comment;
  final VoidCallback onTap;

  const PostCommentPreviewRow({super.key, required this.comment, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HBAvatar(name: comment.author.displayName, imageUrl: comment.author.avatarUrl, size: 28),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(comment.author.displayName, style: const TextStyle(fontWeight: FontWeight.w700)), TranslatableText(type: 'comment', id: comment.id, field: 'content', text: comment.content, richText: true, maxLines: 2)])),
        if (comment.reactionCount > 0) ...[
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.favorite_rounded, size: 15, color: LightModeColors.lightError),
          const SizedBox(width: 2),
          Text('${comment.reactionCount}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
        ],
      ]),
    ),
  );
}

class CheckinLocationRow extends StatelessWidget {
  final FeedPost post;

  const CheckinLocationRow({super.key, required this.post});

  Future<void> _openMap(BuildContext context) async {
    if (post.latitude == null || post.longitude == null) return;
    final confirmed = await showDialog<bool>(context: context, builder: (_) => const ExternalMapDialog()) ?? false;
    if (!confirmed) return;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${post.latitude},${post.longitude}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final unit = post.huntingUnit?.name;
    return InkWell(
      onTap: post.latitude == null || post.longitude == null ? null : () => _openMap(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
        child: Row(children: [
          const Icon(Icons.location_on_rounded, size: 18, color: LightModeColors.lightForest),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(unit == null ? post.locationName! : '${post.locationName} · $unit', maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: LightModeColors.lightForest))),
          if (post.latitude != null && post.longitude != null) const Icon(Icons.open_in_new_rounded, size: 16, color: LightModeColors.lightForest),
        ]),
      ),
    );
  }
}

class ExternalMapDialog extends StatelessWidget {
  const ExternalMapDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('checkin.open_map_title'.tr()),
    content: Text('checkin.open_map_message'.tr()),
    actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop(false)), HBButton.primary(label: 'checkin.open_map'.tr(), onPressed: () => context.pop(true))],
  );
}

class ReactionSummaryIcons extends StatelessWidget {
  final List<ReactionSummary> summary;

  const ReactionSummaryIcons({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final visible = summary.take(3).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 16 + (visible.length - 1) * 10,
      height: 18,
      child: Stack(children: [
        for (var index = 0; index < visible.length; index++) Positioned(left: index * 10, child: Icon(visible[index].type.icon, size: 16, color: visible[index].type.color)),
      ]),
    );
  }
}

class SharedPostCard extends StatelessWidget {
  final FeedPost post;

  const SharedPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push(AppRoutes.postPath(post.id)),
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(border: Border.all(color: LightModeColors.lightBorder), borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [HBAvatar(name: post.page?.name ?? post.author.displayName, imageUrl: post.page?.avatarUrl ?? post.author.avatarUrl, size: 32), const SizedBox(width: AppSpacing.sm), Expanded(child: Row(children: [Flexible(child: Text(post.page?.name ?? post.author.displayName, style: const TextStyle(fontWeight: FontWeight.w700))), if (post.page?.isVerified == true) ...[const SizedBox(width: AppSpacing.xs), const HBBadge(kind: HBBadgeKind.verified)]])), Text(relativeTime(context, post.createdAt), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]),
        if (post.content?.isNotEmpty ?? false) ...[const SizedBox(height: AppSpacing.sm), HBRichText(text: post.content!, maxLines: 4, overflow: TextOverflow.ellipsis)],
        if (post.media.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), SensitivePostMedia(post: post)],
      ]),
    ),
  );
}

class SharedPostUnavailable extends StatelessWidget {
  const SharedPostUnavailable({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
    child: Text('share.unavailable'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
  );
}

class PostDogsRow extends StatelessWidget {
  final List<FeedDog> dogs;
  const PostDogsRow({super.key, required this.dogs});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm), child: Row(children: [SizedBox(width: 26 + (dogs.length - 1).clamp(0, 2) * 18, height: 28, child: Stack(children: [for (var index = 0; index < dogs.take(3).length; index++) Positioned(left: index * 18, child: InkWell(onTap: () => context.push(AppRoutes.dogDetailPath(dogs[index].id)), child: HBAvatar(name: dogs[index].name, imageUrl: dogs[index].avatarUrl, size: 26, ringColor: LightModeColors.lightSurface)))])), const SizedBox(width: AppSpacing.sm), Expanded(child: Wrap(children: [Text('dogs.tags.with'.tr()), for (var index = 0; index < dogs.length; index++) InkWell(onTap: () => context.push(AppRoutes.dogDetailPath(dogs[index].id)), child: Text('${index == 0 ? '' : index == dogs.length - 1 ? ' ${'dogs.tags.and'.tr()} ' : ', '}${dogs[index].name}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightPrimary))) ]))]));
}

class EditPostDialog extends ConsumerStatefulWidget {
  final String initialContent;
  final Set<String> initialDogIds;

  const EditPostDialog({super.key, required this.initialContent, required this.initialDogIds});

  @override
  ConsumerState<EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends ConsumerState<EditPostDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialContent);
  late Set<String> dogIds = {...widget.initialDogIds};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('post.edit_title'.tr()),
    content: SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: [HBInput(controller: _controller, maxLines: 7, maxLength: 5000, hint: 'post_composer.hint'.tr()), const SizedBox(height: AppSpacing.sm), Align(alignment: Alignment.centerLeft, child: HBButton.soft(label: dogIds.isEmpty ? 'dogs.tags.action'.tr() : 'dogs.tags.selected'.tr(namedArgs: {'count': '${dogIds.length}'}), icon: Icons.pets_outlined, onPressed: () async { final dogs = (ref.read(myDogsProvider).value ?? const <Dog>[]).where((dog) => dog.status == DogStatus.active).toList(); final value = await showModalBottomSheet<Set<String>>(context: context, useSafeArea: true, showDragHandle: true, builder: (_) => DogTagSelector(dogs: dogs, selectedIds: dogIds)); if (value != null && mounted) setState(() => dogIds = value); }))])),
    actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop()), HBButton.primary(label: 'common.save'.tr(), onPressed: () => context.pop((content: _controller.text, dogIds: dogIds)))],
  );
}

class DeletePostDialog extends StatelessWidget {
  const DeletePostDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('post.delete_title'.tr()),
    content: Text('post.delete_message'.tr()),
    actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop(false)), HBButton.primary(label: 'post.delete_confirm'.tr(), onPressed: () => context.pop(true))],
  );
}