import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/admin/data/admin_list_repository.dart';
import 'package:hb_social/features/admin/domain/admin_list_models.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_detail_panel.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_read_only_widgets.dart';
import 'package:hb_social/features/admin/providers/admin_console_providers.dart';

class AdminAuditLogPage extends ConsumerStatefulWidget {
  const AdminAuditLogPage({super.key});
  @override ConsumerState<AdminAuditLogPage> createState() => _AdminAuditLogPageState();
}

class _AdminAuditLogPageState extends ConsumerState<AdminAuditLogPage> {
  String? action;
  String? resourceType;
  String? adminId;
  int periodDays = 0;
  String search = '';
  AdminAuditRecord? selected;
  Timer? debounce;

  @override void dispose() { debounce?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final now = DateTime.now();
    final since = switch (periodDays) { 1 => DateTime(now.year, now.month, now.day), 7 || 30 => now.subtract(Duration(days: periodDays)), _ => null };
    final filters = AdminAuditFilters(action: action, resourceType: resourceType, adminId: adminId, since: since, search: search);
    final audit = ref.watch(adminAuditProvider(filters));
    final state = audit.value;
    final items = state?.items ?? const <AdminAuditRecord>[];
    final count = state == null ? null : ref.read(adminAuditProvider(filters).notifier).count;
    final options = ref.watch(adminAuditOptionsProvider).valueOrNull;
    return Stack(children: [
      AdminListPage(title: 'p40.audit.title'.tr(), description: 'p40.audit.results'.tr(namedArgs: {'count': count?.toString() ?? '—'}), filters: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(width: 250, child: HBInput(hint: 'admin.p05c.auditSearch'.tr(), prefixIcon: const Icon(Icons.search), onChanged: _search)),
          AuditDropdown(label: action ?? 'admin.p05c.action'.tr(), values: options?.actions ?? const [], onChanged: (value) => setState(() => action = value)),
          AuditDropdown(label: resourceType ?? 'admin.p05c.resource'.tr(), values: options?.resourceTypes ?? const [], onChanged: (value) => setState(() => resourceType = value)),
          AuditDropdown(label: adminId == null ? 'admin.p05c.admin'.tr() : options?.admins.where((item) => item.id == adminId).firstOrNull?.displayName ?? 'admin.p05c.admin'.tr(), values: options?.admins.map((item) => item.id).toList() ?? const [], labels: {for (final admin in options?.admins ?? const <AdminPerson>[]) admin.id: admin.displayName}, onChanged: (value) => setState(() => adminId = value)),
          AuditDropdown(label: 'admin.p05c.period.$periodDays'.tr(), values: const ['1','7','30','0'], labels: {for (final value in ['1','7','30','0']) value: 'admin.p05c.period.$value'.tr()}, includeAll: false, onChanged: (value) => setState(() => periodDays = int.parse(value!))),
        ]), emptyMessage: 'admin.p05.activityEmpty'.tr(), content: AdminAuditTable(items: items, isLoading: audit.isLoading, onSelected: (item) => setState(() => selected = item)), onRetry: audit.hasError && state == null ? () => ref.invalidate(adminAuditProvider(filters)) : null, hasMore: state?.hasMore ?? false, isLoadingMore: state?.isLoadingMore ?? false, onLoadMore: () => ref.read(adminAuditProvider(filters).notifier).loadMore()),
      if (selected != null) AdminDetailOverlay(onClose: () => setState(() => selected = null), panel: AdminAuditDetailPanel(record: selected!, onClose: () => setState(() => selected = null))),
    ]);
  }

  void _search(String value) { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 300), () { if (mounted) setState(() => search = value); }); }
}

class AuditDropdown extends StatelessWidget {
  final String label;
  final List<String> values;
  final Map<String, String> labels;
  final bool includeAll;
  final ValueChanged<String?> onChanged;
  const AuditDropdown({super.key, required this.label, required this.values, this.labels = const {}, this.includeAll = true, required this.onChanged});
  @override Widget build(BuildContext context) {
    final entries = <String?>[if (includeAll) null, ...values];
    return AdminCompactDropdown(label: label, items: [for (final value in entries) value == null ? 'admin.p05b.all'.tr() : labels[value] ?? value], onSelected: (index) => onChanged(entries[index]));
  }
}

