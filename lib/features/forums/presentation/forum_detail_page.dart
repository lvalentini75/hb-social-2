import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_paged_sliver_list.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/forums/domain/forum.dart';
import 'package:hb_social/features/forums/domain/forum_thread.dart';
import 'package:hb_social/features/forums/presentation/forum_breadcrumb.dart';
import 'package:hb_social/features/forums/presentation/forum_studio_page.dart';
import 'package:hb_social/features/forums/providers/forums_providers.dart';
import 'package:hb_social/features/forums/presentation/forum_attachments.dart';
import 'package:hb_social/features/forums/presentation/forum_composer_fields.dart';

class ForumDetailPage extends ConsumerStatefulWidget {
  final String slug;
  const ForumDetailPage({super.key, required this.slug});

  @override
  ConsumerState<ForumDetailPage> createState() => _ForumDetailPageState();
}

class _ForumDetailPageState extends ConsumerState<ForumDetailPage> {
  ForumMembership? _membership;
  String? _forumId;
  bool _working = false;

  void _sync(Forum forum) { if (_forumId != forum.id) { _forumId = forum.id; _membership = forum.myMembership; } }
  void _refresh(Forum forum) { ref.invalidate(forumDetailProvider(widget.slug)); ref.invalidate(forumsProvider); ref.invalidate(threadsProvider(forum.id)); }

  Future<void> _join(Forum forum) async {
    if (ref.read(authSessionProvider).value == null) { context.go(AppRoutes.login); return; }
    setState(() => _working = true);
    try { final membership = await ref.read(forumsRepositoryProvider).joinForum(forum.id); if (mounted) setState(() => _membership = membership); _refresh(forum); } on AppException catch (error) { _showError(error); } finally { if (mounted) setState(() => _working = false); }
  }

  Future<void> _leave(Forum forum, {required bool pending}) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text((pending ? 'forums.cancel_request_title' : 'forums.leave_title').tr()), content: Text((pending ? 'forums.cancel_request_message' : 'forums.leave_message').tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: (pending ? 'forums.cancel_request' : 'forums.leave').tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
    if (!confirmed || !mounted) return;
    setState(() => _working = true);
    try { await ref.read(forumsRepositoryProvider).leaveForum(forum.id); if (mounted) setState(() => _membership = null); _refresh(forum); } on AppException catch (error) { _showError(error); } finally { if (mounted) setState(() => _working = false); }
  }

  void _showError(AppException error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs)))); }

  Future<void> _newThread(Forum forum) async {
    if (_membership?.isActive != true) return;
    final id = await showDialog<String>(context: context, builder: (_) => NewThreadDialog(forumId: forum.id));
    if (id != null && mounted) { ref.invalidate(threadsProvider(forum.id)); context.push(AppRoutes.threadPath(forum.slug, id)); }
  }

  @override
  Widget build(BuildContext context) => ref.watch(forumDetailProvider(widget.slug)).when(
    loading: () => const PageColumns(center: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: HBListSkeleton())),
    error: (_, __) => PageColumns(center: ForumDetailError(onRetry: () => ref.invalidate(forumDetailProvider(widget.slug)))),
    data: (forum) {
      if (forum == null) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.forum_outlined, title: 'forums.not_found_title'.tr(), message: 'forums.not_found_message'.tr())));
      _sync(forum);
      final restricted = forum.isPrivate && _membership?.isActive != true;
      final canWrite = _membership?.isActive == true;
      return PageColumns(center: RefreshIndicator(onRefresh: () async { _forumId = null; _refresh(forum); await ref.read(forumDetailProvider(widget.slug).future); }, child: CustomScrollView(slivers: [
        SliverPadding(padding: const EdgeInsets.only(top: AppSpacing.md), sliver: SliverToBoxAdapter(child: ForumBreadcrumb(slug: forum.slug, forumName: forum.name))),
        if (forum.status == 'archived') const SliverPadding(padding: EdgeInsets.only(top: AppSpacing.lg), sliver: SliverToBoxAdapter(child: ForumArchivedBanner())),
        SliverPadding(padding: const EdgeInsets.only(top: AppSpacing.sm), sliver: SliverToBoxAdapter(child: ForumHeader(forum: forum, membership: _membership, working: _working, onJoin: () => _join(forum), onLeave: () => _leave(forum, pending: false), onCancel: () => _leave(forum, pending: true), onNewThread: () => _newThread(forum)))),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        if (!restricted) SliverToBoxAdapter(child: ForumThreadFilters(forumId: forum.id)),
        if (!restricted) const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        if (restricted) SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.lock_outline_rounded, title: 'forums.members_only_title'.tr(), message: 'forums.members_only_message'.tr()))) else HBPagedSliverList<ForumThread>(value: ref.watch(threadsProvider(forum.id)), loading: const HBListSkeleton(), empty: HBCard(child: HBEmptyState(icon: Icons.forum_outlined, title: 'forums.threads_empty_title'.tr(), message: 'forums.threads_empty_message'.tr())), error: ForumDetailError(onRetry: () => ref.invalidate(threadsProvider(forum.id))), onRetry: () => ref.invalidate(threadsProvider(forum.id)), onLoadMore: () => ref.read(threadsProvider(forum.id).notifier).loadMore(), itemBuilder: (context, thread, index) => ForumThreadCard(slug: forum.slug, thread: thread)),
        if (!canWrite && !restricted) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: Tooltip(message: 'forums.join_to_write'.tr(), child: HBButton.primary(label: 'forums.new_thread'.tr(), onPressed: null)))),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
      ])));
    },
  );
}

