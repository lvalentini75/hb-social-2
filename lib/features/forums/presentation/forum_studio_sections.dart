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
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/studio_overview.dart';
import 'package:hb_social/features/forums/domain/forum.dart';
import 'package:hb_social/features/forums/domain/forum_studio.dart';
import 'package:hb_social/features/forums/domain/forum_thread.dart';
import 'package:hb_social/features/forums/presentation/forum_composer_fields.dart';
import 'package:hb_social/features/forums/presentation/thread_moderation_menu.dart';
import 'package:hb_social/features/forums/providers/forums_providers.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';

class ForumStudioOverview extends ConsumerStatefulWidget {
  final Forum forum;
  const ForumStudioOverview({super.key, required this.forum});
  @override
  ConsumerState<ForumStudioOverview> createState() => _ForumStudioOverviewState();
}

class _ForumStudioOverviewState extends ConsumerState<ForumStudioOverview> {
  int _days = 30;
  String _series = 'replies';
  @override
  Widget build(BuildContext context) {
    final request = (forumId: widget.forum.id, days: _days);
    return ref.watch(forumStudioStatsProvider(request)).when(loading: () => const HBListSkeleton(count: 4), error: (_, __) => HBEmptyState(icon: Icons.query_stats_outlined, title: 'forum_studio.analytics.error_title'.tr(), message: 'forum_studio.analytics.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(forumStudioStatsProvider(request)))), data: (stats) => StudioOverview(
        stats: stats.overview,
        labels: {for (final key in const ['members', 'threads', 'replies', 'views']) key: 'forum_studio.analytics.metrics.$key'.tr()},
        series: const ['replies', 'threads', 'members', 'views'],
        selectedSeries: _series,
        onPeriodChanged: (value) => setState(() => _days = value),
        onSeriesChanged: (value) => setState(() => _series = value),
        lists: [
          StudioOverviewList(title: 'forum_studio.analytics.latest_members'.tr(), children: stats.latestMembers.isEmpty ? const [] : [ForumLatestMembersCard(items: stats.latestMembers)]),
          StudioOverviewList(title: 'forum_studio.analytics.top_threads'.tr(), children: stats.topThreads.isEmpty ? const [] : [ForumTopThreadsCard(items: stats.topThreads, slug: widget.forum.slug)]),
          StudioOverviewList(title: 'forum_studio.analytics.top_contributors'.tr(), children: stats.topContributors.isEmpty ? const [] : [ForumContributorsCard(items: stats.topContributors)]),
        ],
      ));
  }
}

class ForumLatestMembersCard extends StatelessWidget {
  final List<ForumStudioMember> items;
  const ForumLatestMembersCard({super.key, required this.items});
  @override
  Widget build(BuildContext context) => Column(children: [for (final item in items.take(10)) ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: HBAvatar(name: item.profile.displayName, imageUrl: item.profile.avatarUrl, size: 34), title: Text(item.profile.displayName, overflow: TextOverflow.ellipsis), subtitle: Text('${'forum_studio.roles.${item.role}'.tr()} · ${'forum_studio.analytics.joined'.tr(namedArgs: {'time': relativeTime(context, item.joinedAt)})}'), trailing: DateTime.now().difference(item.joinedAt).inHours < 24 ? HBStatusChip(kind: HBStatusKind.approved, label: 'studio_overview.new'.tr()) : null, onTap: () => context.push(AppRoutes.publicProfilePath(item.profile.username)))]);
}

class ForumTopThreadsCard extends StatelessWidget {
  final List<ForumStudioTopThread> items;
  final String slug;
  const ForumTopThreadsCard({super.key, required this.items, required this.slug});
  @override
  Widget build(BuildContext context) => Column(children: [for (final item in items.take(5)) ListTile(contentPadding: EdgeInsets.zero, dense: true, title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: Text('forum_studio.analytics.thread_counts'.tr(namedArgs: {'views': '${item.viewCount}', 'replies': '${item.replyCount}'})), trailing: Wrap(spacing: 2, children: [if (item.isPinned) HBStatusChip(kind: HBStatusKind.info, label: 'forums.pinned'.tr()), if (item.solved) HBStatusChip(kind: HBStatusKind.approved, label: 'forums.solved'.tr())]), onTap: () => context.push(AppRoutes.threadPath(slug, item.id)))]);
}