class AdminAuditTable extends StatelessWidget {
  final List<AdminAuditRecord> items;
  final bool isLoading;
  final ValueChanged<AdminAuditRecord> onSelected;
  const AdminAuditTable({super.key, required this.items, required this.isLoading, required this.onSelected});
  @override Widget build(BuildContext context) => AdminDataTable(headers: [for (final key in ['date','admin','action','resource','id','changes']) 'admin.p05c.auditColumns.$key'.tr()], columnWidths: const [150,220,150,140,220,320], rows: [for (final item in items) [Text(relativeTime(context, item.createdAt)), item.admin == null ? Text('admin.p05.unknownAdmin'.tr()) : AdminPersonCell(person: item.admin!), Text(translatedAuditAction(item.action)), Text(item.resourceType ?? 'common.unavailable'.tr()), Text(item.resourceId ?? 'common.unavailable'.tr(), overflow: TextOverflow.ellipsis), AuditChangesSummary(changes: auditChanges(item.changes))]], rowCallbacks: [for (final item in items) () => onSelected(item)], emptyMessage: 'admin.p05.activityEmpty'.tr(), isLoading: isLoading);
}

class AuditChangesSummary extends StatelessWidget {
  final List<AuditFieldChange> changes;
  const AuditChangesSummary({super.key, required this.changes});
  @override Widget build(BuildContext context) {
    final visible = changes.take(2).toList();
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [for (final change in visible) Text('${change.field}: ${change.before} → ${change.after}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall), if (changes.length > 2) Text('+${changes.length - 2}', style: context.textStyles.labelSmall?.bold)]);
  }
}

class AdminAuditDetailPanel extends StatelessWidget {
  final AdminAuditRecord record;
  final VoidCallback onClose;
  const AdminAuditDetailPanel({super.key, required this.record, required this.onClose});
  @override Widget build(BuildContext context) {
    final changes = auditChanges(record.changes);
    final resourcePath = auditResourcePath(record);
    return AdminDetailPanel(title: translatedAuditAction(record.action), onClose: onClose, actions: const [], body: Column(children: [
      AdminDetailCard(title: 'admin.p05c.auditDetail'.tr(), child: Column(children: [AdminLabelValueRow(label: 'admin.p05c.auditColumns.date'.tr(), value: DateFormat.yMd(context.locale.toString()).add_Hm().format(record.createdAt.toLocal())), AdminLabelValueRow(label: 'admin.p05c.auditColumns.admin'.tr(), value: record.admin?.displayName ?? 'admin.p05.unknownAdmin'.tr()), AdminLabelValueRow(label: 'admin.p05c.auditColumns.resource'.tr(), value: record.resourceType ?? 'common.unavailable'.tr()), AdminLabelValueRow(label: 'admin.p05c.auditColumns.id'.tr(), value: record.resourceId ?? 'common.unavailable'.tr()), if (resourcePath != null) Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => context.go(resourcePath), icon: const Icon(Icons.open_in_new, size: 16), label: Text('admin.p05c.openResource'.tr())))])),
      AdminDetailCard(title: 'admin.p05c.changes'.tr(), child: AdminDataTable(headers: [for (final key in ['field','before','after']) 'admin.p05c.changeColumns.$key'.tr()], columnWidths: const [120,120,120], rows: [for (final change in changes) [Text(change.field), Text(change.before), Text(change.after)]], emptyMessage: 'common.unavailable'.tr())),
    ]));
  }
}

class AuditFieldChange {
  final String field;
  final String before;
  final String after;
  const AuditFieldChange(this.field, this.before, this.after);
}

List<AuditFieldChange> auditChanges(Map<String, dynamic>? raw) {
  if (raw == null) return const [];
  final before = raw['before'] is Map ? Map<String, dynamic>.from(raw['before'] as Map) : const <String, dynamic>{};
  final after = raw['after'] is Map ? Map<String, dynamic>.from(raw['after'] as Map) : const <String, dynamic>{};
  if (before.isNotEmpty || after.isNotEmpty) return [for (final key in {...before.keys, ...after.keys}) AuditFieldChange(key, auditValue(before[key]), auditValue(after[key]))];
  return [for (final entry in raw.entries) entry.value is Map ? AuditFieldChange(entry.key, auditValue((entry.value as Map)['before']), auditValue((entry.value as Map)['after'])) : AuditFieldChange(entry.key, 'common.unavailable'.tr(), auditValue(entry.value))];
}

String auditValue(dynamic value) => value == null ? 'common.unavailable'.tr() : value.toString();
String translatedAuditAction(String value) {
  if (value == 'verification.approve') return 'admin.approvals.audit.approve'.tr();
  if (value == 'verification.reject') return 'admin.approvals.audit.reject'.tr();
  const known = {'login','logout','view','create','update','delete','approve','reject'};
  return (known.contains(value) ? 'admin.p05.auditActions.$value' : 'admin.p05.auditActions.other').tr();
}
String? auditResourcePath(AdminAuditRecord record) => switch (record.resourceType) { 'user' => '/admin/users?id=${record.resourceId}', 'report' => '/admin/reports?id=${record.resourceId}', 'verification_request' => '/admin/approvals?id=${record.resourceId}', 'listing' => '/admin/listings?id=${record.resourceId}', 'page' when record.resourceSlug != null => '/pages/${record.resourceSlug}', _ => null };