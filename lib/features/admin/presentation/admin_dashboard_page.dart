import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/domain/admin_dashboard.dart';
import 'package:hb_social/features/admin/providers/admin_dashboard_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardProvider);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text('admin.dashboard.title'.tr(), style: context.textStyles.headlineSmall?.withColor(LightModeColors.lightOnSurface).bold)),
                HBButton.secondary(label: 'admin.p05.refresh'.tr(), icon: Icons.refresh, onPressed: () => ref.invalidate(adminDashboardProvider), size: HBButtonSize.sm),
              ]),
              const SizedBox(height: AppSpacing.lg),
              state.when(
                loading: () => const AdminDashboardSkeleton(),
                error: (error, _) => AdminDashboardError(error: error, onRetry: () => ref.invalidate(adminDashboardProvider)),
                data: (data) => AdminDashboardContent(data: data),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ],
    );
  }
}

class AdminDashboardContent extends StatelessWidget {
  final DashboardData data;

  const AdminDashboardContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) => Column(children: [
    AdminKpiGrid(data: data),
    const SizedBox(height: AppSpacing.md),
    AdminChartCard(counts: data.dailyCounts),
    const SizedBox(height: AppSpacing.md),
    LayoutBuilder(builder: (context, constraints) {
      final cards = [
        AdminReportsCard(reports: data.reports),
        AdminBadgeRequestsCard(requests: data.badgeRequests),
        AdminAuditCard(entries: data.auditEntries),
      ];
      if (constraints.maxWidth < 1080) return Column(children: [for (var index = 0; index < cards.length; index++) ...[cards[index], if (index < cards.length - 1) const SizedBox(height: AppSpacing.md)]]);
      return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (var index = 0; index < cards.length; index++) ...[Expanded(child: cards[index]), if (index < cards.length - 1) const SizedBox(width: AppSpacing.md)]]));
    }),
  ]);
}

class AdminKpiGrid extends StatelessWidget {
  final DashboardData data;

  const AdminKpiGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final items = [
      AdminKpiValue(labelKey: 'admin.p05.kpi.totalUsers', metric: data.totalUsers),
      AdminKpiValue(labelKey: 'admin.p05.kpi.newUsers7d', metric: data.newUsersCurrent, previous: data.newUsersPrevious),
      AdminKpiValue(labelKey: 'admin.p05.kpi.posts7d', metric: data.postsCurrent, previous: data.postsPrevious),
      AdminKpiValue(labelKey: 'admin.p05.kpi.activeListings', metric: data.activeListings),
      AdminKpiValue(labelKey: 'admin.p05.kpi.openReports', metric: data.openReports),
      AdminKpiValue(labelKey: 'admin.p05.kpi.pendingBadges', metric: data.pendingBadges),
      AdminKpiValue(labelKey: 'admin.p05.kpi.upcomingEvents', metric: data.upcomingEvents),
      AdminKpiValue(labelKey: 'admin.p05.kpi.activeGroups', metric: data.activeGroups),
    ];
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1400 ? 4 : width >= 900 ? 3 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: columns == 2 ? 1.8 : 2.0,
      children: [for (final item in items) AdminKpiTile(value: item)],
    );
  }
}

class AdminKpiValue {
  final String labelKey;
  final DashboardMetric metric;
  final DashboardMetric? previous;

  const AdminKpiValue({required this.labelKey, required this.metric, this.previous});
}

class AdminKpiTile extends StatelessWidget {
  final AdminKpiValue value;

  const AdminKpiTile({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final errorKey = value.metric.errorKey;
    final count = value.metric.value;
    Widget number = Text(count == null ? 'common.unavailable'.tr() : NumberFormat.decimalPattern(context.locale.toString()).format(count), style: context.textStyles.displaySmall?.withColor(LightModeColors.lightOnSurface).copyWith(fontSize: 30, fontWeight: FontWeight.w700));
    if (errorKey != null) number = Tooltip(message: errorKey.tr(), child: number);
    return HBCard(
      radius: AppRadius.sm,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(value.labelKey.tr(), maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
        number,
        if (value.previous != null) AdminDeltaChip(current: value.metric, previous: value.previous!),
      ]),
    );
  }
}

class AdminDeltaChip extends StatelessWidget {
  final DashboardMetric current;
  final DashboardMetric previous;