class ForumContributorsCard extends StatelessWidget {
  final List<ForumStudioContributor> items;
  const ForumContributorsCard({super.key, required this.items});
  @override
  Widget build(BuildContext context) => Column(children: [for (final item in items.take(5)) ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: HBAvatar(name: item.profile.displayName, imageUrl: item.profile.avatarUrl, size: 34), title: Text(item.profile.displayName, overflow: TextOverflow.ellipsis), subtitle: Text('forum_studio.analytics.period_replies'.plural(item.replies)), onTap: () => context.push(AppRoutes.publicProfilePath(item.profile.username)))]);
}

class ForumReportsPanel extends ConsumerStatefulWidget {
  final Forum forum;
  final VoidCallback onChanged;
  const ForumReportsPanel({super.key, required this.forum, required this.onChanged});
  @override
  ConsumerState<ForumReportsPanel> createState() => _ForumReportsPanelState();
}

class _ForumReportsPanelState extends ConsumerState<ForumReportsPanel> {
  bool _includeClosed = false;
  Future<void> _resolve(ForumReport report, String action) async {
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('forum_studio.reports.confirm_title'.tr()), content: Column(mainAxisSize: MainAxisSize.min, children: [Text(action == 'dismiss' ? 'forum_studio.reports.dismiss'.tr() : 'forum_studio.reports.confirm_$action'.tr()), const SizedBox(height: AppSpacing.md), HBInput(controller: note, label: 'forum_studio.reports.note'.tr(), maxLines: 3, maxLength: 500)]), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'common.continue'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
    if (!confirmed || !mounted) { note.dispose(); return; }
    try { await ref.read(forumsRepositoryProvider).resolveForumReport(report.id, action, note: note.text); _refresh(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('forum_studio.reports.resolved'.tr()))); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } finally { note.dispose(); }
  }
  void _refresh() { ref.invalidate(forumReportsProvider((forumId: widget.forum.id, openOnly: true))); ref.invalidate(forumReportsProvider((forumId: widget.forum.id, openOnly: false))); widget.onChanged(); }
  @override
  Widget build(BuildContext context) {
    final request = (forumId: widget.forum.id, openOnly: !_includeClosed);
    return Column(children: [SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('forum_studio.reports.include_closed'.tr()), value: _includeClosed, onChanged: (value) => setState(() => _includeClosed = value)), ref.watch(forumReportsProvider(request)).when(loading: () => const HBListSkeleton(), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'forum_studio.load_error_title'.tr(), message: 'forum_studio.load_error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(forumReportsProvider(request)))), data: (items) => items.isEmpty ? HBEmptyState(icon: Icons.flag_outlined, title: 'forum_studio.reports.empty'.tr(), message: 'forum_studio.reports.empty_message'.tr()) : Column(children: [for (final report in items) ForumReportRow(report: report, slug: widget.forum.slug, onAction: (action) => _resolve(report, action))]))]);
  }
}

class ForumReportRow extends StatelessWidget {
  final ForumReport report;
  final String slug;
  final ValueChanged<String> onAction;
  const ForumReportRow({super.key, required this.report, required this.slug, required this.onAction});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [HBStatusChip(kind: HBStatusKind.info, label: 'forum_studio.reports.type.${report.targetType}'.tr()), HBStatusChip(kind: report.priority == 'high' ? HBStatusKind.rejected : HBStatusKind.neutral, label: 'forum_studio.reports.priority.${report.priority}'.tr()), if (report.status != 'open') HBStatusChip(kind: HBStatusKind.neutral, label: 'forum_studio.reports.status.${report.status}'.tr())]),
    const SizedBox(height: AppSpacing.xs), Text('safety.reasons.${report.reason}'.tr(), style: context.textStyles.titleSmall), if (report.preview.isNotEmpty) Text(report.preview, maxLines: 3, overflow: TextOverflow.ellipsis), const SizedBox(height: AppSpacing.xs), Text('forum_studio.reports.meta'.tr(namedArgs: {'author': report.authorDisplayName, 'reporter': report.reporterUsername, 'time': relativeTime(context, report.createdAt)}), style: context.textStyles.bodySmall), const SizedBox(height: AppSpacing.sm),
    Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [HBButton.ghost(label: 'forum_studio.reports.open'.tr(), size: HBButtonSize.sm, onPressed: () => context.push('${AppRoutes.threadPath(slug, report.threadId)}${report.targetType == 'reply' ? '?reply=${report.targetId}' : ''}')), if (report.status == 'open') ...[HBButton.soft(label: 'forum_studio.reports.dismiss'.tr(), size: HBButtonSize.sm, onPressed: () => onAction('dismiss')), HBButton.soft(label: 'forum_studio.reports.hide'.tr(), size: HBButtonSize.sm, onPressed: () => onAction('hide')), HBButton.soft(label: 'forum_studio.reports.delete'.tr(), size: HBButtonSize.sm, onPressed: () => onAction('delete'))]])
  ]));
}

