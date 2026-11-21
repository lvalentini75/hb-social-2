import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/domain/admin_access.dart';
import 'package:hb_social/features/admin/domain/admin_p41_models.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_detail_panel.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/providers/admin_p41_providers.dart';

class AdminReportsPage extends ConsumerStatefulWidget {
  final String? initialId;
  const AdminReportsPage({super.key, this.initialId});
  @override ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  String status = 'open';
  String? priority;
  String assigned = 'any';
  String? targetType;
  String query = '';
  String? selectedId;
  Timer? debounce;
  late Future<List<AdminReportQueueItem>> future;
  @override void initState() { super.initState(); selectedId = widget.initialId; future = _load(); }
  @override void dispose() { debounce?.cancel(); super.dispose(); }
  Future<List<AdminReportQueueItem>> _load() => ref.read(adminP41RepositoryProvider).reports(status: status, priority: priority, assigned: assigned, targetType: targetType, query: query);
  void _reload() { setState(() => future = _load()); ref.invalidate(adminModerationStatsProvider); }

  @override Widget build(BuildContext context) {
    final stats = ref.watch(adminModerationStatsProvider).value;
    final access = ref.watch(adminAccessProvider).value;
    return Stack(children: [FutureBuilder<List<AdminReportQueueItem>>(future: future, builder: (context, snapshot) => AdminListPage(
      title: 'admin.reports.title'.tr(), description: 'admin.reports.description'.tr(),
      filters: AdminReportsP41Filters(status: status, priority: priority, assigned: assigned, targetType: targetType, onStatus: (value) { status = value; _reload(); }, onPriority: (value) { priority = value; _reload(); }, onAssigned: (value) { assigned = value; _reload(); }, onTargetType: (value) { targetType = value; _reload(); }, onQuery: (value) { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 350), () { query = value; _reload(); }); }),
      kpis: [AdminKpiValue(label: 'admin.reports.kpi.open'.tr(), value: '${stats?.open ?? 0}'), AdminKpiValue(label: 'admin.reports.kpi.overdue'.tr(), value: '${stats?.overdue ?? 0}'), AdminKpiValue(label: 'admin.reports.kpi.due_soon'.tr(), value: '${stats?.dueSoon ?? 0}'), AdminKpiValue(label: 'admin.reports.kpi.mine'.tr(), value: '${stats?.mine ?? 0}'), AdminKpiValue(label: 'admin.reports.kpi.resolved_today'.tr(), value: '${stats?.resolvedToday ?? 0}'), AdminKpiValue(label: 'admin.reports.kpi.within_sla'.tr(), value: '${stats?.withinSlaPercent.toStringAsFixed(0) ?? '0'}%'), AdminKpiValue(label: 'admin.reports.kpi.average'.tr(), value: '${stats?.averageResolutionHours.toStringAsFixed(1) ?? '0'} h')],
      emptyMessage: 'admin.reports.empty'.tr(),
      content: snapshot.connectionState == ConnectionState.waiting ? const LinearProgressIndicator() : snapshot.hasError ? HBEmptyState(icon: Icons.error_outline, title: 'admin.reports.load_error'.tr(), message: 'errors.network'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: _reload)) : Column(children: [for (final report in snapshot.data ?? const <AdminReportQueueItem>[]) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: AdminReportQueueCard(item: report, onOpen: () => setState(() => selectedId = report.id), onAssign: access?.canWrite('reports') == true && report.assignedTo == null ? () => _assign(report.id) : null)), if (snapshot.data?.isEmpty == true) HBEmptyState(icon: Icons.task_alt, title: 'admin.reports.empty'.tr(), message: 'admin.reports.empty_help'.tr())]),
    )), if (selectedId != null) AdminDetailOverlay(onClose: () => setState(() => selectedId = null), panel: AdminReportP41Panel(reportId: selectedId!, access: access, onClose: () => setState(() => selectedId = null), onResolved: _resolved))]);
  }

  Future<void> _assign(String id) async { try { await ref.read(adminP41RepositoryProvider).assignReport(id); _reload(); if (mounted) setState(() => selectedId = id); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
  void _resolved(ReportResolutionResult result) { setState(() { selectedId = null; future = _load(); }); ref.invalidate(adminModerationStatsProvider); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.reports.resolved_success'.tr(namedArgs: {'resolution': 'admin.reports.resolution.${result.resolution}'.tr(), 'count': '${result.closedReports}'})))); }
}

class AdminReportsP41Filters extends StatelessWidget {
  final String status, assigned;
  final String? priority, targetType;
  final ValueChanged<String> onStatus, onAssigned;
  final ValueChanged<String?> onPriority, onTargetType;
  final ValueChanged<String> onQuery;
  const AdminReportsP41Filters({super.key, required this.status, required this.priority, required this.assigned, required this.targetType, required this.onStatus, required this.onPriority, required this.onAssigned, required this.onTargetType, required this.onQuery});
  @override Widget build(BuildContext context) { const statuses = ['open','pending','in_progress','resolved','all']; const priorities = ['high','medium','low']; const assignments = ['any','me','unassigned']; const types = ['post','comment','reply','listing','profile','thread','group','page','event','ad']; return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [SizedBox(width: 500, child: HBSegmentedTabs(labels: [for (final value in statuses) 'admin.reports.status.$value'.tr()], selectedIndex: statuses.indexOf(status), onChanged: (i) => onStatus(statuses[i]))), AdminCompactDropdown(label: priority == null ? 'admin.reports.table.priority'.tr() : 'admin.reports.priority.$priority'.tr(), items: [for (final v in priorities) 'admin.reports.priority.$v'.tr()], onSelected: (i) => onPriority(priorities[i])), AdminCompactDropdown(label: 'admin.reports.assigned.$assigned'.tr(), items: [for (final v in assignments) 'admin.reports.assigned.$v'.tr()], onSelected: (i) => onAssigned(assignments[i])), AdminCompactDropdown(label: targetType == null ? 'admin.reports.targetLabel'.tr() : 'admin.reports.target.$targetType'.tr(), items: [for (final v in types) 'admin.reports.target.$v'.tr()], onSelected: (i) => onTargetType(types[i])), SizedBox(width: 220, child: HBInput(hint: 'admin.reports.search'.tr(), prefixIcon: const Icon(Icons.search, size: 18), onChanged: onQuery))]); }
}

class AdminReportQueueCard extends ConsumerWidget {
  final AdminReportQueueItem item;
  final VoidCallback onOpen;
  final VoidCallback? onAssign;
  const AdminReportQueueCard({super.key, required this.item, required this.onOpen, this.onAssign});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final preview = item.preview;
    final path = preview['image_path']?.toString();
    final bucket = preview['bucket']?.toString();
    final direct = preview['image_url']?.toString();
    final imageUrl = direct ?? (path == null || bucket == null ? null : storagePublicUrl(ref.watch(supabaseClientProvider), bucket, path));
    final slaColor = switch (item.slaStatus) { 'overdue' => LightModeColors.lightError, 'due_soon' => LightModeColors.lightWarning, 'closed' => LightModeColors.lightTextTertiary, _ => LightModeColors.bosco };
    final content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: AppSpacing.xs, children: [HBStatusChip(kind: item.priority == 'high' ? HBStatusKind.rejected : item.priority == 'medium' ? HBStatusKind.pending : HBStatusKind.neutral, label: 'admin.reports.priority.${item.priority}'.tr()), HBStatusChip(kind: HBStatusKind.info, label: 'admin.reports.target.${item.targetType}'.tr())]),
      const SizedBox(height: AppSpacing.xs),
      Text(preview['exists'] == false ? 'admin.reports.content_unavailable'.tr() : '${preview['title'] ?? preview['text'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall?.bold),
      Text('admin.reports.reason.${item.reason}'.tr(), maxLines: 2, overflow: TextOverflow.ellipsis),
      Text('admin.reports.reporter_meta'.tr(namedArgs: {'name': item.reporterName ?? 'common.unavailable'.tr(), 'time': item.createdAt == null ? '' : relativeTime(context, item.createdAt!)}), style: context.textStyles.bodySmall),
      if (item.duplicates > 1) Text('admin.reports.duplicates'.tr(namedArgs: {'count': '${item.duplicates - 1}'}), style: context.textStyles.bodySmall),
    ]);
    final owner = SizedBox(width: 190, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.authorName ?? 'common.unavailable'.tr(), style: context.textStyles.bodyMedium?.bold), if (item.activeStrikes > 0) HBStatusChip(kind: HBStatusKind.rejected, label: 'admin.reports.strikes'.tr(namedArgs: {'count': '${item.activeStrikes}'})), Text(item.slaStatus == 'overdue' ? 'admin.reports.overdue_by'.tr(namedArgs: {'minutes': '${item.minutesLeft.abs()}'}) : 'admin.reports.due_in'.tr(namedArgs: {'minutes': '${item.minutesLeft}'}), style: context.textStyles.bodySmall?.copyWith(color: slaColor)), if (item.assigneeName != null) Text(item.assigneeName!, style: context.textStyles.bodySmall) else if (onAssign != null) HBButton.soft(label: 'admin.reports.take'.tr(), size: HBButtonSize.sm, onPressed: onAssign)]));
    return HBCard(padding: EdgeInsets.zero, child: InkWell(onTap: onOpen, child: IntrinsicHeight(child: Row(children: [Container(width: 5, color: slaColor), Expanded(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [if (imageUrl != null) ...[ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: Image.network(imageUrl, width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 72, height: 72))), const SizedBox(width: AppSpacing.md)], Expanded(child: content), const SizedBox(width: AppSpacing.md), owner])))]))));
  }
}

