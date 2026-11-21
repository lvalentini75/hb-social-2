import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/services/realtime_service.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_rich_text.dart';
import 'package:hb_social/core/widgets/translatable_text.dart';
import 'package:hb_social/core/providers/translation_providers.dart';
import 'package:hb_social/features/comments/domain/post_comment.dart';
import 'package:hb_social/features/comments/providers/comments_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/profile/providers/public_profile_providers.dart';
import 'package:hb_social/features/home/providers/feed_providers.dart';
import 'package:hb_social/features/safety/presentation/report_sheet.dart';
import 'package:hb_social/features/safety/presentation/safety_confirmations.dart';
import 'package:hb_social/features/safety/providers/safety_providers.dart';
import 'package:hb_social/features/social_graph/providers/social_graph_providers.dart';
import 'package:hb_social/features/stories/providers/story_providers.dart';
import 'package:hb_social/features/gifs/presentation/gif_picker.dart';
import 'package:hb_social/features/gifs/providers/gifs_providers.dart';

class CommentPanel extends StatefulWidget {
  final String postId;
  final String postAuthorId;
  final int? maxRootComments;
  final String? highlightCommentId;
  final ValueChanged<int>? onCountChanged;
  final ValueChanged<Comment>? onCommentCreated;
  final VoidCallback? onViewAll;
  final bool fixedComposer;

  const CommentPanel({super.key, required this.postId, required this.postAuthorId, this.maxRootComments, this.highlightCommentId, this.onCountChanged, this.onCommentCreated, this.onViewAll, this.fixedComposer = false});

  @override
  State<CommentPanel> createState() => _CommentPanelState();
}

class _CommentPanelState extends State<CommentPanel> {
  CommentReplyTarget? _replyTarget;

  @override
  Widget build(BuildContext context) {
    final thread = CommentThread(
      postId: widget.postId, postAuthorId: widget.postAuthorId, maxRootComments: widget.maxRootComments,
      highlightCommentId: widget.highlightCommentId,
      onReply: (target) => setState(() => _replyTarget = target), onCountChanged: widget.onCountChanged,
    );
    final composer = CommentComposer(
      postId: widget.postId, replyTarget: _replyTarget,
      onCancelReply: () => setState(() => _replyTarget = null),
      onCreated: (comment) {
        setState(() => _replyTarget = null);
        if (widget.onCommentCreated != null) widget.onCommentCreated!(comment); else widget.onCountChanged?.call(1);
      },
    );
    if (widget.fixedComposer) return Column(children: [Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.md), child: thread)), const Divider(height: 1, color: LightModeColors.lightDivider), Padding(padding: const EdgeInsets.all(AppSpacing.md), child: composer)]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [thread, if (widget.onViewAll != null) Align(alignment: Alignment.centerLeft, child: HBButton.ghost(label: 'comments.view_all'.tr(), onPressed: widget.onViewAll, size: HBButtonSize.sm)), const SizedBox(height: AppSpacing.sm), composer]);
  }
}

class CommentThread extends ConsumerStatefulWidget {
  final String postId;
  final String postAuthorId;
  final int? maxRootComments;
  final String? highlightCommentId;
  final ValueChanged<CommentReplyTarget> onReply;
  final ValueChanged<int>? onCountChanged;

  const CommentThread({super.key, required this.postId, required this.postAuthorId, required this.onReply, this.maxRootComments, this.highlightCommentId, this.onCountChanged});

  @override
  ConsumerState<CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends ConsumerState<CommentThread> {
  final Map<String, GlobalKey> _keys = {};
  bool _highlighted = false;
  StreamSubscription<CommentRealtimeEvent>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _realtimeSubscription = ref.read(realtimeServiceProvider).openComments(widget.postId).listen((event) async {
      final notifier = ref.read(postCommentsProvider(widget.postId).notifier);
      if (event.deleted) {
        notifier.deleteRealtime(event.id);
      } else {
        try { await notifier.insertRealtime(event.id); } catch (_) {}
      }
    });
    if (widget.highlightCommentId != null) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    ref.read(realtimeServiceProvider).closeComments(widget.postId);
    super.dispose();
  }

