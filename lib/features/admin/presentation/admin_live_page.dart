import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/features/admin/domain/admin_live.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/providers/admin_live_providers.dart';

class AdminLivePage extends ConsumerStatefulWidget {
  const AdminLivePage({super.key});
  @override ConsumerState<AdminLivePage> createState() => _AdminLivePageState();
}

class _AdminLivePageState extends ConsumerState<AdminLivePage> {
  int selected = 0;
  String? get status => switch (selected) { 0 => 'live', 1 => 'ended', 2 => 'scheduled', _ => null };
  @override Widget build(BuildContext context) {
    final value = ref.watch(adminLiveListProvider(status));
    final items = value.value ?? const <AdminLiveRecord>[];
    return AdminListPage(title: 'admin_live.title'.tr(), description: 'admin_live.subtitle'.tr(), filters: HBSegmentedTabs(labels: ['admin_live.filters.live'.tr(), 'admin_live.filters.ended'.tr(), 'admin_live.filters.scheduled'.tr(), 'admin_live.filters.all'.tr()], selectedIndex: selected, onChanged: (index) => setState(() => selected = index)), emptyMessage: 'admin_live.empty'.tr(), content: value.hasError ? HBEmptyState(icon: Icons.error_outline, title: 'admin_live.error'.tr(), message: 'admin_live.error_message'.tr()) : AdminDataTable(headers: ['admin_live.columns.title'.tr(), 'admin_live.columns.host'.tr(), 'admin_live.columns.viewers'.tr(), 'admin_live.columns.messages'.tr(), 'admin_live.columns.start'.tr(), 'admin_live.columns.duration'.tr(), 'admin_live.columns.outcome'.tr(), 'admin_live.columns.actions'.tr()], columnWidths: const [220,160,160,90,140,100,120,200], rows: [for (final item in items) [Text(item.title), Text(item.hostName), Text('${item.viewerCount} / ${item.peakViewers} / ${item.totalViewers}'), Text('${item.messageCount}'), Text(item.startedAt == null ? '—' : relativeTime(context, item.startedAt!)), Text('${item.durationSeconds}s'), Text(item.outcome ?? item.status), Wrap(spacing: 4, children: [HBButton.ghost(label: 'admin_live.open'.tr(), size: HBButtonSize.sm, onPressed: () => context.push(AppRoutes.livePath(item.id))), if (item.status == 'live' && (ref.watch(adminAccessProvider).value?.canWrite('content') ?? false)) HBButton.secondary(label: 'admin_live.end'.tr(), size: HBButtonSize.sm, onPressed: () => _end(item))])]], emptyMessage: 'admin_live.empty'.tr(), isLoading: value.isLoading));
  }
  Future<void> _end(AdminLiveRecord item) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: Text('admin_live.end_title'.tr()), content: TextField(controller: controller, decoration: InputDecoration(labelText: 'admin_live.reason'.tr())), actions: [TextButton(onPressed: () => context.pop(), child: Text('common.cancel'.tr())), TextButton(onPressed: () => context.pop(controller.text.trim()), child: Text('admin_live.end'.tr()))]));
    controller.dispose();
    if (reason == null || reason.isEmpty) return;
    await ref.read(adminLiveRepositoryProvider).end(item.id, reason);
    ref.invalidate(adminLiveListProvider);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin_live.ended_notice'.tr())));
  }
}