class AdminReportP41Panel extends ConsumerWidget {
  final String reportId;
  final AdminAccess? access;
  final VoidCallback onClose;
  final ValueChanged<ReportResolutionResult> onResolved;
  const AdminReportP41Panel({super.key, required this.reportId, required this.access, required this.onClose, required this.onResolved});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(adminP41ReportDetailProvider(reportId));
    return AdminDetailPanel(title: 'admin.reports.detailTitle'.tr(), onClose: onClose, body: detail.when(loading: () => const LinearProgressIndicator(), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'admin.reports.load_error'.tr(), message: 'errors.network'.tr()), data: (value) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [AdminReportPreviewCard(preview: value.preview), const SizedBox(height: AppSpacing.md), Text('admin.reports.same_target'.tr(namedArgs: {'count': '${value.sameTarget.length}'}), style: context.textStyles.titleMedium?.bold), for (final report in value.sameTarget) ListTile(title: Text('admin.reports.reason.${report['reason'] ?? 'other'}'.tr()), subtitle: Text('${report['reporter_name'] ?? ''}')), const SizedBox(height: AppSpacing.md), Text('admin.reports.author_history'.tr(), style: context.textStyles.titleMedium?.bold), for (final row in value.strikes) ListTile(title: Text('safety.reasons.${row['reason'] ?? 'other'}'.tr()), subtitle: Text('${row['status'] ?? ''}')), if (access?.canWrite('reports') == true) ...[const Divider(), AdminReportResolutionActions(reportId: reportId, targetType: '${value.report['target_type'] ?? ''}', canBan: access?.roleName == 'admin' || access?.roleName == 'superadmin', onResolved: onResolved)] ])), actions: const []);
  }
}

