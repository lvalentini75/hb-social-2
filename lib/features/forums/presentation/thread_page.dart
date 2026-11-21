import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/services/realtime_service.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_rich_text.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/forums/domain/forum.dart';
import 'package:hb_social/features/forums/domain/forum_reply.dart';
import 'package:hb_social/features/forums/domain/forum_thread.dart';
import 'package:hb_social/features/forums/presentation/forum_breadcrumb.dart';
import 'package:hb_social/features/forums/presentation/thread_moderation_menu.dart';
import 'package:hb_social/features/forums/providers/forums_providers.dart';
import 'package:hb_social/features/forums/presentation/forum_attachments.dart';
import 'package:hb_social/features/forums/presentation/forum_composer_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';

class ThreadPage extends ConsumerStatefulWidget {
  final String slug;
  final String threadId;
  final String? replyId;
  const ThreadPage({super.key, required this.slug, required this.threadId, this.replyId});

  @override
  ConsumerState<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends ConsumerState<ThreadPage> {
  final _reply = TextEditingController();
  final Map<String, GlobalKey> _replyKeys = {};
  String? _replyingTo;
  String? _highlighted;
  bool _sending = false;
  bool _didScroll = false;
  bool? _subscribed;
  final List<PreparedUpload> _files = [];
  double? _progress;
  StreamSubscription<ForumRealtimeEvent>? _realtime;
  ForumThread? _liveThread;

  @override
  void initState() { super.initState(); Future.microtask(() async { ref.read(forumsRepositoryProvider).touchView(widget.threadId); _subscribed = await ref.read(forumsRepositoryProvider).isThreadSubscribed(widget.threadId); if (mounted) setState(() {}); }); _realtime = ref.read(realtimeServiceProvider).openForumThread(widget.threadId).listen(_onRealtime); }
  @override
  void dispose() { _realtime?.cancel(); ref.read(realtimeServiceProvider).closeForumThread(widget.threadId); _reply.dispose(); super.dispose(); }

  Future<void> _onRealtime(ForumRealtimeEvent event) async {
    if (!mounted) return;
    if (event.table == 'forum_threads') {
      final current = _liveThread ?? ref.read(threadDetailProvider(widget.threadId)).value;
      if (current != null) setState(() => _liveThread = current.copyWith(replyCount: (event.record['reply_count'] as num?)?.toInt(), viewCount: (event.record['view_count'] as num?)?.toInt(), isLocked: event.record['is_locked'] as bool?, isPinned: event.record['is_pinned'] as bool?, solutionReplyId: event.record['solution_reply_id'] as String?, clearSolution: event.record['solution_reply_id'] == null));
      return;
    }
    final id = event.record['id']?.toString(); if (id == null) return;
    if (event.event == PostgresChangeEvent.delete) { ref.read(repliesProvider(widget.threadId).notifier).remove(id); return; }
    final existing = ref.read(repliesProvider(widget.threadId)).value?.items.any((item) => item.id == id) ?? false;
    try { final reply = await ref.read(forumsRepositoryProvider).getReply(id); if (event.event == PostgresChangeEvent.insert && !existing) ref.read(repliesProvider(widget.threadId).notifier).insert(reply); else ref.read(repliesProvider(widget.threadId).notifier).replaceReply(reply, canManage: ref.read(forumDetailProvider(widget.slug)).value?.myMembership?.canManage == true); } catch (_) {}
  }

  void _error(AppException error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs)))); }

  Future<void> _send({String? parentId}) async {
    if ((_reply.text.trim().isEmpty && _files.isEmpty) || _reply.text.trim().length > 5000 || _sending) return;
    setState(() => _sending = true);
    try {
      final attachments = await _uploadAttachments();
      final reply = await ref.read(forumsRepositoryProvider).createReply(threadId: widget.threadId, content: _reply.text, parentId: parentId, attachments: attachments);
      ref.read(repliesProvider(widget.threadId).notifier).insert(reply);
      ref.invalidate(threadDetailProvider(widget.threadId));
      _reply.clear();
      _files.clear(); _progress = null;
      if (mounted) setState(() => _replyingTo = null);
    } on AppException catch (error) { _error(error); } finally { if (mounted) setState(() => _sending = false); }
  }

  Future<List<Map<String, dynamic>>> _uploadAttachments() async {
    final service = ref.read(mediaUploadServiceProvider); final userId = ref.read(authSessionProvider).value!.user.id;
    final result = <Map<String, dynamic>>[]; var completed = 0;
    for (final file in _files) {
      String? thumbnailPath; if (file.poster != null) thumbnailPath = (await service.uploadPoster(bucket: 'forum-media', bytes: file.poster!.bytes)).path;
      final progress = UploadProgress(); final subscription = progress.stream.listen((value) { if (mounted) setState(() => _progress = (completed + value) / _files.length); });
      final uploaded = await service.uploadToBucket(bucket: 'forum-media', userId: userId, upload: file, isPublic: true, progress: progress); await subscription.cancel(); await progress.close(); completed++;
      result.add({'path': uploaded.path, 'kind': file.mediaKind, 'mime_type': file.contentType, 'size_bytes': file.bytes.length, 'file_name': file.fileName, 'width': file.width, 'height': file.height, 'duration_ms': file.durationMs, 'thumbnail_path': thumbnailPath});
    }
    return result;
  }

  Future<void> _pickAttachments() async { try { final files = await ref.read(mediaUploadServiceProvider).pickForumAttachments(remaining: 6 - _files.length); if (mounted) setState(() => _files.addAll(files)); } on AppException catch (error) { _error(error); } }

  Future<void> _toggleSubscription() async { try { final value = await ref.read(forumsRepositoryProvider).subscribeThread(widget.threadId, !(_subscribed ?? false)); if (mounted) setState(() => _subscribed = value); } on AppException catch (error) { _error(error); } }

  Future<void> _toggleLike(ForumReply reply) async {
    final optimistic = !reply.myLike; final count = (reply.reactionCount + (optimistic ? 1 : -1)).clamp(0, 1 << 30);
    ref.read(repliesProvider(widget.threadId).notifier).updateLike(reply.id, optimistic, count);
    try { final result = await ref.read(forumsRepositoryProvider).toggleReplyLike(reply.id); ref.read(repliesProvider(widget.threadId).notifier).updateLike(reply.id, result.liked, result.count); } on AppException catch (error) { ref.read(repliesProvider(widget.threadId).notifier).updateLike(reply.id, reply.myLike, reply.reactionCount); _error(error); }
  }

  Future<void> _markSolution(String? replyId) async {
    try { await ref.read(forumsRepositoryProvider).markSolution(widget.threadId, replyId); ref.invalidate(threadDetailProvider(widget.threadId)); } on AppException catch (error) { _error(error); }
  }

  Future<void> _delete(ForumReply reply) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('forums.reply.delete_title'.tr()), content: Text('forums.reply.delete_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'forums.reply.delete'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
    if (!confirmed) return;
    try { await ref.read(forumsRepositoryProvider).deleteReply(reply.id); ref.invalidate(repliesProvider(widget.threadId)); ref.invalidate(threadDetailProvider(widget.threadId)); } on AppException catch (error) { _error(error); }
  }

  Future<void> _editReply(ForumReply reply) async {
    final content = await showDialog<String>(context: context, builder: (_) => ForumTextEditDialog(titleKey: 'forums.reply.edit', initialText: reply.content, maxLength: 5000));
    if (content == null) return;
    try { await ref.read(forumsRepositoryProvider).updateReply(reply.id, content); ref.invalidate(repliesProvider(widget.threadId)); } on AppException catch (error) { _error(error); }
  }

  Future<void> _moderate(ForumThread thread, String action) async {
    final repository = ref.read(forumsRepositoryProvider);
    try {
      if (action == 'pin') await repository.setThreadPinned(thread.id, !thread.isPinned);
      if (action == 'lock') await repository.setThreadLocked(thread.id, !thread.isLocked);
      if (action == 'status') await repository.setThreadStatus(thread.id, thread.status == 'hidden' ? 'published' : 'hidden');
      if (action == 'delete') {
        final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('forum_studio.thread.delete_title'.tr()), content: Text('forum_studio.thread.delete_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'forum_studio.thread.delete'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
        if (!confirmed) return;
        await repository.deleteThread(thread.id);
        if (mounted) { ref.invalidate(threadsProvider(thread.forumId)); context.go(AppRoutes.forumDetailPath(widget.slug)); }
        return;
      }
      ref.invalidate(threadDetailProvider(thread.id));
      ref.invalidate(threadsProvider(thread.forumId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('forum_studio.thread.updated'.tr())));
    } on AppException catch (error) { _error(error); }
  }

  void _scrollTo(String id) {
    final target = _replyKeys[id]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 300), alignment: 0.2);
    setState(() => _highlighted = id);
    Timer(const Duration(seconds: 2), () { if (mounted && _highlighted == id) setState(() => _highlighted = null); });
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(threadDetailProvider(widget.threadId));
    final forumAsync = ref.watch(forumDetailProvider(widget.slug));
    return threadAsync.when(
      loading: () => const PageColumns(center: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: HBListSkeleton())),
      error: (_, __) => PageColumns(center: ThreadError(onRetry: () => ref.invalidate(threadDetailProvider(widget.threadId)))),
      data: (loadedThread) {
        final thread = _liveThread ?? loadedThread;
        if (thread == null) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.forum_outlined, title: 'forums.thread_not_found_title'.tr(), message: 'forums.not_found_message'.tr())));
        final forum = forumAsync.value;
        final userId = ref.watch(authSessionProvider).value?.user.id;
        final isMember = forum?.myMembership?.isActive == true;
        final canManage = forum?.myMembership?.canManage == true;
        final canSolve = userId == thread.authorId || canManage;
        final replies = ref.watch(repliesProvider(thread.id));
        final solution = replies.value?.items.where((item) => item.id == thread.solutionReplyId).firstOrNull;
        if (!_didScroll && widget.replyId != null && replies.hasValue) {
          _didScroll = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(widget.replyId!));
        }
        return PageColumns(center: RefreshIndicator(onRefresh: () async { ref.invalidate(threadDetailProvider(thread.id)); ref.invalidate(repliesProvider(thread.id)); await ref.read(repliesProvider(thread.id).future); }, child: CustomScrollView(slivers: [
          if (thread.status == 'hidden') SliverPadding(padding: const EdgeInsets.only(top: AppSpacing.lg), sliver: SliverToBoxAdapter(child: Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: LightModeColors.lightWarning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)), child: Row(children: [const Icon(Icons.visibility_off_outlined, color: LightModeColors.lightWarning), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('forum_studio.thread.hidden_banner'.tr()))])))),
          SliverPadding(padding: const EdgeInsets.only(top: AppSpacing.md), sliver: SliverToBoxAdapter(child: Column(children: [Row(children: [Expanded(child: ForumBreadcrumb(slug: widget.slug, forumName: forum?.name ?? thread.forumName ?? widget.slug, threadTitle: thread.title)), const SizedBox(width: AppSpacing.sm), HBButton.soft(label: (_subscribed == true ? 'forum_advanced.subscription.on' : 'forum_advanced.subscription.off').tr(), icon: _subscribed == true ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, onPressed: userId == null ? null : _toggleSubscription, size: HBButtonSize.sm)]), const SizedBox(height: AppSpacing.sm), ThreadPostCard(thread: thread, canEdit: userId == thread.authorId, canManage: canManage, onModerate: (action) => _moderate(thread, action), onEdit: () async {
            final result = await showDialog<({String title, String? content, List<String> tags})>(context: context, builder: (_) => ThreadEditDialog(thread: thread));
            if (result == null) return;
            try { final repository = ref.read(forumsRepositoryProvider); await repository.updateThread(thread.id, title: result.title, content: result.content); await repository.updateThreadTags(thread.id, result.tags); ref.invalidate(threadDetailProvider(thread.id)); } on AppException catch (error) { _error(error); }
          })]))),
          if (solution != null) ...[const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)), SliverToBoxAdapter(child: SolutionSummary(reply: solution, onGo: () => _scrollTo(solution.id), onRemove: canSolve ? () => _markSolution(null) : null))],
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          SliverToBoxAdapter(child: Text('forums.replies_title'.tr(), style: context.textStyles.titleLarge)),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          replies.when(
            loading: () => const SliverToBoxAdapter(child: HBListSkeleton()),
            error: (_, __) => SliverToBoxAdapter(child: ThreadError(onRetry: () => ref.invalidate(repliesProvider(thread.id)))),
            data: (page) => page.items.isEmpty ? SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.chat_bubble_outline, title: 'forums.replies_empty_title'.tr(), message: 'forums.replies_empty_message'.tr()))) : SliverList.separated(itemCount: page.items.length + (page.hasMore ? 1 : 0), separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm), itemBuilder: (context, index) {
              if (index == page.items.length) return HBButton.secondary(label: 'feed.load_more'.tr(), onPressed: page.isLoadingMore ? null : () => ref.read(repliesProvider(thread.id).notifier).loadMore());
              final item = page.items[index];
              final own = userId == item.authorId;
              final actualParent = item.depth >= 2 ? item.parentId : item.id;
               return Column(key: _replyKeys.putIfAbsent(item.id, GlobalKey.new), children: [ForumReplyCard(reply: item, isSolution: item.id == thread.solutionReplyId, highlighted: _highlighted == item.id, canEdit: own, canDelete: own || canManage, canSolve: canSolve && item.id != thread.solutionReplyId, onLike: userId == null ? null : () => _toggleLike(item), onReply: isMember && !thread.isLocked ? () => setState(() => _replyingTo = actualParent) : null, onEdit: own ? () => _editReply(item) : null, onDelete: own || canManage ? () => _delete(item) : null, onSolve: canSolve ? () => _markSolution(item.id == thread.solutionReplyId ? null : item.id) : null), if (_replyingTo == actualParent) InlineReplyComposer(controller: _reply, sending: _sending, onChanged: () => setState(() {}), onCancel: () => setState(() => _replyingTo = null), onSend: () => _send(parentId: actualParent))]);
            }),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          SliverToBoxAdapter(child: ThreadReplyFooter(thread: thread, forum: forum, signedIn: userId != null, controller: _reply, files: _files, progress: _progress, sending: _sending, onPick: _pickAttachments, onRemove: (index) => setState(() => _files.removeAt(index)), onChanged: () => setState(() {}), onSend: () => _send(), onLogin: () => context.go(AppRoutes.login), onJoin: () => context.go(AppRoutes.forumDetailPath(widget.slug)))),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ])));
      },
    );
  }
}

