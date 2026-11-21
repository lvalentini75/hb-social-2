import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_bar_chart.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';

class StudioMetrics {
  final Map<String, int> values;
  const StudioMetrics(this.values);
  int value(String key) => values[key] ?? 0;
  factory StudioMetrics.fromJson(Map<String, dynamic> json, Iterable<String> keys) => StudioMetrics({for (final key in keys) key: (json[key] as num?)?.toInt() ?? 0});
}

class StudioSeriesPoint {
  final DateTime day;
  final StudioMetrics metrics;
  const StudioSeriesPoint({required this.day, required this.metrics});
}

class StudioStats {
  final int days;
  final StudioMetrics totals;
  final StudioMetrics period;
  final StudioMetrics previous;
  final List<StudioSeriesPoint> series;
  const StudioStats({required this.days, required this.totals, required this.period, required this.previous, required this.series});

  factory StudioStats.fromJson(Map<String, dynamic> json, Iterable<String> metricKeys) {
    final keys = metricKeys.toList();
    Map<String, dynamic> map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : const {};
    final points = (json['series'] as List? ?? const []).map((value) {
      final item = map(value);
      return StudioSeriesPoint(day: DateTime.parse(item['day'].toString()).toLocal(), metrics: StudioMetrics.fromJson(item, keys));
    }).toList();
    return StudioStats(days: (json['days'] as num?)?.toInt() ?? 30, totals: StudioMetrics.fromJson(map(json['totals']), keys), period: StudioMetrics.fromJson(map(json['period']), keys), previous: StudioMetrics.fromJson(map(json['previous']), keys), series: points);
  }
}

class StudioOverviewList {
  final String title;
  final List<Widget> children;
  const StudioOverviewList({required this.title, required this.children});
}

/// Shared analytics overview used by forum, group and page studios.
class StudioOverview extends StatelessWidget {
  final StudioStats stats;
  final Map<String, String> labels;
  final List<String> series;
  final String selectedSeries;
  final ValueChanged<int> onPeriodChanged;
  final ValueChanged<String> onSeriesChanged;
  final List<StudioOverviewList> lists;

  const StudioOverview({super.key, required this.stats, required this.labels, required this.series, required this.selectedSeries, required this.onPeriodChanged, required this.onSeriesChanged, required this.lists});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Wrap(spacing: AppSpacing.sm, children: [for (final days in const [7, 30, 90]) HBChip(label: 'studio_overview.days'.tr(namedArgs: {'days': '$days'}), selected: stats.days == days, onTap: () => onPeriodChanged(days))]),
    const SizedBox(height: AppSpacing.md),
    StudioKpiGrid(stats: stats, labels: labels),
    const SizedBox(height: AppSpacing.md),
    HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('studio_overview.chart_title'.tr(), style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: AppSpacing.sm),
      Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final key in series) HBChip(label: labels[key] ?? key, selected: selectedSeries == key, onTap: () => onSeriesChanged(key))]),
      const SizedBox(height: AppSpacing.md),
      HbBarChart(points: stats.series.map((point) => HbBarChartPoint(day: point.day, value: point.metrics.value(selectedSeries))).toList()),
    ])),
    const SizedBox(height: AppSpacing.md),
    StudioOverviewLists(lists: lists),
  ]);
}

class StudioKpiGrid extends StatelessWidget {
  final StudioStats stats;
  final Map<String, String> labels;
  const StudioKpiGrid({super.key, required this.stats, required this.labels});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final columns = constraints.maxWidth >= 760 ? 4 : 2;
    final width = (constraints.maxWidth - (columns - 1) * AppSpacing.md) / columns;
    return Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [for (final key in labels.keys) SizedBox(width: width, child: StudioKpiCard(label: labels[key]!, period: stats.period.value(key), total: stats.totals.value(key), previous: stats.previous.value(key)))]);
  });
}

class StudioKpiCard extends StatelessWidget {
  final String label;
  final int period;
  final int total;
  final int previous;
  const StudioKpiCard({super.key, required this.label, required this.period, required this.total, required this.previous});

  @override
  Widget build(BuildContext context) {
    final delta = period - previous;
    final isNew = previous == 0 && period > 0;
    final kind = delta > 0 ? HBStatusKind.approved : delta < 0 ? HBStatusKind.rejected : HBStatusKind.neutral;
    final change = isNew ? 'studio_overview.new'.tr() : delta == 0 ? '=' : '${delta > 0 ? '▲ +' : '▼ '}$delta';
    return HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), const SizedBox(height: AppSpacing.xs), Text('$period', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.displaySmall), const SizedBox(height: AppSpacing.xs), Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [Text('studio_overview.total'.tr(namedArgs: {'count': '$total'}), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall), HBStatusChip(kind: kind, label: change)])]));
  }
}

class StudioOverviewLists extends StatelessWidget {
  final List<StudioOverviewList> lists;
  const StudioOverviewLists({super.key, required this.lists});

  @override
  Widget build(BuildContext context) {
    final cards = lists.map((list) => StudioOverviewListCard(list: list)).toList();
    return LayoutBuilder(builder: (_, constraints) => constraints.maxWidth >= 820 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (var index = 0; index < cards.length; index++) ...[Expanded(child: cards[index]), if (index < cards.length - 1) const SizedBox(width: AppSpacing.md)]]) : Column(children: [for (var index = 0; index < cards.length; index++) ...[cards[index], if (index < cards.length - 1) const SizedBox(height: AppSpacing.md)]]));
  }
}

class StudioOverviewListCard extends StatelessWidget {
  final StudioOverviewList list;
  const StudioOverviewListCard({super.key, required this.list});

  @override
  Widget build(BuildContext context) => HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(list.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: AppSpacing.sm), if (list.children.isEmpty) HBEmptyState(icon: Icons.inbox_outlined, title: 'studio_overview.empty'.tr(), message: 'studio_overview.empty_message'.tr()) else ...list.children]));
}