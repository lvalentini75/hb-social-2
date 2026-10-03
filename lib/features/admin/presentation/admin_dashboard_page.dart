import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('admin.dashboard.title'.tr(), style: context.textStyles.headlineSmall?.withColor(LightModeColors.lightOnSurface).bold),
              const SizedBox(height: AppSpacing.lg),
              const AdminKpiGrid(),
              const SizedBox(height: AppSpacing.md),
              const AdminDashboardSecondRow(),
              const SizedBox(height: AppSpacing.md),
              const AdminDashboardThirdRow(),
              const SizedBox(height: AppSpacing.md),
              const AdminDashboardFourthRow(),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ],
    );
  }
}

class AdminKpiGrid extends StatelessWidget {
  const AdminKpiGrid({super.key});

  static const keys = ['registeredUsers', 'activeToday', 'posts24h', 'activeListings', 'adRevenue30d', 'orders30d'];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1440 ? 6 : width >= 1200 ? 3 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: columns == 2 ? 2.1 : 1.65,
      children: [for (final key in keys) AdminKpiTile(label: 'admin.dashboard.kpi.$key'.tr())],
    );
  }
}

class AdminKpiTile extends StatelessWidget {
  final String label;

  const AdminKpiTile({super.key, required this.label});

  @override
  Widget build(BuildContext context) => HBCard(
    radius: AppRadius.sm,
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
        Text('admin.common.unavailable'.tr(), style: context.textStyles.displaySmall?.withColor(LightModeColors.lightOnSurface).copyWith(fontSize: 32, fontWeight: FontWeight.w700)),
        Text('admin.dashboard.realDataP05'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary)),
      ],
    ),
  );
}

class AdminDashboardSecondRow extends StatelessWidget {
  const AdminDashboardSecondRow({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 960;
      final chart = const Expanded(flex: 2, child: AdminChartCard());
      final todo = const Expanded(child: AdminTodoCard());
      if (wide) return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [chart, const SizedBox(width: AppSpacing.md), todo]));
      return const Column(children: [AdminChartCard(), SizedBox(height: AppSpacing.md), AdminTodoCard()]);
    },
  );
}

class AdminChartCard extends StatelessWidget {
  const AdminChartCard({super.key});

  @override
  Widget build(BuildContext context) => AdminPanelCard(
    title: 'admin.dashboard.chartTitle'.tr(),
    subtitle: 'admin.dashboard.last30Days'.tr(),
    trailing: HBButton.ghost(label: 'admin.dashboard.exportCsv'.tr(), onPressed: null, size: HBButtonSize.sm),
    child: Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [const AdminLegendMarker(isLine: true), Text('admin.dashboard.dau'.tr(), style: context.textStyles.labelSmall), const SizedBox(width: AppSpacing.md), const AdminLegendMarker(), Text('admin.dashboard.adRevenue'.tr(), style: context.textStyles.labelSmall)]),
        const SizedBox(height: AppSpacing.sm),
        AspectRatio(
          aspectRatio: 16 / 5,
          child: Container(
            decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: HBEmptyState(icon: Icons.insert_chart_outlined, title: 'admin.dashboard.chartEmptyTitle'.tr(), message: 'admin.dashboard.chartEmptyMessage'.tr(), padding: const EdgeInsets.all(AppSpacing.md)),
          ),
        ),
      ],
    ),
  );
}

class AdminLegendMarker extends StatelessWidget {
  final bool isLine;

  const AdminLegendMarker({super.key, this.isLine = false});

  @override
  Widget build(BuildContext context) => Container(width: 16, height: isLine ? 2 : 8, margin: const EdgeInsets.only(right: 5), decoration: BoxDecoration(color: isLine ? LightModeColors.lightPrimary : LightModeColors.lightPrimaryOutline, borderRadius: BorderRadius.circular(AppRadius.pill)));
}

class AdminTodoCard extends StatelessWidget {
  const AdminTodoCard({super.key});

  @override
  Widget build(BuildContext context) => AdminPanelCard(
    title: 'admin.dashboard.todoTitle'.tr(),
    trailing: HBStatusChip(kind: HBStatusKind.neutral, label: 'admin.dashboard.zeroItems'.tr()),
    child: HBEmptyState(icon: Icons.task_alt_outlined, title: 'admin.dashboard.todoEmpty'.tr(), message: 'admin.dashboard.realDataP05'.tr(), padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg)),
  );
}

class AdminDashboardThirdRow extends StatelessWidget {
  const AdminDashboardThirdRow({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cards = [
        const AdminReportsCard(),
        const AdminApprovalsCard(),
        const AdminSystemStatusCard(),
      ];
      if (constraints.maxWidth < 1080) return Column(children: [for (var i = 0; i < cards.length; i++) ...[cards[i], if (i < cards.length - 1) const SizedBox(height: AppSpacing.md)]]);
      return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(flex: 2, child: cards[0]), const SizedBox(width: AppSpacing.md), Expanded(child: cards[1]), const SizedBox(width: AppSpacing.md), Expanded(child: cards[2])]));
    },
  );
}

class AdminReportsCard extends StatelessWidget {
  const AdminReportsCard({super.key});