class ThreadPostCard extends StatelessWidget {
  final ForumThread thread;
  final bool canEdit;
  final bool canManage;
  final VoidCallback onEdit;
  final ValueChanged<String> onModerate;
  const ThreadPostCard({super.key, required this.thread, required this.canEdit, required this.canManage, required this.onEdit, required this.onModerate});

  @override
  Widget build(BuildContext context) => HBCard(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(thread.title, style: context.textStyles.headlineSmall)), if (canManage) ThreadModerationMenu(thread: thread, onSelected: onModerate) else if (canEdit) PopupMenuButton<String>(onSelected: (action) => action == 'edit' ? onEdit() : onModerate('delete'), itemBuilder: (_) => [PopupMenuItem(value: 'edit', child: Text('forums.thread.edit'.tr())), PopupMenuItem(value: 'delete', child: Text('forum_studio.thread.delete'.tr()))])]),
    if (thread.tags.isNotEmpty) ...[const SizedBox(height: AppSpacing.xs), Wrap(spacing: AppSpacing.xs, children: [for (final tag in thread.tags) HBChip(label: '#$tag', selected: false, onTap: () => context.push(AppRoutes.forumTagPath(tag)))])],
    Wrap(spacing: AppSpacing.xs, children: [if (thread.isPinned) HBStatusChip(kind: HBStatusKind.info, label: 'forums.pinned'.tr()), if (thread.isLocked) HBStatusChip(kind: HBStatusKind.neutral, label: 'forums.closed'.tr()), if (thread.status == 'hidden') HBStatusChip(kind: HBStatusKind.pending, label: 'forum_studio.hidden'.tr()), if (thread.solutionReplyId != null) HBStatusChip(kind: HBStatusKind.approved, label: 'forums.solved'.tr())]),
    const SizedBox(height: AppSpacing.sm),
    Row(children: [HBAvatar(name: thread.author.displayName, imageUrl: thread.author.avatarUrl, size: 40), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(thread.author.displayName), Text(relativeTime(context, thread.createdAt), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]))]),
    if (thread.content?.isNotEmpty == true) ...[const SizedBox(height: AppSpacing.md), HBRichText(text: thread.content!)],
    if (thread.attachments.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), ForumAttachmentsView(attachments: thread.attachments)],
  ]));
}