class ForumStudioThreadsPanel extends ConsumerStatefulWidget {
  final Forum forum;
  final VoidCallback onChanged;
  const ForumStudioThreadsPanel({super.key, required this.forum, required this.onChanged});
  @override
  ConsumerState<ForumStudioThreadsPanel> createState() => _ForumStudioThreadsPanelState();
}

class _ForumStudioThreadsPanelState extends ConsumerState<ForumStudioThreadsPanel> {
  String _filter = 'all';
  String _sort = 'activity';
  int? _sinceDays;
  UserProfile? _author;
  List<UserProfile> _suggestions = const [];
  final _authorInput = TextEditingController();
  final _selected = <String>{};
  bool _working = false;
  @override
  void dispose() { _authorInput.dispose(); super.dispose(); }
  Future<void> _search(String value) async { final result = await ref.read(forumsRepositoryProvider).searchProfiles(value); if (mounted && value == _authorInput.text) setState(() => _suggestions = result); }
  Future<List<ForumThread>> _load() => ref.read(forumsRepositoryProvider).fetchThreads(forumId: widget.forum.id, filter: _filter, sort: _sort, authorId: _author?.id, since: _sinceDays == null ? null : DateTime.now().subtract(Duration(days: _sinceDays!))).then((page) => page.items);
  void _reload() { setState(() {}); widget.onChanged(); }

  Future<void> _action(ForumThread thread, String action) async {
    if (action == 'open') { context.push(AppRoutes.threadPath(widget.forum.slug, thread.id)); return; }
    if (action == 'edit_tags') { await _editTags(thread); return; }
    final repository = ref.read(forumsRepositoryProvider);
    try {
      if (action == 'pin') await repository.setThreadPinned(thread.id, !thread.isPinned);
      if (action == 'lock') await repository.setThreadLocked(thread.id, !thread.isLocked);
      if (action == 'status') await repository.setThreadStatus(thread.id, thread.status == 'hidden' ? 'published' : 'hidden');
      if (action == 'delete') { final confirmed = await _confirmDelete(); if (!confirmed) return; await repository.deleteThread(thread.id); }
      _reload();
    } on AppException catch (error) { _snack(error.messageKey); }
  }