class ForumHeader extends StatelessWidget {
  final Forum forum;
  final ForumMembership? membership;
  final bool working;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onCancel;
  final VoidCallback onNewThread;
  const ForumHeader({super.key, required this.forum, required this.membership, required this.working, required this.onJoin, required this.onLeave, required this.onCancel, required this.onNewThread});

  @override
  Widget build(BuildContext context) => HBCard.media(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    AspectRatio(aspectRatio: 3, child: forum.coverUrl?.isNotEmpty == true ? Image.network(forum.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft)) : const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.landscape_outlined, color: LightModeColors.lightTextTertiary, size: 42))),
    Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [HBAvatar(name: forum.name, imageUrl: forum.avatarUrl, size: 56), const SizedBox(width: AppSpacing.md), Expanded(child: Text(forum.name, style: context.textStyles.headlineSmall)), if (forum.isPrivate) const Icon(Icons.lock_outline_rounded)]),
    if (forum.description?.isNotEmpty == true) ...[const SizedBox(height: AppSpacing.sm), Text(forum.description!)],
    const SizedBox(height: AppSpacing.sm),
    Text('${'forums.thread_count'.plural(forum.threadCount)} · ${'forums.member_count'.plural(forum.memberCount)}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
    if (forum.category != null) ...[const SizedBox(height: AppSpacing.sm), HBChip(label: 'forums.category.${forum.category}'.tr(), selected: false)],
    const SizedBox(height: AppSpacing.md),
    Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [ForumMembershipAction(forum: forum, membership: membership, working: working, onJoin: onJoin, onLeave: onLeave, onCancel: onCancel), if (membership?.canManage == true) HBButton.secondary(label: 'forums.studio'.tr(), icon: Icons.tune_rounded, onPressed: () => context.push(AppRoutes.forumStudioPath(forum.slug))), if (membership?.isActive == true) HBButton.primary(label: 'forums.new_thread'.tr(), icon: Icons.add_rounded, onPressed: onNewThread)]),
  ]))]));
}

class ForumMembershipAction extends StatelessWidget {
  final Forum forum;
  final ForumMembership? membership;
  final bool working;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onCancel;
  const ForumMembershipAction({super.key, required this.forum, required this.membership, required this.working, required this.onJoin, required this.onLeave, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    if (membership?.status == 'banned') return HBButton.soft(label: 'forums.banned'.tr(), onPressed: null);
    if (membership?.status == 'pending') return HBButton.soft(label: 'forums.request_sent'.tr(), icon: Icons.schedule_rounded, onPressed: working ? null : onCancel, isLoading: working);
    if (membership?.isActive == true) {
      final owner = membership!.role == 'owner';
      return Row(mainAxisSize: MainAxisSize.min, children: [HBStatusChip(kind: HBStatusKind.approved, label: 'forums.member_chip'.tr()), const SizedBox(width: AppSpacing.xs), Tooltip(message: owner ? 'forums.owner_cannot_leave'.tr() : '', child: PopupMenuButton<String>(enabled: !working, icon: const Icon(Icons.more_horiz_rounded), onSelected: (_) => onLeave(), itemBuilder: (_) => [PopupMenuItem(value: 'leave', enabled: !owner, child: Text('forums.leave'.tr()))]))]);
    }
    return HBButton.primary(label: (forum.isPrivate ? 'forums.request_join' : 'forums.join').tr(), onPressed: working ? null : onJoin, isLoading: working);
  }
}

class ForumThreadCard extends StatelessWidget {
  final String slug;
  final ForumThread thread;
  const ForumThreadCard({super.key, required this.slug, required this.thread});

