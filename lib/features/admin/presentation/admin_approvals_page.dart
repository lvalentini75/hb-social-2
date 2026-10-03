import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_detail_panel.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';

class AdminApprovalsPage extends StatefulWidget { const AdminApprovalsPage({super.key}); @override State<AdminApprovalsPage> createState() => _AdminApprovalsPageState(); }
class _AdminApprovalsPageState extends State<AdminApprovalsPage> {
  int view = 0; int type = 0;
  @override Widget build(BuildContext context) {
    final panel = GoRouterState.of(context).uri.queryParameters['panel'] == 'approval';
    return Stack(children: [AdminListPage(title: 'admin.approvals.title'.tr(), description: 'admin.approvals.description'.tr(), filters: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [HBSegmentedTabs(labels: [for (final key in ['pending', 'approved', 'rejected']) 'admin.approvals.views.$key'.tr()], selectedIndex: view, onChanged: (value) => setState(() => view = value)), const SizedBox(height: AppSpacing.sm), HBFilterChipsRow(labels: [for (final key in ['all', 'ads', 'listings', 'businessPages']) 'admin.approvals.types.$key'.tr()], selectedIndex: type, onChanged: (value) => setState(() => type = value)), const SizedBox(height: AppSpacing.sm), const AdminCompactDropdown(label: '—', items: []), const SizedBox(height: AppSpacing.sm), Text('admin.approvals.weaponsOnly'.tr(), style: context.textStyles.bodySmall)]), kpis: [for (final key in ['pending', 'over24h', 'approved7d', 'rejectionRate']) AdminKpiValue(label: 'admin.approvals.kpi.$key'.tr(), value: '—')], emptyMessage: 'admin.approvals.empty'.tr(), content: HBEmptyState(icon: Icons.approval_outlined, title: 'admin.approvals.empty'.tr(), message: 'admin.approvals.emptyMessage'.tr(), padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl))), if (panel) AdminDetailOverlay(onClose: _close, panel: AdminApprovalDetailPanel(onClose: _close))]);
  }
  void _close() => context.go('/admin/approvals?debugPreview=true');
}
class AdminApprovalDetailPanel extends StatelessWidget { final VoidCallback onClose; const AdminApprovalDetailPanel({super.key, required this.onClose});
  @override Widget build(BuildContext context) => AdminDetailPanel(title: 'admin.approvals.detailTitle'.tr(), onClose: onClose, actions: [HBButton.secondary(label: 'admin.approvals.reject'.tr(), onPressed: null, foregroundColor: LightModeColors.lightError), HBButton.primary(label: 'admin.approvals.approve'.tr(), onPressed: null)], body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [AspectRatio(aspectRatio: 16 / 9, child: Container(decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)), child: const Icon(Icons.image_outlined, color: LightModeColors.lightTextTertiary, size: 44))), AdminDetailSection(title: 'admin.approvals.data'.tr(), child: Column(children: [for (final key in ['title', 'text', 'category', 'priceBudget', 'placement']) AdminLabelValueRow(label: 'admin.approvals.fields.$key'.tr(), value: '—')])), AdminDetailSection(title: 'admin.approvals.policy'.tr(), child: Column(children: [for (final key in ['prohibited', 'categoryCorrect', 'weapons']) CheckboxListTile(value: false, onChanged: null, contentPadding: EdgeInsets.zero, title: Text('admin.approvals.checks.$key'.tr(), style: context.textStyles.bodySmall))])), AdminDetailSection(title: 'admin.approvals.rejectionReason'.tr(), child: HBInput(hint: 'admin.approvals.rejectionHint'.tr(), enabled: false))])); }