  Future<bool> _confirmDelete() async => await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('forum_studio.thread.delete_title'.tr()), content: Text('forum_studio.thread.delete_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'forum_studio.thread.delete'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
  Future<void> _editTags(ForumThread thread) async {
    var tags = [...thread.tags];
    final saved = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (_, setDialogState) => AlertDialog(title: Text('forum_studio.thread.edit_tags'.tr()), content: SizedBox(width: 520, child: ForumTagEditor(tags: tags, onChanged: (value) => setDialogState(() => tags = value))), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'common.save'.tr(), onPressed: () => dialogContext.pop(true))]))) ?? false;
    if (!saved) return;
    try { await ref.read(forumsRepositoryProvider).updateThreadTags(thread.id, tags); _reload(); } on AppException catch (error) { _snack(error.messageKey); }
  }

  Future<void> _bulk(String action, List<ForumThread> threads) async {
    setState(() => _working = true);
    var count = 0;
    final repository = ref.read(forumsRepositoryProvider);
    try {
      for (final thread in threads.where((item) => _selected.contains(item.id))) {
        if (action == 'lock') await repository.setThreadLocked(thread.id, true);
        if (action == 'hide') await repository.setThreadStatus(thread.id, 'hidden');
        if (action == 'pin') await repository.setThreadPinned(thread.id, true);
        count++;
      }
      _selected.clear(); _reload(); _snack('forum_studio.thread.bulk_updated', args: {'count': '$count'});
    } on AppException catch (error) { _snack(error.messageKey); } finally { if (mounted) setState(() => _working = false); }
  }
  void _snack(String key, {Map<String, String>? args}) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr(namedArgs: args)))); }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ForumThread>>(future: _load(), builder: (context, snapshot) {
    final threads = snapshot.data ?? const <ForumThread>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final filter in const ['all', 'open', 'solved', 'pinned', 'locked', 'with_attachments', 'unanswered', 'hidden']) HBChip(label: filter == 'hidden' ? 'forum_studio.hidden'.tr() : 'forum_advanced.filters.$filter'.tr(), selected: _filter == filter, onTap: () => setState(() { _filter = filter; _selected.clear(); }))]),
      const SizedBox(height: AppSpacing.sm),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
        PopupMenuButton<String>(initialValue: _sort, onSelected: (value) => setState(() => _sort = value), itemBuilder: (_) => [for (final sort in const ['activity', 'views', 'replies', 'newest']) PopupMenuItem(value: sort, child: Text('forum_advanced.sort.$sort'.tr()))], child: HBChip(label: 'forum_advanced.sort.$_sort'.tr(), selected: false)),
        for (final value in const [1, 7, 30]) HBChip(label: 'forum_studio.thread.since_$value'.tr(), selected: _sinceDays == value, onTap: () => setState(() => _sinceDays = _sinceDays == value ? null : value)),
      ]),
      const SizedBox(height: AppSpacing.sm),
      HBInput(controller: _authorInput, hint: 'forum_studio.thread.author_filter'.tr(), prefixIcon: const Icon(Icons.person_search_outlined), suffixIcon: _author == null ? null : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _author = null; _authorInput.clear(); _suggestions = const []; })), onChanged: (value) { _author = null; _search(value); }),
      if (_suggestions.isNotEmpty) HBCard(child: Column(children: [for (final profile in _suggestions) ListTile(leading: HBAvatar(name: profile.displayName, imageUrl: profile.avatarUrl, size: 32), title: Text(profile.displayName), subtitle: Text('@${profile.username}'), onTap: () => setState(() { _author = profile; _authorInput.text = profile.displayName; _suggestions = const []; }))])),
      const SizedBox(height: AppSpacing.sm),
      if (snapshot.connectionState == ConnectionState.waiting) const HBListSkeleton() else if (snapshot.hasError) HBEmptyState(icon: Icons.error_outline, title: 'forum_studio.load_error_title'.tr(), message: 'forum_studio.load_error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: _reload)) else if (threads.isEmpty) HBEmptyState(icon: Icons.forum_outlined, title: 'forum_studio.threads_empty'.tr(), message: 'forum_studio.threads_empty_message'.tr()) else for (final thread in threads) CheckboxListTile(value: _selected.contains(thread.id), onChanged: (value) => setState(() => value == true ? _selected.add(thread.id) : _selected.remove(thread.id)), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, title: Text(thread.title), subtitle: Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [if (thread.isPinned) HBStatusChip(kind: HBStatusKind.info, label: 'forums.pinned'.tr()), if (thread.isLocked) HBStatusChip(kind: HBStatusKind.neutral, label: 'forums.closed'.tr()), if (thread.status == 'hidden') HBStatusChip(kind: HBStatusKind.pending, label: 'forum_studio.hidden'.tr()), if (thread.solutionReplyId != null) HBStatusChip(kind: HBStatusKind.approved, label: 'forums.solved'.tr()), if (DateTime.now().difference(thread.createdAt).inHours < 24) HBStatusChip(kind: HBStatusKind.approved, label: 'forum_studio.analytics.new'.tr())]), secondary: ThreadModerationMenu(thread: thread, includeStudioActions: true, onSelected: (action) => _action(thread, action))),
      if (_selected.isNotEmpty) Container(margin: const EdgeInsets.only(top: AppSpacing.md), padding: const EdgeInsets.all(AppSpacing.sm), decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.md)), child: Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [Text('forum_studio.thread.selected'.tr(namedArgs: {'count': '${_selected.length}'})), HBButton.soft(label: 'forum_studio.thread.close'.tr(), size: HBButtonSize.sm, isLoading: _working, onPressed: _working ? null : () => _bulk('lock', threads)), HBButton.soft(label: 'forum_studio.thread.hide'.tr(), size: HBButtonSize.sm, onPressed: _working ? null : () => _bulk('hide', threads)), HBButton.soft(label: 'forum_studio.thread.pin'.tr(), size: HBButtonSize.sm, onPressed: _working ? null : () => _bulk('pin', threads))])),
    ]);
  });
}