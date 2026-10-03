import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/domain/admin_moderation.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_detail_panel.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/providers/admin_console_providers.dart';

class AdminReportsPage extends ConsumerStatefulWidget {
  const AdminReportsPage({super.key});

  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  int statusIndex = 0;
  int priorityIndex = -1;

  void _future() => showComingSoonInfo(context, icon: Icons.schedule_outlined, title: 'common.coming_soon_title'.tr(), message: 'admin.common.arrivesWith'.tr(namedArgs: {'phase': 'P41'}));

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(adminReportsProvider);
    final showPanel = GoRouterState.of(context).uri.queryParameters['panel'] == 'report';
    return Stack(
      children: [
        AdminListPage(
          title: 'admin.reports.title'.tr(),
          description: 'admin.reports.description'.tr(),
          actions: [HBButton.secondary(label: 'admin.reports.assignMe'.tr(), onPressed: null, size: HBButtonSize.sm), HBButton.ghost(label: 'admin.reports.rules'.tr(), onPressed: () => context.go('/admin/rules?debugPreview=true'), size: HBButtonSize.sm)],
          filters: AdminReportsFilters(statusIndex: statusIndex, priorityIndex: priorityIndex, onStatusChanged: (value) => setState(() => statusIndex = value), onPriorityChanged: (value) => setState(() => priorityIndex = value)),
          kpis: [for (final key in ['queued', 'overSla', 'resolvedToday', 'averageTime']) AdminKpiValue(label: 'admin.reports.kpi.$key'.tr(), value: 'admin.common.unavailable'.tr())],
          headers: [for (final key in ['type', 'content', 'reason', 'reportedBy', 'priority', 'status', 'sla', 'moderator', 'actions']) 'admin.reports.table.$key'.tr()],
          columnWidths: const [100, 230, 150, 130, 100, 120, 90, 90, 56],
          rows: const [],
          isLoading: reports.isLoading,
          emptyMessage: 'admin.reports.empty'.tr(),
        ),
        if (showPanel) AdminDetailOverlay(onClose: _closePanel, panel: AdminReportDetailPanel(onClose: _closePanel, onFutureAction: _future)),
      ],
    );
  }

  void _closePanel() {
    final debug = GoRouterState.of(context).uri.queryParameters['debugPreview'] == 'true';
    context.go('/admin/reports${debug ? '?debugPreview=true' : ''}');
  }
}

class AdminReportsFilters extends StatelessWidget {
  final int statusIndex;
  final int priorityIndex;
  final ValueChanged<int> onStatusChanged;
  final ValueChanged<int> onPriorityChanged;

  const AdminReportsFilters({super.key, required this.statusIndex, required this.priorityIndex, required this.onStatusChanged, required this.onPriorityChanged});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(width: 480, child: HBFilterChipsRow(labels: [for (final key in ['all', 'pending', 'inProgress', 'resolved', 'removed']) 'admin.reports.filters.$key'.tr()], selectedIndex: statusIndex, onChanged: onStatusChanged)),
      SizedBox(width: 260, child: HBFilterChipsRow(labels: [for (final key in ['high', 'medium', 'low']) 'admin.reports.priority.$key'.tr()], selectedIndex: priorityIndex, onChanged: onPriorityChanged)),
      AdminCompactDropdown(label: 'admin.reports.targetLabel'.tr(), items: ReportTargetType.values.map((type) => type.labelKey.tr()).toList()),
      AdminCompactDropdown(label: 'admin.reports.assignee'.tr(), items: [for (final key in ['all', 'unassigned', 'mine']) 'admin.reports.assignees.$key'.tr()]),
    ],
  );
}

class AdminReportDetailPanel extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onFutureAction;
  const AdminReportDetailPanel({super.key, required this.onClose, required this.onFutureAction});

  @override
  Widget build(BuildContext context) => AdminDetailPanel(
    title: 'admin.reports.detailTitle'.tr(),
    status: Wrap(spacing: AppSpacing.xs, children: [HBStatusChip(kind: ReportPriority.medium.statusKind, label: 'admin.common.unavailable'.tr()), HBStatusChip(kind: ReportStatus.pending.statusKind, label: 'admin.common.unavailable'.tr())]),
    onClose: onClose,
    actions: [
      HBButton.ghost(label: 'admin.reports.actions.ignore'.tr(), onPressed: onFutureAction, size: HBButtonSize.sm),
      HBButton.secondary(label: 'admin.reports.actions.warn'.tr(), onPressed: onFutureAction, size: HBButtonSize.sm),
      HBButton.secondary(label: 'admin.reports.actions.remove'.tr(), onPressed: onFutureAction, size: HBButtonSize.sm, foregroundColor: LightModeColors.lightError),
      HBButton.secondary(label: 'admin.reports.actions.strike'.tr(), onPressed: onFutureAction, size: HBButtonSize.sm),
      HBButton.ghost(label: 'admin.reports.actions.suspend'.tr(), onPressed: onFutureAction, size: HBButtonSize.sm, foregroundColor: LightModeColors.lightError),
    ],
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(aspectRatio: 16 / 9, child: Container(decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)), child: const Icon(Icons.article_outlined, size: 52, color: LightModeColors.lightTextTertiary))),
        const SizedBox(height: AppSpacing.lg),
        AdminDetailSection(title: 'admin.reports.reason'.tr(), child: Column(children: [AdminLabelValueRow(label: 'admin.reports.category'.tr(), value: 'admin.common.unavailable'.tr()), AdminLabelValueRow(label: 'admin.reports.reporterText'.tr(), value: 'admin.common.unavailable'.tr())])),
        AdminDetailSection(title: 'admin.reports.reportedBy'.tr(), child: const AdminPersonPlaceholder(showStrike: false)),
        AdminDetailSection(title: 'admin.reports.contentAuthor'.tr(), child: const AdminPersonPlaceholder(showStrike: true)),
        AdminDetailSection(title: 'admin.reports.history'.tr(), child: HBEmptyState(icon: Icons.history_outlined, title: 'admin.reports.noHistory'.tr(), message: 'admin.reports.noHistoryMessage'.tr(), padding: const EdgeInsets.symmetric(vertical: AppSpacing.md))),
        AdminDetailSection(title: 'admin.reports.assignTo'.tr(), child: AdminCompactDropdown(label: 'admin.common.unavailable'.tr(), items: ['admin.common.unavailable'.tr()], enabled: false)),
      ],
    ),
  );
}

class AdminPersonPlaceholder extends StatelessWidget {
  final bool showStrike;
  const AdminPersonPlaceholder({super.key, required this.showStrike});

  @override
  Widget build(BuildContext context) => HBCard(
    radius: AppRadius.sm,
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Row(children: [const HBAvatar(size: 36, isGuest: true), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('admin.common.unavailable'.tr())), if (showStrike) HBStatusChip(kind: HBStatusKind.neutral, label: 'admin.reports.strike'.tr(namedArgs: {'value': '—'}))]),
  );
}