  Future<void> _reveal() async {
    try {
      await ref.read(postCommentsProvider(widget.postId).notifier).reveal(widget.highlightCommentId!);
      if (!mounted) return;
      setState(() => _highlighted = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _keys[widget.highlightCommentId!]?.currentContext;
        if (context != null) Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 300), alignment: 0.3);
      });
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _highlighted = false);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => ref.watch(postCommentsProvider(widget.postId)).when(
    loading: () => const HBListSkeleton(count: 3, showTrailing: false),
    error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'comments.error_title'.tr(), message: 'comments.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(postCommentsProvider(widget.postId))))),
    data: (page) {
      final blocked = ref.watch(locallyBlockedUserIdsProvider);
      final visibleItems = page.items.where((comment) => !blocked.contains(comment.authorId)).map((comment) => comment.copyWith(replies: comment.replies.where((reply) => !blocked.contains(reply.authorId)).toList())).toList();
      if (visibleItems.isEmpty) return HBEmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'comments.empty_title'.tr(), message: 'comments.empty_message'.tr());
      final items = widget.maxRootComments == null ? visibleItems : visibleItems.take(widget.maxRootComments!).toList();
      return Column(children: [
        for (final comment in items) CommentTile(
          key: _keys.putIfAbsent(comment.id, GlobalKey.new), comment: comment, postId: widget.postId,
          postAuthorId: widget.postAuthorId, highlighted: _highlighted && widget.highlightCommentId == comment.id,
          onReply: widget.onReply, onCountChanged: widget.onCountChanged,
          replyKey: (id) => _keys.putIfAbsent(id, GlobalKey.new), highlightCommentId: widget.highlightCommentId,
        ),
        if (widget.maxRootComments == null && page.hasMore) Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: HBButton.secondary(label: 'comments.load_more'.tr(), onPressed: page.isLoadingMore ? null : () => ref.read(postCommentsProvider(widget.postId).notifier).loadMore(), isLoading: page.isLoadingMore),
        ),
      ]);
    },
  );
}

class CommentTile extends ConsumerStatefulWidget {
  final Comment comment;
  final String postId;
  final String postAuthorId;
  final bool highlighted;
  final String? highlightCommentId;
  final ValueChanged<CommentReplyTarget> onReply;
  final ValueChanged<int>? onCountChanged;
  final Key Function(String) replyKey;

  const CommentTile({super.key, required this.comment, required this.postId, required this.postAuthorId, required this.highlighted, required this.onReply, required this.replyKey, this.highlightCommentId, this.onCountChanged});