class ForumReplyCard extends StatelessWidget {
  final ForumReply reply;
  final bool isSolution;
  final bool highlighted;
  final bool canEdit;
  final bool canDelete;
  final bool canSolve;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSolve;
  final VoidCallback? onLike;
  const ForumReplyCard({super.key, required this.reply, required this.isSolution, required this.highlighted, required this.canEdit, required this.canDelete, required this.canSolve, this.onReply, this.onEdit, this.onDelete, this.onSolve, this.onLike});

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final indent = reply.depth * (mobile ? 16.0 : 32.0);
    return AnimatedContainer(duration: const Duration(milliseconds: 180), margin: EdgeInsets.only(left: indent), padding: reply.depth == 0 ? EdgeInsets.zero : const EdgeInsets.only(left: AppSpacing.sm), decoration: BoxDecoration(border: Border(left: BorderSide(color: highlighted || isSolution ? LightModeColors.lightPrimaryOutline : LightModeColors.lightDivider, width: highlighted || isSolution ? 2 : 1)), color: highlighted ? LightModeColors.lightPrimarySoft : null), child: Container(decoration: isSolution ? BoxDecoration(border: Border.all(color: LightModeColors.lightPrimaryOutline), borderRadius: BorderRadius.circular(AppRadius.lg)) : null, child: HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [HBAvatar(name: reply.author.displayName, imageUrl: reply.author.avatarUrl, size: 32), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(reply.author.displayName), Text(relativeTime(context, reply.createdAt), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])), if (isSolution) HBStatusChip(kind: HBStatusKind.approved, label: 'forums.solution'.tr())]),
      const SizedBox(height: AppSpacing.sm),
      HBRichText(text: reply.content),
      if (reply.attachments.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), ForumAttachmentsView(attachments: reply.attachments)],
      const SizedBox(height: AppSpacing.sm),
      Wrap(spacing: AppSpacing.xs, children: [HBButton.ghost(label: '${'feed.like'.tr()}${reply.reactionCount > 0 ? ' ${reply.reactionCount}' : ''}', icon: reply.myLike ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: HBButtonSize.sm, onPressed: onLike), if (onReply != null) HBButton.ghost(label: 'forums.reply.reply'.tr(), size: HBButtonSize.sm, onPressed: onReply), if (canEdit) HBButton.ghost(label: 'forums.reply.edit'.tr(), size: HBButtonSize.sm, onPressed: onEdit), if (canDelete) HBButton.ghost(label: 'forums.reply.delete'.tr(), size: HBButtonSize.sm, onPressed: onDelete), if (canSolve || isSolution) HBButton.ghost(label: (isSolution ? 'forums.reply.remove_solution' : 'forums.reply.mark_solution').tr(), size: HBButtonSize.sm, onPressed: onSolve)]),
    ]))));
  }
}

