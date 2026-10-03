import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/domain/admin_moderation.dart';
import 'package:hb_social/features/admin/domain/admin_role.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_detail_panel.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/providers/admin_console_providers.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  int statusIndex = 0;
  bool onlyVerified = false;

  void _future(String phase) => showComingSoonInfo(context, icon: Icons.schedule_outlined, title: 'common.coming_soon_title'.tr(), message: 'admin.common.arrivesWith'.tr(namedArgs: {'phase': phase}));

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminUsersProvider);
    final showPanel = GoRouterState.of(context).uri.queryParameters['panel'] == 'user';
    final hasFilters = statusIndex != 0 || onlyVerified;
    return Stack(
      children: [
        AdminListPage(
          title: 'admin.users.title'.tr(),
          description: 'admin.users.description'.tr(),
          actions: [HBButton.ghost(label: 'admin.users.exportCsv'.tr(), onPressed: null, icon: Icons.download_outlined, size: HBButtonSize.sm), HBButton.secondary(label: 'admin.users.inviteStaff'.tr(), onPressed: () => _future('P40'), icon: Icons.person_add_alt_1_outlined, size: HBButtonSize.sm)],
          filters: AdminUsersFilters(statusIndex: statusIndex, onlyVerified: onlyVerified, onStatusChanged: (value) => setState(() => statusIndex = value), onVerifiedChanged: () => setState(() => onlyVerified = !onlyVerified)),
          kpis: [for (final key in ['registered', 'active30d', 'suspended', 'pendingVerification']) AdminKpiValue(label: 'admin.users.kpi.$key'.tr(), value: 'admin.common.unavailable'.tr())],
          headers: [for (final key in ['user', 'countryRegion', 'verification', 'role', 'registered', 'lastActivity', 'status', 'actions']) 'admin.users.table.$key'.tr()],
          columnWidths: const [220, 150, 120, 120, 110, 130, 110, 56],
          rows: const [],
          isLoading: users.isLoading,
          emptyMessage: (hasFilters ? 'admin.users.emptyFiltered' : 'admin.users.emptyBackend').tr(),
        ),
        if (showPanel) AdminDetailOverlay(onClose: _closePanel, panel: AdminUserDetailPanel(onClose: _closePanel, onFutureAction: () => _future('P41'))),
      ],
    );
  }

  void _closePanel() {
    final debug = GoRouterState.of(context).uri.queryParameters['debugPreview'] == 'true';
    context.go('/admin/users${debug ? '?debugPreview=true' : ''}');
  }
}

class AdminUsersFilters extends StatelessWidget {
  final int statusIndex;
  final bool onlyVerified;
  final ValueChanged<int> onStatusChanged;
  final VoidCallback onVerifiedChanged;

  const AdminUsersFilters({super.key, required this.statusIndex, required this.onlyVerified, required this.onStatusChanged, required this.onVerifiedChanged});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(width: 320, child: HBInput(hint: 'admin.users.searchHint'.tr(), prefixIcon: const Icon(Icons.search, size: 18))),
      SizedBox(width: 480, child: HBFilterChipsRow(labels: [for (final key in ['all', 'active', 'suspended', 'banned', 'pendingVerification']) 'admin.users.filters.$key'.tr()], selectedIndex: statusIndex, onChanged: onStatusChanged)),
      AdminCompactDropdown(label: 'admin.users.role'.tr(), items: ['admin.users.roleUser'.tr(), ...AdminRole.values.map((role) => role.labelKey.tr())]),
      AdminCompactDropdown(label: 'admin.users.country'.tr(), items: SupportedCountry.values.map((country) => country.labelKey.tr()).toList()),
      SizedBox(width: 140, child: HBFilterChipsRow(labels: ['admin.users.onlyVerified'.tr()], selectedIndex: onlyVerified ? 0 : -1, onChanged: (_) => onVerifiedChanged())),
    ],
  );
}

class AdminUserDetailPanel extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onFutureAction;
  const AdminUserDetailPanel({super.key, required this.onClose, required this.onFutureAction});

  @override
  State<AdminUserDetailPanel> createState() => _AdminUserDetailPanelState();
}

class _AdminUserDetailPanelState extends State<AdminUserDetailPanel> {
  int tab = 0;

  @override
  Widget build(BuildContext context) => AdminDetailPanel(
    title: 'admin.users.detailTitle'.tr(),
    status: HBStatusChip(kind: HBStatusKind.neutral, label: 'admin.common.unavailable'.tr()),
    onClose: widget.onClose,
    actions: [
      HBButton.secondary(label: 'admin.users.actions.suspend'.tr(), onPressed: widget.onFutureAction, size: HBButtonSize.sm),
      HBButton.secondary(label: 'admin.users.actions.ban'.tr(), onPressed: widget.onFutureAction, size: HBButtonSize.sm, foregroundColor: LightModeColors.lightError),
      HBButton.ghost(label: 'admin.users.actions.exportGdpr'.tr(), onPressed: widget.onFutureAction, size: HBButtonSize.sm),
      HBButton.ghost(label: 'admin.users.actions.delete'.tr(), onPressed: widget.onFutureAction, size: HBButtonSize.sm, foregroundColor: LightModeColors.lightError),
    ],
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [const HBAvatar(size: 56, isGuest: true), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.common.unavailable'.tr(), style: context.textStyles.titleMedium?.bold), Text('admin.common.unavailable'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])), HBStatusChip(kind: HBStatusKind.neutral, label: 'admin.users.verification'.tr())]),
        const SizedBox(height: AppSpacing.sm),
        Text('admin.users.detailMeta'.tr(namedArgs: {'country': '—', 'region': '—', 'date': '—'}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
        const SizedBox(height: AppSpacing.lg),
        HBSegmentedTabs(labels: [for (final key in ['profile', 'activity', 'reports', 'notes']) 'admin.users.tabs.$key'.tr()], selectedIndex: tab, onChanged: (value) => setState(() => tab = value)),
        const SizedBox(height: AppSpacing.lg),
        AdminUserTab(index: tab),
      ],
    ),
  );
}

class AdminUserTab extends StatelessWidget {
  final int index;
  const AdminUserTab({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    if (index == 0) return Column(children: [for (final key in ['email', 'phone', 'language', 'currency', 'huntingUnit', 'badges']) AdminLabelValueRow(label: 'admin.users.fields.$key'.tr(), value: 'admin.common.unavailable'.tr())]);
    if (index == 1) return GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 2.2, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm, children: [for (final key in ['posts', 'comments', 'listings', 'outings']) Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)), child: Row(children: [Expanded(child: Text('admin.users.activity.$key'.tr())), Text('admin.common.unavailable'.tr(), style: context.textStyles.titleMedium?.bold)]))]);
    if (index == 2) return HBEmptyState(icon: Icons.report_outlined, title: 'admin.users.noReports'.tr(), message: 'admin.users.noReportsMessage'.tr(), padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg));
    return HBInput(label: 'admin.users.internalNotes'.tr(), hint: 'admin.users.notesP41'.tr(), enabled: false, maxLines: 4);
  }
}