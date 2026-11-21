import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/data/admin_list_repository.dart';
import 'package:hb_social/features/admin/domain/admin_list_models.dart';
import 'package:hb_social/features/admin/presentation/admin_users_page.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_detail_panel.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_read_only_widgets.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/providers/admin_console_providers.dart';
import 'package:hb_social/features/home/presentation/widgets/feed_post_card.dart';
import 'package:hb_social/features/reels/providers/reels_providers.dart';

class AdminContentPage extends ConsumerStatefulWidget {
  final String? initialId;
  const AdminContentPage({super.key, this.initialId});
  @override ConsumerState<AdminContentPage> createState() => _AdminContentPageState();
}

class _AdminContentPageState extends ConsumerState<AdminContentPage> {
  int tab = 0;
  String? status;
  String? kind;
  String? visibility;
  String? country;
  bool? sensitive;
  String search = '';
  Object? selected;
  Timer? debounce;

  @override void dispose() { debounce?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final filters = AdminContentFilters(id: widget.initialId, status: status, kind: kind, visibility: visibility, isSensitive: sensitive, countryCode: country, search: search);
    final provider = tab == 0 ? adminPostsProvider(filters) : tab == 1 ? adminStoriesProvider(filters) : adminCommentsProvider(filters);
    final value = ref.watch(provider);
    final state = value.value;
    final count = ref.watch(adminContentCountProvider((table: tab == 0 ? 'posts' : tab == 1 ? 'stories' : 'comments', filters: filters))).valueOrNull;
    if (selected == null && widget.initialId != null && state?.items.isNotEmpty == true) WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && selected == null) setState(() => selected = state!.items.first); });
    return Stack(children: [
      AdminListPage(
        title: 'admin.modules.content.title'.tr(),
        description: 'admin.p05d.results'.tr(namedArgs: {'count': count?.toString() ?? '—'}),
        filters: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AdminReelsStatsCard(),
          const SizedBox(height: AppSpacing.md),
          SizedBox(width: 420, child: HBSegmentedTabs(labels: ['admin.p05d.contentTabs.posts'.tr(), 'admin.p05d.contentTabs.stories'.tr(), 'admin.p05d.contentTabs.comments'.tr()], selectedIndex: tab, onChanged: (value) => setState(() { tab = value; status = null; kind = null; visibility = null; selected = null; }))),
          const SizedBox(height: AppSpacing.sm),
          ContentFilters(tab: tab, status: status, kind: kind, visibility: visibility, country: country, sensitive: sensitive, onSearch: _search, onStatus: (value) => setState(() => status = value), onKind: (value) => setState(() => kind = value), onVisibility: (value) => setState(() => visibility = value), onCountry: (value) => setState(() => country = value), onSensitive: (value) => setState(() => sensitive = value)),
        ]),
        kpis: [AdminKpiValue(label: 'admin.p05d.total'.tr(), value: count?.toString() ?? '—')],
        emptyMessage: 'admin.p05d.contentEmpty'.tr(),
        content: AdminContentTable(tab: tab, items: state?.items ?? const [], isLoading: value.isLoading, onSelected: (item) => setState(() => selected = item)),
        hasMore: state?.hasMore ?? false,
        isLoadingMore: state?.isLoadingMore ?? false,
        onLoadMore: () {
          if (tab == 0) ref.read(adminPostsProvider(filters).notifier).loadMore();
          if (tab == 1) ref.read(adminStoriesProvider(filters).notifier).loadMore();
          if (tab == 2) ref.read(adminCommentsProvider(filters).notifier).loadMore();
        },
        onRetry: value.hasError && state == null ? () => ref.invalidate(provider) : null,
      ),
      if (selected != null) AdminDetailOverlay(onClose: _close, panel: AdminContentDetailPanel(record: selected!, onClose: _close)),
    ]);
  }

  void _search(String value) { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 250), () { if (mounted) setState(() => search = value); }); }
  void _close() { setState(() => selected = null); if (widget.initialId != null) context.go('/admin/content'); }
}