class SolutionSummary extends StatelessWidget {
  final ForumReply reply;
  final VoidCallback onGo;
  final VoidCallback? onRemove;
  const SolutionSummary({super.key, required this.reply, required this.onGo, this.onRemove});
  @override
  Widget build(BuildContext context) => HBCard(child: Row(children: [const Icon(Icons.check_circle_rounded, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('forums.solution_by'.tr(namedArgs: {'name': reply.author.displayName}))), HBButton.ghost(label: 'forums.go_to_reply'.tr(), onPressed: onGo), if (onRemove != null) HBButton.ghost(label: 'forums.reply.remove_solution'.tr(), onPressed: onRemove)]));
}

class InlineReplyComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onChanged;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  const InlineReplyComposer({super.key, required this.controller, required this.sending, required this.onChanged, required this.onCancel, required this.onSend});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: HBCard(child: Column(children: [ForumMentionInput(controller: controller, maxLength: 5000, minLines: 2, maxLines: 6, hint: 'forums.reply_hint'.tr(), onChanged: (_) => onChanged()), if (controller.text.length > 4500) Align(alignment: Alignment.centerRight, child: Text('${controller.text.length}/5000', style: context.textStyles.bodySmall)), HBFormActions(primaryLabel: 'forums.reply.send'.tr(), onPrimary: controller.text.trim().isEmpty || sending ? null : onSend, secondaryLabel: 'common.cancel'.tr(), onSecondary: onCancel, loading: sending)])));
}