  @override
  Widget build(BuildContext context) {
    final activity = thread.lastReplyAt ?? thread.createdAt;
    return GestureDetector(onTap: () => context.push(AppRoutes.threadPath(slug, thread.id)), child: HBCard(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [if (thread.isPinned) ...[const Icon(Icons.push_pin_outlined, size: 18), const SizedBox(width: AppSpacing.xs)], Expanded(child: Text(thread.title, style: context.textStyles.titleMedium)), if (thread.attachments.isNotEmpty) ...[const Icon(Icons.attach_file_rounded, size: 18), Text('${thread.attachments.length}')], if (thread.isLocked) const Icon(Icons.lock_outline_rounded, size: 18), if (thread.solutionReplyId != null) ...[const SizedBox(width: AppSpacing.sm), HBStatusChip(kind: HBStatusKind.approved, label: 'forums.solved'.tr())]]),
      if (thread.tags.isNotEmpty) ...[const SizedBox(height: AppSpacing.xs), Wrap(spacing: AppSpacing.xs, children: [for (final tag in thread.tags.take(3)) HBChip(label: '#$tag', selected: false, onTap: () => context.push(AppRoutes.forumTagPath(tag))), if (thread.tags.length > 3) HBChip(label: '+${thread.tags.length - 3}', selected: false)])],
      const SizedBox(height: AppSpacing.sm),
      Row(children: [HBAvatar(name: thread.author.displayName, imageUrl: thread.author.avatarUrl, size: 24), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(thread.author.displayName, overflow: TextOverflow.ellipsis))]),
      const SizedBox(height: AppSpacing.sm),
      Text('forums.thread_meta'.tr(namedArgs: {'replies': '${thread.replyCount}', 'views': '${thread.viewCount}', 'time': relativeTime(context, activity)}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
    ])));
  }
}

class NewThreadDialog extends ConsumerStatefulWidget {
  final String forumId;
  const NewThreadDialog({super.key, required this.forumId});

  @override
  ConsumerState<NewThreadDialog> createState() => _NewThreadDialogState();
}