  @override
  ConsumerState<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<CommentTile> {

  Future<void> _toggleLike(BuildContext context, WidgetRef ref, Comment comment) async {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) { context.push(AppRoutes.login); return; }
    final optimisticLiked = !comment.myLike;
    final optimisticCount = (comment.reactionCount + (optimisticLiked ? 1 : -1)).clamp(0, 1 << 30);
    final notifier = ref.read(postCommentsProvider(widget.postId).notifier);
    notifier.applyLike(comment.id, optimisticLiked, optimisticCount);
    try {
      final result = await ref.read(commentsRepositoryProvider).toggleLike(comment.id);
      notifier.applyLike(comment.id, result.liked, result.likeCount);
    } on AppException catch (error) {
      notifier.applyLike(comment.id, comment.myLike, comment.reactionCount);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Comment comment) async {
    final content = await showDialog<String>(context: context, builder: (_) => CommentEditDialog(content: comment.content));
    if (content == null || !context.mounted) return;
    try { await ref.read(postCommentsProvider(widget.postId).notifier).updateComment(comment.id, content); ref.read(translationServiceProvider).invalidate('comment', comment.id); }
    on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs)))); }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Comment comment) async {
    final confirmed = await showDialog<bool>(context: context, builder: (_) => const CommentDeleteDialog()) ?? false;
    if (!confirmed || !context.mounted) return;
    try {
      final delta = await ref.read(postCommentsProvider(widget.postId).notifier).deleteComment(comment);
      widget.onCountChanged?.call(delta);
    } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs)))); }
  }

  Future<void> _report(Comment comment) async {
    if (ref.read(supabaseClientProvider).auth.currentUser == null) { context.push(AppRoutes.login); return; }
    if (await showReportSheet(context, targetType: 'comment', targetId: comment.id) && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('safety.report_success'.tr())));
  }

  Future<void> _block(Comment comment) async {
    if (ref.read(supabaseClientProvider).auth.currentUser == null) { context.push(AppRoutes.login); return; }
    if (!await showBlockConfirmation(context, comment.author.displayName) || !mounted) return;
    try {
      await ref.read(safetyRepositoryProvider).blockUser(comment.authorId);
      ref.read(locallyBlockedUserIdsProvider.notifier).state = {...ref.read(locallyBlockedUserIdsProvider), comment.authorId};
      ref.read(postCommentsProvider(widget.postId).notifier).removeAuthor(comment.authorId);
      removeAuthorFromFeeds(ref, comment.authorId);
      ref.invalidate(relationshipProvider(comment.authorId));
      ref.invalidate(peopleSuggestionsProvider);
      ref.invalidate(connectionsProvider);
      ref.invalidate(currentProfileProvider);
      ref.invalidate(publicProfileProvider(comment.author.username));
      ref.invalidate(storyTrayProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('safety.user_blocked'.tr())));
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final canDelete = userId == widget.comment.authorId || userId == widget.postAuthorId;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm), padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: widget.highlighted ? LightModeColors.lightPrimarySoft : Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Column(children: [
        CommentRow(
          comment: widget.comment, canEdit: userId == widget.comment.authorId, canDelete: canDelete,
          onLike: () => _toggleLike(context, ref, widget.comment),
          onReply: () => widget.onReply(CommentReplyTarget(parentId: widget.comment.id, username: widget.comment.author.username)),
          onEdit: () => _edit(context, ref, widget.comment), onDelete: () => _delete(context, ref, widget.comment),
          canSafety: userId != widget.comment.authorId, onReport: () => _report(widget.comment), onBlock: () => _block(widget.comment),
        ),
        if (widget.comment.replies.isNotEmpty) Padding(
          padding: const EdgeInsets.only(left: 44, top: AppSpacing.sm),
          child: Column(children: [for (final reply in widget.comment.replies) Container(
            key: widget.replyKey(reply.id),
            decoration: BoxDecoration(color: widget.highlightCommentId == reply.id ? LightModeColors.lightPrimarySoft : Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.sm)),
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: CommentRow(
              comment: reply, canEdit: userId == reply.authorId, canDelete: userId == reply.authorId || userId == widget.postAuthorId,
              onLike: () => _toggleLike(context, ref, reply),
              onReply: () => widget.onReply(CommentReplyTarget(parentId: widget.comment.id, username: reply.author.username, prefix: '@${reply.author.username} ')),
              onEdit: () => _edit(context, ref, reply), onDelete: () => _delete(context, ref, reply),
              canSafety: userId != reply.authorId, onReport: () => _report(reply), onBlock: () => _block(reply),
            ),
          )]),
        ),
        if (widget.comment.replyCount > widget.comment.replies.length) Align(
          alignment: Alignment.centerLeft,
          child: Padding(padding: const EdgeInsets.only(left: 44), child: HBButton.ghost(
            label: 'comments.view_more_replies'.tr(namedArgs: {'n': '${widget.comment.replyCount - widget.comment.replies.length}'}),
            onPressed: () => ref.read(postCommentsProvider(widget.postId).notifier).loadReplies(widget.comment.id), size: HBButtonSize.sm,
          )),
        ),
      ]),
    );
  }
}

class CommentRow extends StatefulWidget {
  final Comment comment;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canSafety;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  const CommentRow({super.key, required this.comment, required this.canEdit, required this.canDelete, required this.onLike, required this.onReply, required this.onEdit, required this.onDelete, required this.canSafety, required this.onReport, required this.onBlock});

  @override
  State<CommentRow> createState() => _CommentRowState();
}

class _CommentRowState extends State<CommentRow> {
  bool _hovered = false;

