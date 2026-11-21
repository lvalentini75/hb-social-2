import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/domain/admin_list_models.dart';
import 'package:hb_social/features/admin/domain/admin_module.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_detail_panel.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_read_only_widgets.dart';
import 'package:hb_social/features/admin/providers/admin_console_providers.dart';

class AdminRolesPage extends ConsumerStatefulWidget {
  const AdminRolesPage({super.key});
  @override ConsumerState<AdminRolesPage> createState() => _AdminRolesPageState();
}

class _AdminRolesPageState extends ConsumerState<AdminRolesPage> {
  int tab = 0;
  AdminStaffRecord? selected;

  @override Widget build(BuildContext context) {
    final data = ref.watch(adminRolesDataProvider);
    return Stack(children: [
      AdminListPage(title: 'admin.rolesPage.title'.tr(), description: 'admin.rolesPage.description'.tr(), filters: SizedBox(width: 420, child: HBSegmentedTabs(labels: ['admin.p05c.roleTabs.admins'.tr(), 'admin.p05c.roleTabs.matrix'.tr()], selectedIndex: tab, onChanged: (value) => setState(() => tab = value))), emptyMessage: 'admin.rolesPage.staffEmpty'.tr(), onRetry: data.hasError ? () => ref.invalidate(adminRolesDataProvider) : null, content: data.when(loading: () => const AdminDataTable(headers: ['','','','',''], rows: [], emptyMessage: '', isLoading: true), error: (_, __) => const SizedBox.shrink(), data: (value) => tab == 0 ? AdminStaffTable(data: value, onSelected: (member) => setState(() => selected = member)) : AdminPermissionMatrix(data: value))),
      if (selected != null && data.valueOrNull != null) AdminDetailOverlay(onClose: () => setState(() => selected = null), panel: AdminStaffDetailPanel(member: selected!, role: data.valueOrNull!.roles.firstWhere((role) => role.name == selected!.roleName), onClose: () => setState(() => selected = null))),
    ]);
  }
}

class AdminStaffTable extends StatelessWidget {
  final AdminRolesData data;
  final ValueChanged<AdminStaffRecord> onSelected;
  const AdminStaffTable({super.key, required this.data, required this.onSelected});
  @override Widget build(BuildContext context) => AdminDataTable(headers: [for (final key in ['member','role','mfa','addedBy','since']) 'admin.p05c.staffColumns.$key'.tr()], columnWidths: const [240,180,100,220,140], emptyMessage: 'admin.rolesPage.staffEmpty'.tr(), rows: [for (final member in data.staff) [AdminPersonCell(person: member.person), Text(roleLabel(member.roleName).tr()), HBStatusChip(kind: member.mfaEnabled ? HBStatusKind.approved : HBStatusKind.pending, label: (member.mfaEnabled ? 'admin.p05c.enabled' : 'admin.p05c.disabled').tr()), member.addedBy == null ? Text('common.unavailable'.tr()) : AdminPersonCell(person: member.addedBy!), Text(relativeTime(context, member.createdAt))]], rowCallbacks: [for (final member in data.staff) () => onSelected(member)]);
}

class AdminPermissionMatrix extends StatelessWidget {
  final AdminRolesData data;
  const AdminPermissionMatrix({super.key, required this.data});
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text('admin.p05c.matrixReal'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
    const SizedBox(height: AppSpacing.sm),
    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Table(defaultColumnWidth: const IntrinsicColumnWidth(), children: [
      TableRow(children: [const SizedBox(width: 210), for (final role in data.roles) Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: Text(roleLabel(role.name).tr(), textAlign: TextAlign.center, style: context.textStyles.labelSmall?.bold))]),
      for (final section in adminModuleSections) ...[
        TableRow(children: [Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.xs), child: Text(section.labelKey.tr(), style: context.textStyles.labelSmall?.bold)), for (final _ in data.roles) const SizedBox()]),
        for (final module in section.modules) TableRow(children: [Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.sm), child: Text(module.titleKey.tr(), style: context.textStyles.bodySmall)), for (final role in data.roles) Padding(padding: const EdgeInsets.all(AppSpacing.xs), child: PermissionAccessCell(access: role.permissions[module.permissionSlug] ?? 'none'))]),
      ],
    ])),
    const SizedBox(height: AppSpacing.md),
    Wrap(spacing: AppSpacing.lg, children: [for (final access in ['none','read','write']) Row(mainAxisSize: MainAxisSize.min, children: [PermissionAccessCell(access: access), const SizedBox(width: AppSpacing.xs), Text('admin.p05c.access.$access'.tr())])]),
  ]);
}

class PermissionAccessCell extends StatelessWidget {
  final String access;
  const PermissionAccessCell({super.key, required this.access});
  @override Widget build(BuildContext context) => SizedBox(width: 34, height: 28, child: access == 'none' ? const SizedBox.shrink() : Icon(access == 'read' ? Icons.visibility_outlined : Icons.edit_outlined, size: 18, color: access == 'read' ? LightModeColors.lightInfo : LightModeColors.lightSuccess));
}

class AdminStaffDetailPanel extends StatelessWidget {
  final AdminStaffRecord member;
  final AdminRoleRecord role;
  final VoidCallback onClose;
  const AdminStaffDetailPanel({super.key, required this.member, required this.role, required this.onClose});
  @override Widget build(BuildContext context) => AdminDetailPanel(title: member.person.displayName, onClose: onClose, actions: const [], body: Column(children: [
    AdminDetailCard(title: 'admin.p05c.adminData'.tr(), child: Column(children: [AdminLabelValueRow(label: 'admin.p05c.staffColumns.role'.tr(), value: roleLabel(member.roleName).tr()), AdminLabelValueRow(label: 'admin.p05c.staffColumns.mfa'.tr(), value: (member.mfaEnabled ? 'admin.p05c.enabled' : 'admin.p05c.disabled').tr()), AdminLabelValueRow(label: 'admin.p05c.staffColumns.addedBy'.tr(), value: member.addedBy?.displayName ?? 'common.unavailable'.tr()), AdminLabelValueRow(label: 'admin.p05c.staffColumns.since'.tr(), value: DateFormat.yMd(context.locale.toString()).format(member.createdAt.toLocal()))])),
    AdminDetailCard(title: 'admin.p05c.rolePermissions'.tr(), child: Column(children: [for (final section in adminModuleSections) ...[Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(section.labelKey.tr(), style: context.textStyles.labelSmall?.bold))), for (final module in section.modules) AdminLabelValueRow(label: module.titleKey.tr(), value: 'admin.p05c.access.${role.permissions[module.permissionSlug] ?? 'none'}'.tr())]])),
  ]));
}

String roleLabel(String value) => 'admin.roles.${switch (value) { 'ads_reviewer' => 'adsReviewer', 'hunting_data_editor' => 'huntingDataEditor', _ => value }}';