class AdminReelsStatsCard extends ConsumerWidget {
  const AdminReelsStatsCard({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(adminReelsStatsProvider).when(loading: () => const LinearProgressIndicator(), error: (_, __) => const SizedBox.shrink(), data: (data) {
    final flag = Map<String, dynamic>.from(data['flag'] as Map? ?? const {});
    final top = data['top_7d'] as List? ?? const [];
    return AdminDetailCard(title: 'reels.admin.title'.tr(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.sm, children: [AdminLabelValueRow(label: 'reels.admin.published'.tr(), value: '${data['published'] ?? 0}'), AdminLabelValueRow(label: 'reels.admin.published_7d'.tr(), value: '${data['published_7d'] ?? 0}'), AdminLabelValueRow(label: 'reels.admin.failed_7d'.tr(), value: '${data['failed_7d'] ?? 0}'), AdminLabelValueRow(label: 'reels.admin.minutes'.tr(), value: '${data['minutes_stored'] ?? 0}'), AdminLabelValueRow(label: 'reels.admin.views_7d'.tr(), value: '${data['views_7d'] ?? 0}')]),
      TextButton(onPressed: () => context.go('/admin/system'), child: Text('reels.admin.flag'.tr(namedArgs: {'enabled': (flag['is_enabled'] == true ? 'admin.system.active' : 'admin.system.inactive').tr(), 'rollout': '${flag['rollout_percentage'] ?? 0}'}))),
      for (final raw in top.take(5)) ListTile(contentPadding: EdgeInsets.zero, title: Text(Map<String, dynamic>.from(raw as Map)['caption']?.toString() ?? 'reels.caption_empty'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Text('${Map<String, dynamic>.from(raw)['views'] ?? 0}'), onTap: () { final id = Map<String, dynamic>.from(raw)['post_id']; if (id != null) context.go('/admin/content?id=$id'); }),
    ]));
  });
}

class ContentFilters extends StatelessWidget {
  final int tab;
  final String? status;
  final String? kind;
  final String? visibility;
  final String? country;
  final bool? sensitive;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String?> onKind;
  final ValueChanged<String?> onVisibility;
  final ValueChanged<String?> onCountry;
  final ValueChanged<bool?> onSensitive;
  const ContentFilters({super.key, required this.tab, required this.status, required this.kind, required this.visibility, required this.country, required this.sensitive, required this.onSearch, required this.onStatus, required this.onKind, required this.onVisibility, required this.onCountry, required this.onSensitive});

  @override Widget build(BuildContext context) {
    final statuses = tab == 1 ? const ['active','expired','removed'] : const ['published','hidden','removed'];
    return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
      SizedBox(width: 250, child: HBInput(hint: tab == 1 ? 'admin.p05d.searchAuthor'.tr() : 'admin.p05d.searchContent'.tr(), prefixIcon: const Icon(Icons.search), onChanged: onSearch)),
      AdminValueFilter(label: status == null ? 'admin.p05d.status'.tr() : 'admin.p05d.statuses.$status'.tr(), values: statuses, scope: 'admin.p05d.statuses', onChanged: onStatus),
      if (tab < 2) AdminValueFilter(label: kind == null ? 'admin.p05d.kind'.tr() : 'admin.p05d.kinds.$kind'.tr(), values: tab == 0 ? const ['text','photo','video','poll','checkin'] : const ['image','video'], scope: 'admin.p05d.kinds', onChanged: onKind),
      if (tab == 0) AdminValueFilter(label: visibility == null ? 'admin.p05d.visibility'.tr() : 'admin.p05d.visibilities.$visibility'.tr(), values: const ['public','followers','group'], scope: 'admin.p05d.visibilities', onChanged: onVisibility),
      if (tab < 2) AdminValueFilter(label: country ?? 'admin.p05d.country'.tr(), values: const ['IT','FR','ES','DE','AT','GB'], onChanged: onCountry),
      if (tab == 0) AdminBoolFilter(value: sensitive, onChanged: onSensitive),
    ]);
  }
}

class AdminValueFilter extends StatelessWidget {
  final String label;
  final List<String> values;
  final String? scope;
  final ValueChanged<String?> onChanged;
  const AdminValueFilter({super.key, required this.label, required this.values, this.scope, required this.onChanged});
  @override Widget build(BuildContext context) => AdminCompactDropdown(label: label, items: ['admin.p05b.all'.tr(), for (final value in values) scope == null ? value : '$scope.$value'.tr()], onSelected: (index) => onChanged(index == 0 ? null : values[index - 1]));
}

class AdminBoolFilter extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?> onChanged;
  const AdminBoolFilter({super.key, required this.value, required this.onChanged});
  @override Widget build(BuildContext context) => AdminCompactDropdown(label: value == null ? 'admin.p05d.sensitive'.tr() : (value! ? 'admin.p05c.yes' : 'admin.p05c.no').tr(), items: ['admin.p05b.all'.tr(), 'admin.p05c.yes'.tr(), 'admin.p05c.no'.tr()], onSelected: (index) => onChanged(index == 0 ? null : index == 1));
}