  Future<void> _mobileMenu() async {
    if (!widget.canSafety || kIsWeb) return;
    final value = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.flag_outlined), title: Text('safety.report_comment'.tr()), onTap: () => sheetContext.pop('report')),
      ListTile(leading: const Icon(Icons.block_rounded), title: Text('safety.block_named'.tr(namedArgs: {'name': widget.comment.author.displayName})), onTap: () => sheetContext.pop('block')),
    ])));
    if (value == 'report') widget.onReport();
    if (value == 'block') widget.onBlock();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(onEnter: (_) => setState(() => _hovered = true), onExit: (_) => setState(() => _hovered = false), child: GestureDetector(onLongPress: _mobileMenu, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    HBAvatar(name: widget.comment.author.displayName, imageUrl: widget.comment.author.avatarUrl, size: 36, onTap: () => context.push(AppRoutes.publicProfilePath(widget.comment.author.username))),
    const SizedBox(width: AppSpacing.sm),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Flexible(child: Text(widget.comment.author.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w700))), if (widget.comment.author.isVerified) ...[const SizedBox(width: 4), HBBadge.verification(level: widget.comment.author.verificationLevel, verifiedAt: widget.comment.author.verifiedAt)], const Spacer(), Text(relativeTime(context, widget.comment.createdAt), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]),
      if (widget.comment.content.isNotEmpty) ...[const SizedBox(height: AppSpacing.xs), TranslatableText(type: 'comment', id: widget.comment.id, field: 'content', text: widget.comment.content, richText: true)],
      if (widget.comment.gifUrl != null) ...[const SizedBox(height: AppSpacing.xs), GifImage(url: widget.comment.gifUrl!, width: 260, height: 180)],
      Wrap(children: [
        HBButton.ghost(label: widget.comment.reactionCount > 0 ? '${'comments.like'.tr()} ${widget.comment.reactionCount}' : 'comments.like'.tr(), icon: widget.comment.myLike ? Icons.favorite_rounded : Icons.favorite_border_rounded, foregroundColor: widget.comment.myLike ? LightModeColors.lightError : null, onPressed: widget.onLike, size: HBButtonSize.sm),
        HBButton.ghost(label: 'comments.reply'.tr(), onPressed: widget.onReply, size: HBButtonSize.sm),
      ]),
    ])),
    if (widget.canEdit || widget.canDelete || kIsWeb && widget.canSafety && _hovered) SizedBox(width: 36, height: 36, child: PopupMenuButton<String>(
      padding: EdgeInsets.zero, icon: const Icon(Icons.more_horiz_rounded, size: 20),
      onSelected: (value) { if (value == 'edit') widget.onEdit(); if (value == 'delete') widget.onDelete(); if (value == 'report') widget.onReport(); if (value == 'block') widget.onBlock(); },
      itemBuilder: (_) => [if (widget.canEdit) PopupMenuItem(value: 'edit', child: Text('comments.edit'.tr())), if (widget.canDelete) PopupMenuItem(value: 'delete', child: Text('comments.delete'.tr())), if (widget.canSafety) PopupMenuItem(value: 'report', child: Text('safety.report_comment'.tr())), if (widget.canSafety) PopupMenuItem(value: 'block', child: Text('safety.block_named'.tr(namedArgs: {'name': widget.comment.author.displayName})))],
    )),
  ])));
}

class CommentReplyTarget {
  final String parentId;
  final String username;
  final String prefix;
  const CommentReplyTarget({required this.parentId, required this.username, this.prefix = ''});
}

class CommentComposer extends ConsumerStatefulWidget {
  final String postId;
  final CommentReplyTarget? replyTarget;
  final VoidCallback onCancelReply;
  final ValueChanged<Comment> onCreated;

  const CommentComposer({super.key, required this.postId, required this.replyTarget, required this.onCancelReply, required this.onCreated});

  @override
  ConsumerState<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends ConsumerState<CommentComposer> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<PostAuthor> _suggestions = const [];
  String? _mentionFragment;
  bool _sending = false;
  String? _errorKey;