  const AdminDeltaChip({super.key, required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    if (current.value == null || previous.value == null) return HBStatusChip(kind: HBStatusKind.neutral, label: 'common.unavailable'.tr());
    if (previous.value == 0) return HBStatusChip(kind: HBStatusKind.neutral, label: 'admin.p05.deltaNew'.tr());
    final delta = (((current.value! - previous.value!) / previous.value!) * 100).round();
    final kind = delta > 0 ? HBStatusKind.approved : delta < 0 ? HBStatusKind.rejected : HBStatusKind.neutral;
    return HBStatusChip(kind: kind, label: 'admin.p05.delta'.tr(namedArgs: {'value': '${delta >= 0 ? '+' : ''}$delta'}));
  }
}

class AdminChartCard extends StatelessWidget {
  final List<DailyCount> counts;

  const AdminChartCard({super.key, required this.counts});

  @override
  Widget build(BuildContext context) => AdminPanelCard(
    title: 'admin.p05.chartTitle'.tr(),
    subtitle: 'admin.dashboard.last30Days'.tr(),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        const AdminLegendMarker(color: LightModeColors.lightPrimary),
        Text('admin.p05.registrations'.tr(), style: context.textStyles.labelSmall),
        const SizedBox(width: AppSpacing.md),
        const AdminLegendMarker(color: LightModeColors.lightInfo),
        Text('admin.p05.posts'.tr(), style: context.textStyles.labelSmall),
      ]),
      const SizedBox(height: AppSpacing.md),
      AspectRatio(
        aspectRatio: 16 / 5,
        child: DecoratedBox(
          decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: CustomPaint(painter: AdminTrendChartPainter(counts))),
        ),
      ),
    ]),
  );
}

class AdminLegendMarker extends StatelessWidget {
  final Color color;

  const AdminLegendMarker({super.key, required this.color});

  @override
  Widget build(BuildContext context) => Container(width: 16, height: 3, margin: const EdgeInsets.only(right: 5), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.pill)));
}

class AdminTrendChartPainter extends CustomPainter {
  final List<DailyCount> counts;

  AdminTrendChartPainter(this.counts);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = LightModeColors.lightDivider..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final maxValue = math.max(1, counts.fold<int>(0, (value, item) => math.max(value, math.max(item.registrations, item.posts))));
    _drawSeries(canvas, size, maxValue, [for (final item in counts) item.registrations], LightModeColors.lightPrimary);
    _drawSeries(canvas, size, maxValue, [for (final item in counts) item.posts], LightModeColors.lightInfo);
  }

  void _drawSeries(Canvas canvas, Size size, int maxValue, List<int> values, Color color) {
    if (values.isEmpty) return;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final point = Offset(size.width * index / math.max(1, values.length - 1), size.height - (values[index] / maxValue * size.height));
      if (index == 0) path.moveTo(point.dx, point.dy); else path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant AdminTrendChartPainter oldDelegate) => oldDelegate.counts != counts;
}

class AdminReportsCard extends StatelessWidget {
  final List<DashboardReport> reports;

  const AdminReportsCard({super.key, required this.reports});

  @override
  Widget build(BuildContext context) => AdminPanelCard(
    title: 'admin.dashboard.reportsTitle'.tr(),
    trailing: HBButton.ghost(label: 'common.see_all'.tr(), onPressed: () => context.go('/admin/reports'), size: HBButtonSize.sm),
    child: reports.isEmpty
        ? HBEmptyState(icon: Icons.report_outlined, title: 'admin.dashboard.noReports'.tr(), message: 'admin.p05.noReportsMessage'.tr(), padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg))
        : Column(children: [for (final report in reports) AdminReportRow(report: report)]),
  );
}

class AdminReportRow extends StatelessWidget {
  final DashboardReport report;

  const AdminReportRow({super.key, required this.report});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(children: [
      HBStatusChip(kind: report.priority == 'high' ? HBStatusKind.rejected : report.priority == 'medium' ? HBStatusKind.pending : HBStatusKind.neutral, label: 'admin.reports.priority.${report.priority}'.tr()),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('admin.p05.reasons.${report.reason}'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.semiBold),
        Text('${'admin.p05.targets.${report.targetType}'.tr()} · ${relativeTime(context, report.createdAt)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      ])),
    ]),
  );
}