class AdminContentTable extends StatelessWidget {
  final int tab;
  final List<Object> items;
  final bool isLoading;
  final ValueChanged<Object> onSelected;
  const AdminContentTable({super.key, required this.tab, required this.items, required this.isLoading, required this.onSelected});
  @override Widget build(BuildContext context) {
    if (tab == 0) return AdminDataTable(headers: [for (final key in ['author','excerpt','kind','media','reactions','comments','visibility','context','sensitive','status','published']) 'admin.p05d.postColumns.$key'.tr()], columnWidths: const [180,220,90,80,85,85,100,140,100,100,130], rows: [for (final raw in items) _postCells(context, raw as AdminPostRecord)], rowCallbacks: [for (final item in items) () => onSelected(item)], emptyMessage: 'admin.p05d.contentEmpty'.tr(), isLoading: isLoading);
    if (tab == 1) return AdminDataTable(headers: [for (final key in ['author','preview','caption','views','expires','status']) 'admin.p05d.storyColumns.$key'.tr()], columnWidths: const [190,70,260,100,140,110], rows: [for (final raw in items) _storyCells(context, raw as AdminStoryRecord)], rowCallbacks: [for (final item in items) () => onSelected(item)], emptyMessage: 'admin.p05d.contentEmpty'.tr(), isLoading: isLoading);
    return AdminDataTable(headers: [for (final key in ['author','text','post','reactions','status','created']) 'admin.p05d.commentColumns.$key'.tr()], columnWidths: const [190,300,210,100,110,130], rows: [for (final raw in items) _commentCells(context, raw as AdminCommentRecord)], rowCallbacks: [for (final item in items) () => onSelected(item)], emptyMessage: 'admin.p05d.contentEmpty'.tr(), isLoading: isLoading);
  }

  List<Widget> _postCells(BuildContext context, AdminPostRecord item) => [AdminPersonCell(person: AdminPerson(id: item.post.author.id, username: item.post.author.username, displayName: item.post.author.displayName, avatarUrl: item.post.author.avatarUrl), avatarSize: 24, showUsername: false), Text(excerpt(item.post.content, 80)), Text('admin.p05d.kinds.${item.post.kind}'.tr()), Row(children: [const Icon(Icons.perm_media_outlined, size: 16), Text(' ${item.post.media.length}')]), Text('${item.post.reactionCount}'), Text('${item.post.commentCount}'), Text('admin.p05d.visibilities.${item.visibility}'.tr()), Text(item.groupName ?? item.pageName ?? 'common.unavailable'.tr()), item.isSensitive ? HBStatusChip(kind: HBStatusKind.pending, label: 'admin.p05d.sensitive'.tr()) : const AdminDashText(), AdminStatusValueChip(scope: 'admin.p05d.statuses', value: item.status), Text(relativeTime(context, item.post.createdAt))];
  List<Widget> _storyCells(BuildContext context, AdminStoryRecord item) => [AdminPersonCell(person: item.author, avatarSize: 24, showUsername: false), ClipRRect(borderRadius: BorderRadius.circular(AppRadius.xs), child: Image.network(item.mediaUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 40, height: 40, child: Icon(Icons.broken_image_outlined)))), Text(item.caption ?? 'common.unavailable'.tr(), maxLines: 2, overflow: TextOverflow.ellipsis), Text('${item.viewCount}'), Text(item.expiresAt.isBefore(DateTime.now()) ? 'admin.p05d.expired'.tr() : relativeTime(context, item.expiresAt)), AdminStatusValueChip(scope: 'admin.p05d.statuses', value: item.status)];
  List<Widget> _commentCells(BuildContext context, AdminCommentRecord item) => [AdminPersonCell(person: item.author, avatarSize: 24, showUsername: false), Text(excerpt(item.content, 100), maxLines: 2, overflow: TextOverflow.ellipsis), TextButton(onPressed: () => context.go('/admin/content?id=${item.postId}'), child: Text(excerpt(item.postExcerpt, 40))), Text('${item.reactionCount}'), AdminStatusValueChip(scope: 'admin.p05d.statuses', value: item.status), Text(relativeTime(context, item.createdAt))];
}