class AdminReportPreviewCard extends StatelessWidget {
  final Map<String, dynamic> preview;
  const AdminReportPreviewCard({super.key, required this.preview});
  @override Widget build(BuildContext context) => HBCard(color: LightModeColors.surfaceSoft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.reports.reportedContent'.tr(), style: context.textStyles.titleMedium?.bold), const SizedBox(height: AppSpacing.sm), Text(preview['exists'] == false ? 'admin.reports.content_unavailable'.tr() : '${preview['title'] ?? ''}', style: context.textStyles.titleSmall?.bold), if (preview['text'] != null) Text('${preview['text']}', maxLines: 6, overflow: TextOverflow.ellipsis), if (preview['status'] != null) HBStatusChip(kind: HBStatusKind.neutral, label: '${preview['status']}') ]));
}

class AdminReportResolutionActions extends StatelessWidget {
  final String reportId;
  final String targetType;
  final bool canBan;
  final ValueChanged<ReportResolutionResult> onResolved;
  const AdminReportResolutionActions({super.key, required this.reportId, required this.targetType, required this.canBan, required this.onResolved});
  @override Widget build(BuildContext context) => Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final action in ['dismiss', if (targetType != 'profile') 'hide', if (targetType != 'profile') 'remove', 'strike', 'suspend', if (canBan) 'ban']) HBButton.soft(label: 'admin.reports.actions.$action'.tr(), icon: action == 'ban' || action == 'remove' ? Icons.warning_amber : null, onPressed: () => showDialog<void>(context: context, builder: (_) => ReportResolutionDialog(reportId: reportId, action: action, onResolved: onResolved)))]);
}

class ReportResolutionDialog extends ConsumerStatefulWidget {
  final String reportId;
  final String action;
  final ValueChanged<ReportResolutionResult> onResolved;
  const ReportResolutionDialog({super.key, required this.reportId, required this.action, required this.onResolved});
  @override ConsumerState<ReportResolutionDialog> createState() => _ReportResolutionDialogState();
}

class _ReportResolutionDialogState extends ConsumerState<ReportResolutionDialog> {
  final note = TextEditingController();
  int days = 7;
  bool saving = false;
  @override void dispose() { note.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AlertDialog(title: Text('admin.reports.actions.${widget.action}'.tr()), content: SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: [if (widget.action == 'strike' || widget.action == 'suspend') Wrap(spacing: AppSpacing.sm, children: [for (final value in [1,3,7,30]) ChoiceChip(label: Text('admin.users.days'.tr(namedArgs: {'days': '$value'})), selected: days == value, onSelected: (_) => setState(() => days = value))]), const SizedBox(height: AppSpacing.sm), HBInput(controller: note, hint: 'admin.reports.note'.tr(), maxLines: 4, maxLength: 1000), if (widget.action == 'remove') Text('admin.reports.remove_strike_help'.tr())])), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: saving ? null : () => context.pop()), HBButton.primary(label: 'common.confirm'.tr(), isLoading: saving, onPressed: saving ? null : _submit)]);
  Future<void> _submit() async { if (!const {'dismiss','hide'}.contains(widget.action) && note.text.trim().isEmpty) return; setState(() => saving = true); try { final result = await ref.read(adminP41RepositoryProvider).resolveReport(widget.reportId, widget.action, note: note.text, strikeDays: widget.action == 'strike' ? days : null, suspendDays: widget.action == 'suspend' ? days : null); if (mounted) context.pop(); widget.onResolved(result); } on AppException catch (error) { if (mounted) { setState(() => saving = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } } }
}