  @override
  Widget build(BuildContext context) => AdminPanelCard(
    title: 'admin.dashboard.reportsTitle'.tr(),
    subtitle: 'admin.dashboard.reportsSubtitle'.tr(),
    trailing: HBButton.ghost(label: 'admin.dashboard.openReports'.tr(), onPressed: () {
      final query = GoRouterState.of(context).uri.query;
      context.go('/admin/reports${query.isEmpty ? '' : '?$query'}');
    }, size: HBButtonSize.sm),
    child: AdminDataTable(
      headers: ['admin.tables.type'.tr(), 'admin.tables.content'.tr(), 'admin.tables.reason'.tr(), 'admin.tables.priority'.tr(), 'admin.tables.status'.tr(), 'admin.tables.moderator'.tr()],
      columnWidths: const [100, 200, 150, 100, 100, 60],
      rows: const [],
      emptyMessage: 'admin.dashboard.noReports'.tr(),
    ),
  );
}

class AdminApprovalsCard extends StatelessWidget {
  const AdminApprovalsCard({super.key});

  @override
  Widget build(BuildContext context) => AdminPanelCard(
    title: 'admin.dashboard.approvalsTitle'.tr(),
    trailing: HBButton.ghost(label: 'admin.dashboard.openApprovals'.tr(), onPressed: () => context.go('/admin/approvals?${GoRouterState.of(context).uri.query}'), size: HBButtonSize.sm),
    child: HBEmptyState(icon: Icons.approval_outlined, title: 'admin.dashboard.approvalsEmpty'.tr(), message: 'admin.dashboard.realDataP05'.tr(), padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg)),
  );
}

class AdminSystemStatusCard extends StatelessWidget {
  const AdminSystemStatusCard({super.key});

  static const serviceKeys = ['database', 'storage', 'realtime', 'edgeFunctions', 'stripeWebhook', 'push', 'jobs'];

  @override
  Widget build(BuildContext context) => AdminPanelCard(
    title: 'admin.dashboard.systemStatus'.tr(),
    trailing: HBButton.ghost(label: 'admin.dashboard.sentry'.tr(), onPressed: null, size: HBButtonSize.sm),
    child: Column(children: [
      for (final key in serviceKeys) AdminSystemStatusRow(label: 'admin.dashboard.services.$key'.tr()),
      const SizedBox(height: AppSpacing.sm),
      Text('admin.dashboard.monitoringP43'.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary)),
    ]),
  );
}

class AdminSystemStatusRow extends StatelessWidget {
  final String label;

  const AdminSystemStatusRow({super.key, required this.label});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: Row(children: [
      Container(width: 7, height: 7, decoration: const BoxDecoration(color: LightModeColors.lightTextTertiary, shape: BoxShape.circle)),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurface))),
      Text('admin.common.unavailable'.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary)),
      const SizedBox(width: AppSpacing.sm),
      HBStatusChip(kind: HBStatusKind.neutral, label: 'admin.dashboard.unknown'.tr()),
    ]),
  );
}

class AdminDashboardFourthRow extends StatelessWidget {
  const AdminDashboardFourthRow({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const activities = AdminActivitiesCard();
      const audit = AdminAuditCard();
      if (constraints.maxWidth < 900) return const Column(children: [activities, SizedBox(height: AppSpacing.md), audit]);
      return const IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(flex: 2, child: activities), SizedBox(width: AppSpacing.md), Expanded(child: audit)]));
    },
  );
}

class AdminActivitiesCard extends StatelessWidget {
  const AdminActivitiesCard({super.key});

  @override
  Widget build(BuildContext context) => AdminPanelCard(
    title: 'admin.dashboard.activitiesTitle'.tr(),
    subtitle: 'admin.dashboard.activitiesSubtitle'.tr(),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [HBButton.ghost(label: 'admin.dashboard.filters'.tr(), onPressed: null, size: HBButtonSize.sm), HBButton.ghost(label: 'admin.dashboard.exportGdpr'.tr(), onPressed: null, size: HBButtonSize.sm)]),
    child: AdminDataTable(
      headers: ['admin.tables.user'.tr(), 'admin.tables.region'.tr(), 'admin.tables.verification'.tr(), 'admin.tables.role'.tr(), 'admin.tables.lastActivity'.tr()],
      rows: const [],
      emptyMessage: 'admin.dashboard.noActivities'.tr(),
    ),
  );
}

class AdminAuditCard extends StatelessWidget {
  const AdminAuditCard({super.key});

  @override
  Widget build(BuildContext context) => AdminPanelCard(
    title: 'admin.dashboard.auditTitle'.tr(),
    trailing: HBButton.ghost(label: 'admin.dashboard.fullHistory'.tr(), onPressed: () {
      final query = GoRouterState.of(context).uri.query;
      context.go('/admin/security${query.isEmpty ? '' : '?$query'}');
    }, size: HBButtonSize.sm),
    child: HBEmptyState(icon: Icons.history_outlined, title: 'admin.dashboard.auditEmpty'.tr(), message: 'admin.dashboard.realDataP05'.tr(), padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg)),
  );
}

class AdminPanelCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  const AdminPanelCard({super.key, required this.title, this.subtitle, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) => HBCard(
    radius: AppRadius.sm,
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: context.textStyles.titleMedium?.withColor(LightModeColors.lightOnSurface).copyWith(fontSize: 16, fontWeight: FontWeight.w700)), if (subtitle != null) Text(subtitle!, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary))])),
            if (trailing != null) Flexible(child: trailing!),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    ),
  );
}