class ThreadReplyFooter extends StatelessWidget {
  final ForumThread thread;
  final Forum? forum;
  final bool signedIn;
  final TextEditingController controller;
  final bool sending;
  final List<PreparedUpload> files;
  final double? progress;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;
  final VoidCallback onChanged;
  final VoidCallback onSend;
  final VoidCallback onLogin;
  final VoidCallback onJoin;
  const ThreadReplyFooter({super.key, required this.thread, required this.forum, required this.signedIn, required this.controller, required this.files, required this.progress, required this.sending, required this.onPick, required this.onRemove, required this.onChanged, required this.onSend, required this.onLogin, required this.onJoin});
  @override
  Widget build(BuildContext context) {
    if (thread.isLocked) return Text('forums.thread_closed'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant));
    if (!signedIn) return HBButton.primary(label: 'forums.sign_in_to_reply'.tr(), onPressed: onLogin);
    if (forum == null) return const SizedBox.shrink();
    if (forum!.myMembership?.isActive != true) return HBButton.primary(label: 'forums.join_to_reply'.tr(), onPressed: onJoin);
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('forums.write_reply'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), ForumMentionInput(controller: controller, maxLength: 5000, minLines: 3, maxLines: 8, hint: 'forums.reply_hint'.tr(), onChanged: (_) => onChanged()), if (controller.text.length > 4500) Align(alignment: Alignment.centerRight, child: Text('${controller.text.length}/5000', style: context.textStyles.bodySmall)), const SizedBox(height: AppSpacing.sm), ForumAttachmentPicker(files: files, onPick: files.length >= 6 || sending ? null : onPick, onRemove: onRemove), if (sending && files.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), HBUploadProgress(progress: progress)], const SizedBox(height: AppSpacing.sm), Align(alignment: Alignment.centerRight, child: HBButton.primary(label: 'forums.reply.send'.tr(), onPressed: (controller.text.trim().isEmpty && files.isEmpty) || sending ? null : onSend, isLoading: sending))]));
  }
}