class AdminContentDetailPanel extends ConsumerWidget {
  final Object record;
  final VoidCallback onClose;
  const AdminContentDetailPanel({super.key, required this.record, required this.onClose});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = ref.watch(adminAccessProvider).valueOrNull?.canWrite('content') ?? false;
    if (record is AdminPostRecord) return AdminPostDetailPanel(record: record as AdminPostRecord, canWrite: canWrite, onClose: onClose);
    if (record is AdminStoryRecord) {
      final story = record as AdminStoryRecord;
      return AdminDetailPanel(title: story.author.displayName, status: AdminStatusValueChip(scope: 'admin.p05d.statuses', value: story.status), onClose: onClose, actions: canWrite ? [const P41Action(labelKey: 'admin.p05d.actions.remove')] : const [], body: Column(children: [AdminDetailCard(title: 'admin.p05d.story'.tr(), child: Image.network(story.mediaUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Text('feed.media_unavailable'.tr()))), if (story.caption != null) AdminDetailCard(title: 'admin.p05d.caption'.tr(), child: Text(story.caption!))]));
    }
    final comment = record as AdminCommentRecord;
    return AdminDetailPanel(title: comment.author.displayName, status: AdminStatusValueChip(scope: 'admin.p05d.statuses', value: comment.status), onClose: onClose, actions: canWrite ? const [P41Action(labelKey: 'admin.p05d.actions.hide'), P41Action(labelKey: 'admin.p05d.actions.remove')] : const [], body: Column(children: [AdminDetailCard(title: 'admin.p05d.comment'.tr(), child: Text(comment.content)), AdminDetailCard(title: 'admin.p05d.referencePost'.tr(), child: TextButton(onPressed: () => context.go('/admin/content?id=${comment.postId}'), child: Text(excerpt(comment.postExcerpt, 80))))]));
  }
}

class AdminPostDetailPanel extends ConsumerWidget {
  final AdminPostRecord record;
  final bool canWrite;
  final VoidCallback onClose;
  const AdminPostDetailPanel({super.key, required this.record, required this.canWrite, required this.onClose});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(adminPostDetailProvider(record.post.id));
    return AdminDetailPanel(title: record.post.author.displayName, status: AdminStatusValueChip(scope: 'admin.p05d.statuses', value: record.status), onClose: onClose, actions: canWrite ? const [P41Action(labelKey: 'admin.p05d.actions.hide'), P41Action(labelKey: 'admin.p05d.actions.remove'), P41Action(labelKey: 'admin.p05d.actions.sensitive'), P41Action(labelKey: 'admin.p05d.actions.warn')] : const [], body: Column(children: [
      Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => context.go('/admin/users?id=${record.post.author.id}'), icon: const Icon(Icons.person_outline), label: Text('admin.p05d.openAuthor'.tr()))),
      FeedPostCard(post: record.post),
      if (record.post.media.length > 1) AdminMediaGrid(media: record.post.media.skip(1).map((item) => item.url).toList()),
      detail.when(loading: () => const LinearProgressIndicator(), error: (_, __) => Text('admin.p05b.detailError'.tr()), data: (value) => Column(children: [AdminDetailCard(title: 'admin.p05d.commentsFirst'.tr(), child: value.comments.isEmpty ? Text('admin.p05d.noComments'.tr()) : Column(children: [for (final item in value.comments) ListTile(contentPadding: EdgeInsets.zero, title: Text(item.author.displayName), subtitle: Text(item.content), trailing: AdminStatusValueChip(scope: 'admin.p05d.statuses', value: item.status))])), AdminDetailCard(title: 'admin.p05d.reports'.tr(), child: value.reports.isEmpty ? Text('admin.p05b.noReports'.tr()) : Column(children: [for (final item in value.reports) AdminLabelValueRow(label: item.reporter?.displayName ?? 'common.unavailable'.tr(), value: 'admin.p05.reasons.${item.reason}'.tr())]))])),
    ]));
  }
}

class AdminMediaGrid extends StatelessWidget {
  final List<String> media;
  const AdminMediaGrid({super.key, required this.media});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm, children: [for (final url in media) Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined))]));
}

class P41Action extends StatelessWidget {
  final String labelKey;
  const P41Action({super.key, required this.labelKey});
  @override Widget build(BuildContext context) => Tooltip(message: 'admin.p05d.availableP41'.tr(), child: HBButton.secondary(label: labelKey.tr(), onPressed: null, size: HBButtonSize.sm));
}

String excerpt(String? value, int max) {
  final firstLine = (value ?? '').split('\n').first.trim();
  if (firstLine.isEmpty) return '—';
  return firstLine.length <= max ? firstLine : '${firstLine.substring(0, max - 1)}…';
}