class AdminBadgeRequestsCard extends StatelessWidget {
  final List<DashboardBadgeRequest> requests;

  const AdminBadgeRequestsCard({super.key, required this.requests});

  @override
  Widget build(BuildContext context) => AdminPanelCard(
    title: 'admin.p05.badgesTitle'.tr(),
    trailing: HBButton.ghost(label: 'common.see_all'.tr(), onPressed: () => context.go('/admin/approvals'), size: HBButtonSize.sm),
    child: requests.isEmpty
        ? HBEmptyState(icon: Icons.verified_outlined, title: 'admin.p05.noBadges'.tr(), message: 'admin.p05.noBadgesMessage'.tr(), padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg))
        : Column(children: [for (final request in requests) AdminBadgeRequestRow(request: request)]),
  );
}

class AdminBadgeRequestRow extends StatelessWidget {
  final DashboardBadgeRequest request;

  const AdminBadgeRequestRow({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final badgeKey = switch (request.badgeType) { 'gun_shop' => 'gunShop', _ => request.badgeType };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(children: [
        HBAvatar(size: 34, name: request.user.displayName, imageUrl: request.user.avatarUrl),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(request.user.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.semiBold),
          Text('${'admin.badges.type.$badgeKey'.tr()} · ${relativeTime(context, request.createdAt)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
        ])),
      ]),
    );
  }
}

class AdminAuditCard extends StatelessWidget {
  final List<DashboardAuditEntry> entries;

  const AdminAuditCard({super.key, required this.entries});

  @override
  Widget build(BuildContext context) => AdminPanelCard(
    title: 'admin.p05.activityTitle'.tr(),
    child: entries.isEmpty
        ? HBEmptyState(icon: Icons.history_outlined, title: 'admin.p05.activityEmpty'.tr(), message: 'admin.p05.activityEmptyMessage'.tr(), padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg))
        : Column(children: [for (final entry in entries) AdminAuditRow(entry: entry)]),
  );
}

class AdminAuditRow extends StatelessWidget {
  final DashboardAuditEntry entry;

  const AdminAuditRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(children: [
      HBAvatar(size: 34, name: entry.admin?.displayName, imageUrl: entry.admin?.avatarUrl),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(entry.admin?.displayName.isNotEmpty == true ? entry.admin!.displayName : 'admin.p05.unknownAdmin'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.semiBold),
        Text('${_actionLabel(entry.action)} · ${_resourceLabel(entry.resourceType)} · ${relativeTime(context, entry.createdAt)}', maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      ])),
    ]),
  );

  String _actionLabel(String action) => 'admin.p05.auditActions.${switch (action) { 'login' => 'login', 'logout' => 'logout', 'view' => 'view', 'create' => 'create', 'update' => 'update', 'delete' => 'delete', 'approve' => 'approve', 'reject' => 'reject', _ => 'other' }}'.tr();

  String _resourceLabel(String? resource) => 'admin.p05.auditResources.${switch (resource) { 'user' || 'user_profile' => 'user', 'post' => 'post', 'report' => 'report', 'verification_request' => 'badgeRequest', 'listing' => 'listing', 'event' => 'event', 'group' => 'group', null => 'none', _ => 'other' }}'.tr();
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
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: context.textStyles.titleMedium?.withColor(LightModeColors.lightOnSurface).bold), if (subtitle != null) Text(subtitle!, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary))])),
        if (trailing != null) Flexible(child: trailing!),
      ]),
      const SizedBox(height: AppSpacing.md),
      child,
    ]),
  );
}

class AdminDashboardSkeleton extends StatelessWidget {
  const AdminDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(children: [
    GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: MediaQuery.sizeOf(context).width >= 900 ? 4 : 2, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: 2, children: [for (var index = 0; index < 8; index++) const HBSkeleton(height: 120)]),
    const SizedBox(height: AppSpacing.md),
    const HBSkeleton(height: 300),
    const SizedBox(height: AppSpacing.md),
    const HBSkeleton(height: 240),
  ]);
}

class AdminDashboardError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const AdminDashboardError({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final key = error is AppException ? (error as AppException).messageKey : 'admin.p05.loadError';
    return HBEmptyState(icon: Icons.error_outline, title: 'admin.p05.loadErrorTitle'.tr(), message: key.tr(), action: HBButton.primary(label: 'common.retry'.tr(), onPressed: onRetry));
  }
}