class ForumTextEditDialog extends StatefulWidget {
  final String titleKey;
  final String initialText;
  final int maxLength;
  const ForumTextEditDialog({super.key, required this.titleKey, required this.initialText, required this.maxLength});
  @override
  State<ForumTextEditDialog> createState() => _ForumTextEditDialogState();
}

class _ForumTextEditDialogState extends State<ForumTextEditDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialText);
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(title: Text(widget.titleKey.tr()), content: SizedBox(width: 560, child: HBInput(controller: _controller, maxLength: widget.maxLength, minLines: 3, maxLines: 8, onChanged: (_) => setState(() {}))), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop()), HBButton.primary(label: 'common.save'.tr(), onPressed: _controller.text.trim().isEmpty ? null : () => context.pop(_controller.text))]);
}

class ThreadEditDialog extends StatefulWidget {
  final ForumThread thread;
  const ThreadEditDialog({super.key, required this.thread});
  @override
  State<ThreadEditDialog> createState() => _ThreadEditDialogState();
}

class _ThreadEditDialogState extends State<ThreadEditDialog> {
  late final TextEditingController _title = TextEditingController(text: widget.thread.title);
  late final TextEditingController _content = TextEditingController(text: widget.thread.content ?? '');
  late List<String> _tags = [...widget.thread.tags];
  @override
  void dispose() { _title.dispose(); _content.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(title: Text('forums.thread.edit'.tr()), content: SizedBox(width: 640, child: Column(mainAxisSize: MainAxisSize.min, children: [HBInput(controller: _title, maxLength: 160, onChanged: (_) => setState(() {})), const SizedBox(height: AppSpacing.md), HBInput(controller: _content, maxLength: 10000, minLines: 3, maxLines: 8), const SizedBox(height: AppSpacing.md), ForumTagEditor(tags: _tags, onChanged: (value) => setState(() => _tags = value))])), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop()), HBButton.primary(label: 'common.save'.tr(), onPressed: _title.text.trim().length < 3 ? null : () => context.pop((title: _title.text, content: _content.text.trim().isEmpty ? null : _content.text, tags: _tags)))]);
}

class ThreadError extends StatelessWidget {
  final VoidCallback onRetry;
  const ThreadError({super.key, required this.onRetry});
  @override
  Widget build(BuildContext context) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'forums.error_title'.tr(), message: 'forums.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: onRetry)));
}