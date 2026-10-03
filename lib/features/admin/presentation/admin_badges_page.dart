import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/features/admin/domain/admin_moderation.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_detail_panel.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/providers/admin_console_providers.dart';

class AdminBadgesPage extends ConsumerStatefulWidget {
  const AdminBadgesPage({super.key});

  @override
  ConsumerState<AdminBadgesPage> createState() => _AdminBadgesPageState();
}

class _AdminBadgesPageState extends ConsumerState<AdminBadgesPage> {
  int viewIndex = 0;
  int typeIndex = 0;

  void _future() => showComingSoonInfo(context, icon: Icons.schedule_outlined, title: 'common.coming_soon_title'.tr(), message: 'admin.common.arrivesWith'.tr(namedArgs: {'phase': 'P31'}));

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(adminBadgeRequestsProvider);
    final showPanel = GoRouterState.of(context).uri.queryParameters['panel'] == 'badge';
    return Stack(
      children: [
        AdminListPage(
          title: 'admin.badges.title'.tr(),
          description: 'admin.badges.description'.tr(),
          filters: AdminBadgeFilters(viewIndex: viewIndex, typeIndex: typeIndex, onViewChanged: (value) => setState(() => viewIndex = value), onTypeChanged: (value) => setState(() => typeIndex = value)),
          kpis: [for (final key in ['pending', 'over48h', 'approved30d', 'rejected30d']) AdminKpiValue(label: 'admin.badges.kpi.$key'.tr(), value: 'admin.common.unavailable'.tr())],
          emptyMessage: 'admin.badges.empty'.tr(),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AdminVerificationNotice(),
              const SizedBox(height: AppSpacing.md),
              if (requests.isLoading)
                const Column(children: [HBSkeleton(height: 64, radius: AppRadius.sm), SizedBox(height: AppSpacing.sm), HBSkeleton(height: 64, radius: AppRadius.sm)])
              else
                HBEmptyState(icon: Icons.verified_user_outlined, title: 'admin.badges.empty'.tr(), message: 'admin.badges.emptyMessage'.tr(), padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl)),
            ],
          ),
        ),
        if (showPanel) AdminDetailOverlay(onClose: _closePanel, panel: AdminBadgeDetailPanel(onClose: _closePanel, onFutureAction: _future)),
      ],
    );
  }

  void _closePanel() {
    final debug = GoRouterState.of(context).uri.queryParameters['debugPreview'] == 'true';
    context.go('/admin/badges${debug ? '?debugPreview=true' : ''}');
  }
}

class AdminBadgeFilters extends StatelessWidget {
  final int viewIndex;
  final int typeIndex;
  final ValueChanged<int> onViewChanged;
  final ValueChanged<int> onTypeChanged;

  const AdminBadgeFilters({super.key, required this.viewIndex, required this.typeIndex, required this.onViewChanged, required this.onTypeChanged});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HBSegmentedTabs(labels: [for (final key in ['pending', 'approved', 'rejected']) 'admin.badges.views.$key'.tr()], selectedIndex: viewIndex, onChanged: onViewChanged),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(width: 560, child: HBFilterChipsRow(labels: [for (final type in BadgeType.values) type.labelKey.tr()], selectedIndex: typeIndex, onChanged: onTypeChanged)),
      const SizedBox(height: AppSpacing.xs),
      Wrap(spacing: AppSpacing.md, children: [for (final type in BadgeType.values) Row(mainAxisSize: MainAxisSize.min, children: [HBBadge(kind: type.badgeKind), const SizedBox(width: AppSpacing.xs), Text(type.labelKey.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant))])]),
    ],
  );
}

class AdminVerificationNotice extends StatelessWidget {
  const AdminVerificationNotice({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(color: LightModeColors.lightPrimarySoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lock_outline, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('admin.badges.privateNotice'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightForest)))]),
  );
}

class AdminBadgeDetailPanel extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onFutureAction;
  const AdminBadgeDetailPanel({super.key, required this.onClose, required this.onFutureAction});

  @override
  Widget build(BuildContext context) => AdminDetailPanel(
    title: 'admin.badges.detailTitle'.tr(),
    status: HBStatusChip(kind: HBStatusKind.pending, label: 'admin.common.unavailable'.tr()),
    onClose: onClose,
    actions: [HBButton.secondary(label: 'admin.badges.reject'.tr(), onPressed: onFutureAction, foregroundColor: LightModeColors.lightError), HBButton.primary(label: 'admin.badges.approve'.tr(), onPressed: onFutureAction)],
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [const HBAvatar(size: 40, isGuest: true), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.common.unavailable'.tr(), style: context.textStyles.titleMedium?.bold), Text('admin.common.unavailable'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])), HBBadge(kind: BadgeType.hunter.badgeKind)]),
        const SizedBox(height: AppSpacing.lg),
        AdminDetailSection(
          title: 'admin.badges.document'.tr(),
          child: Column(children: [
            AspectRatio(aspectRatio: 3 / 4, child: Container(decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.description_outlined, size: 56, color: LightModeColors.lightTextTertiary), const SizedBox(height: AppSpacing.sm), Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), child: Text('admin.badges.previewP07P31'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)))]))),
            const SizedBox(height: AppSpacing.sm),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [HBButton.ghost(label: 'admin.badges.open'.tr(), onPressed: null, size: HBButtonSize.sm), HBButton.ghost(label: 'admin.badges.download'.tr(), onPressed: null, size: HBButtonSize.sm)]),
          ]),
        ),
        AdminDetailSection(title: 'admin.badges.declaredData'.tr(), child: Column(children: [for (final key in ['badgeType', 'licenseNumber', 'authority', 'expiry', 'vatNumber']) AdminLabelValueRow(label: 'admin.badges.fields.$key'.tr(), value: 'admin.common.unavailable'.tr())])),
        AdminDetailSection(title: 'admin.badges.checklist'.tr(), child: Column(children: [for (final key in ['readable', 'consistent', 'valid']) CheckboxListTile(value: false, onChanged: null, dense: true, contentPadding: EdgeInsets.zero, title: Text('admin.badges.checks.$key'.tr(), style: context.textStyles.bodySmall))])),
        AdminDetailSection(title: 'admin.badges.rejectionReason'.tr(), child: HBInput(hint: 'admin.badges.rejectionReasonHint'.tr(), enabled: false)),
      ],
    ),
  );
}