class _NewThreadDialogState extends ConsumerState<NewThreadDialog> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  final List<String> _tags = [];
  final List<PreparedUpload> _files = [];
  bool _saving = false;
  double? _progress;
  String? _errorKey;
  bool get _valid => _title.text.trim().length >= 3 && _title.text.trim().length <= 160 && _content.text.trim().length <= 10000;

  @override
  void dispose() { _title.dispose(); _content.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() { _saving = true; _errorKey = null; });
    try { final attachments = await _upload(); final id = await ref.read(forumsRepositoryProvider).createThread(forumId: widget.forumId, title: _title.text, content: _content.text, tags: _tags, attachments: attachments); if (mounted) context.pop(id); } on AppException catch (error) { if (mounted) setState(() => _errorKey = error.messageKey); } finally { if (mounted) setState(() => _saving = false); }
  }

  Future<List<Map<String, dynamic>>> _upload() async {
    final service = ref.read(mediaUploadServiceProvider);
    final userId = ref.read(authSessionProvider).value!.user.id;
    final result = <Map<String, dynamic>>[];
    var completed = 0;
    for (final file in _files) {
      String? thumbnailPath;
      if (file.poster != null) { final poster = await service.uploadPoster(bucket: 'forum-media', bytes: file.poster!.bytes); thumbnailPath = poster.path; }
      final progress = UploadProgress();
      final subscription = progress.stream.listen((value) { if (mounted) setState(() => _progress = (completed + value) / _files.length); });
      final uploaded = await service.uploadToBucket(bucket: 'forum-media', userId: userId, upload: file, isPublic: true, progress: progress);
      await subscription.cancel(); await progress.close(); completed++;
      result.add({'path': uploaded.path, 'kind': file.mediaKind, 'mime_type': file.contentType, 'size_bytes': file.bytes.length, 'file_name': file.fileName, 'width': file.width, 'height': file.height, 'duration_ms': file.durationMs, 'thumbnail_path': thumbnailPath});
    }
    return result;
  }

  Future<void> _pick() async { try { final picked = await ref.read(mediaUploadServiceProvider).pickForumAttachments(remaining: 6 - _files.length); if (mounted) setState(() => _files.addAll(picked)); } on AppException catch (error) { if (mounted) setState(() => _errorKey = error.messageKey); } }

  @override
  Widget build(BuildContext context) => AlertDialog(title: Text('forums.new_thread'.tr()), content: SizedBox(width: 640, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [HBFormField(label: 'forums.thread.title'.tr(), required: true, helper: '${_title.text.length}/160', child: HBInput(controller: _title, maxLength: 160, onChanged: (_) => setState(() {}))), const SizedBox(height: AppSpacing.md), HBFormField(label: 'forums.thread.content'.tr(), helper: '${_content.text.length}/10000', child: ForumMentionInput(controller: _content, maxLength: 10000, minLines: 4, maxLines: 10, hint: 'forums.thread.content'.tr(), onChanged: (_) => setState(() {}))), const SizedBox(height: AppSpacing.md), ForumTagEditor(tags: _tags, onChanged: (value) => setState(() { _tags..clear()..addAll(value); })), const SizedBox(height: AppSpacing.md), ForumAttachmentPicker(files: _files, onPick: _files.length >= 6 || _saving ? null : _pick, onRemove: (index) => setState(() => _files.removeAt(index))), if (_saving && _files.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), HBUploadProgress(progress: _progress)], if (_errorKey != null) ...[const SizedBox(height: AppSpacing.sm), Text(_errorKey!.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))]]))), actions: [HBFormActions(primaryLabel: 'forums.thread.publish'.tr(), onPrimary: _valid && !_saving ? _save : null, secondaryLabel: 'common.cancel'.tr(), onSecondary: () => context.pop(), loading: _saving)]);
}

class ForumThreadFilters extends ConsumerWidget {
  final String forumId;
  const ForumThreadFilters({super.key, required this.forumId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(forumThreadQueryProvider(forumId));
    const filters = ['all', 'open', 'solved', 'pinned', 'locked', 'with_attachments', 'unanswered'];
    void update(ForumThreadQuery value) { ref.read(forumThreadQueryProvider(forumId).notifier).state = value; ref.invalidate(threadsProvider(forumId)); }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ref.watch(forumTopTagsProvider(forumId)).when(data: (tags) => tags.isEmpty ? const SizedBox.shrink() : SizedBox(height: 38, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: tags.length, separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs), itemBuilder: (_, index) => HBChip(label: '#${tags[index].tag}', selected: query.tag == tags[index].tag, onTap: () => update(query.copyWith(tag: tags[index].tag))))), loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink()),
      const SizedBox(height: AppSpacing.sm),
      Row(children: [Expanded(child: SizedBox(height: 38, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: filters.length, separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs), itemBuilder: (_, index) => HBChip(label: 'forum_advanced.filters.${filters[index]}'.tr(), selected: query.filter == filters[index], onTap: () => update(query.copyWith(filter: filters[index])))))), PopupMenuButton<String>(initialValue: query.sort, onSelected: (value) => update(query.copyWith(sort: value)), itemBuilder: (_) => [for (final sort in const ['activity', 'views', 'replies', 'newest']) PopupMenuItem(value: sort, child: Text('forum_advanced.sort.$sort'.tr()))])]),
      if (query.tag != null) InputChip(label: Text('#${query.tag}'), onDeleted: () => update(query.copyWith(clearTag: true))),
    ]);
  }
}

class ForumDetailError extends StatelessWidget {
  final VoidCallback? onRetry;
  const ForumDetailError({super.key, this.onRetry});
  @override
  Widget build(BuildContext context) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'forums.error_title'.tr(), message: 'forums.error_message'.tr(), action: onRetry == null ? null : HBButton.secondary(label: 'common.retry'.tr(), onPressed: onRetry)));
}