  @override
  void didUpdateWidget(covariant CommentComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replyTarget != oldWidget.replyTarget && widget.replyTarget?.prefix.isNotEmpty == true) {
      _controller.text = widget.replyTarget!.prefix;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  void _changed(String value) {
    setState(() => _errorKey = null);
    _debounce?.cancel();
    final beforeCursor = value.substring(0, _controller.selection.baseOffset.clamp(0, value.length));
    final match = RegExp(r'(?:^|\s)@([A-Za-z0-9_]{2,30})$').firstMatch(beforeCursor);
    if (match == null) { setState(() { _suggestions = const []; _mentionFragment = null; }); return; }
    _mentionFragment = match.group(1)!;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final result = await ref.read(commentsRepositoryProvider).searchMentions(_mentionFragment!);
        if (mounted) setState(() => _suggestions = result);
      } catch (_) {}
    });
  }

  void _insertMention(PostAuthor author) {
    final selection = _controller.selection.baseOffset.clamp(0, _controller.text.length);
    final before = _controller.text.substring(0, selection);
    final start = before.lastIndexOf('@${_mentionFragment!}');
    final text = '${_controller.text.substring(0, start)}@${author.username} ${_controller.text.substring(selection)}';
    _controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: start + author.username.length + 2));
    setState(() { _suggestions = const []; _mentionFragment = null; });
  }

  Future<void> _send() async {
    if (_sending || _controller.text.trim().isEmpty) return;
    setState(() { _sending = true; _errorKey = null; });
    try {
      final comment = await ref.read(postCommentsProvider(widget.postId).notifier).create(_controller.text, parentId: widget.replyTarget?.parentId);
      _controller.clear();
      widget.onCreated(comment);
    } on AppException catch (error) {
      if (mounted) setState(() => _errorKey = error.messageKey);
    } finally { if (mounted) setState(() => _sending = false); }
  }

  Future<void> _sendGif() async {
    if (_sending) return;
    final gif = await showGifPicker(context);
    if (gif == null || !mounted) return;
    setState(() { _sending = true; _errorKey = null; });
    try {
      await ref.read(gifsRepositoryProvider).share(gif.onsent);
      final comment = await ref.read(postCommentsProvider(widget.postId).notifier).createGif(gif.url, content: _controller.text, parentId: widget.replyTarget?.parentId);
      _controller.clear();
      widget.onCreated(comment);
    } on AppException catch (error) { if (mounted) setState(() => _errorKey = error.messageKey); }
    finally { if (mounted) setState(() => _sending = false); }
  }

  @override
  void dispose() { _debounce?.cancel(); _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    if (ref.watch(supabaseClientProvider).auth.currentUser == null) return Row(children: [Expanded(child: Text('comments.guest_message'.tr())), HBButton.soft(label: 'comments.guest_cta'.tr(), onPressed: () => context.push(AppRoutes.login), size: HBButtonSize.sm)]);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.replyTarget != null) Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: InputChip(label: Text('comments.replying_to'.tr(namedArgs: {'username': widget.replyTarget!.username})), onDeleted: widget.onCancelReply, backgroundColor: LightModeColors.lightPrimarySoft, side: BorderSide.none),
      ),
      if (_suggestions.isNotEmpty) HBCard(
        padding: const EdgeInsets.all(AppSpacing.sm), radius: AppRadius.sm,
        child: Column(children: [for (final author in _suggestions) ListTile(leading: HBAvatar(name: author.displayName, imageUrl: author.avatarUrl, size: 32), title: Text(author.displayName), subtitle: Text('@${author.username}'), onTap: () => _insertMention(author))]),
      ),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        HBAvatar(name: profile?.displayName, imageUrl: profile?.avatarUrl, size: 36), const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          HBInput(controller: _controller, hint: 'comments.hint'.tr(), maxLines: 3, maxLength: 2000, onChanged: _changed),
          if (_errorKey != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text(_errorKey!.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))),
          if (_controller.text.length > 1800) Text('${_controller.text.length}/2000', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
        ])),
        if (ref.watch(gifsAvailableProvider).value == true) ...[const SizedBox(width: AppSpacing.xs), HBButton.ghost(label: 'gifs.button'.tr(), onPressed: _sending ? null : _sendGif, size: HBButtonSize.sm)],
        const SizedBox(width: AppSpacing.xs),
        HBButton.icon(icon: _sending ? Icons.hourglass_top_rounded : Icons.send_rounded, onPressed: _sending || _controller.text.trim().isEmpty ? null : _send, backgroundColor: LightModeColors.lightPrimary, foregroundColor: Colors.white),
      ]),
    ]);
  }
}

class CommentEditDialog extends StatefulWidget {
  final String content;
  const CommentEditDialog({super.key, required this.content});
  @override
  State<CommentEditDialog> createState() => _CommentEditDialogState();
}

class _CommentEditDialogState extends State<CommentEditDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.content);
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('comments.edit_title'.tr()), content: SizedBox(width: 480, child: HBInput(controller: _controller, maxLines: 5, maxLength: 2000)),
    actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop()), HBButton.primary(label: 'common.save'.tr(), onPressed: () => context.pop(_controller.text))],
  );
}

class CommentDeleteDialog extends StatelessWidget {
  const CommentDeleteDialog({super.key});
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('comments.delete_title'.tr()), content: Text('comments.delete_message'.tr()),
    actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop(false)), HBButton.primary(label: 'comments.delete_confirm'.tr(), onPressed: () => context.pop(true))],
  );
}