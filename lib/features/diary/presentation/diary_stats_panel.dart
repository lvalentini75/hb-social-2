import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_bar_chart.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/features/diary/domain/diary_season_stats.dart';
import 'package:hb_social/features/diary/presentation/diary_export.dart';
import 'package:hb_social/features/diary/providers/diary_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';

class DiaryStatsPanel extends ConsumerStatefulWidget {
  final String? userId;
  final String? season;
  final String? previousSeason;
  final bool owner;
  final UserProfile? profile;
  final String regionName;
  final ValueChanged<String> onPlaceSelected;
  const DiaryStatsPanel({super.key, this.userId, required this.season, this.previousSeason, required this.owner, this.profile, this.regionName = '', required this.onPlaceSelected});
  @override
  ConsumerState<DiaryStatsPanel> createState() => _DiaryStatsPanelState();
}

class _DiaryStatsPanelState extends ConsumerState<DiaryStatsPanel> {
  String series = 'outings';

  Future<DiaryExportData?> _exportData() async {
    final profile = widget.profile;
    if (profile == null) return null;
    final request = (userId: widget.userId, season: widget.season);
    final stats = await ref.read(diaryStatsProvider(request).future);
    final outings = await ref.read(diaryExportOutingsProvider(request).future);
    final names = await ref.read(speciesNamesProvider.future);
    return DiaryExportData(stats: stats, outings: outings, profile: profile, regionName: widget.regionName, speciesNames: names, locale: context.locale.languageCode);
  }

  Future<void> _previewPdf() async {
    try { final data = await _exportData(); if (data != null && mounted) await showDialog<void>(context: context, useSafeArea: false, builder: (_) => DiaryPdfPreview(data: data)); }
    catch (_) { if (mounted) _exportError(); }
  }

  Future<void> _exportCsv() async { try { final data = await _exportData(); if (data != null) await DiaryExportService.shareCsv(data); } catch (_) { if (mounted) _exportError(); } }
  void _exportError() => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('diary.error_message'.tr())));

  @override
  Widget build(BuildContext context) {
    final request = (userId: widget.userId, season: widget.season);
    final previous = widget.previousSeason == null ? null : ref.watch(diaryStatsProvider((userId: widget.userId, season: widget.previousSeason))).value;
    final names = ref.watch(speciesNamesProvider).value ?? const <String, String>{};
    return ref.watch(diaryStatsProvider(request)).when(
      loading: () => const HBListSkeleton(count: 5),
      error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'diary.error_title'.tr(), message: 'diary.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(diaryStatsProvider(request))))),
      data: (stats) {
        if (stats.totals.outings == 0) return HBCard(child: HBEmptyState(icon: Icons.analytics_outlined, title: 'diary.stats.empty_title'.tr(), message: 'diary.stats.empty_message'.tr()));
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (widget.owner) Align(alignment: Alignment.centerRight, child: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBButton.primary(label: 'diary.export.pdf'.tr(), icon: Icons.picture_as_pdf_outlined, onPressed: _previewPdf), HBButton.secondary(label: 'diary.export.csv'.tr(), icon: Icons.table_view_outlined, onPressed: _exportCsv)])),
          if (widget.owner) const SizedBox(height: AppSpacing.md),
          DiaryKpiGrid(stats: stats, previous: previous), const SizedBox(height: AppSpacing.md),
          DiaryChartTile(title: 'diary.stats.by_month'.tr(), controls: [HBChip(label: 'diary.stats.outings'.tr(), selected: series == 'outings', onTap: () => setState(() => series = 'outings')), HBChip(label: 'diary.stats.harvests'.tr(), selected: series == 'harvests', onTap: () => setState(() => series = 'harvests'))], chart: HbBarChart(points: [for (final item in stats.byMonth) HbBarChartPoint(day: DateTime.tryParse('${item.key}-01') ?? DateTime.now(), value: series == 'outings' ? item.outings : item.harvests, label: DateFormat.MMM(context.locale.languageCode).format(DateTime.tryParse('${item.key}-01') ?? DateTime.now()))])),
          const SizedBox(height: AppSpacing.md), DiaryChartTile(title: 'diary.stats.by_weekday'.tr(), chart: HbBarChart(points: [for (final item in stats.byWeekday) HbBarChartPoint(day: DateTime.now(), value: item.outings, label: 'diary.stats.weekday.${item.key}'.tr())])),
          const SizedBox(height: AppSpacing.md), DiaryChartTile(title: 'diary.stats.by_method'.tr(), chart: HbBarChart(horizontal: true, height: 160, points: [for (final item in stats.byMethod) HbBarChartPoint(day: DateTime.now(), value: item.outings, label: 'diary.method.${item.key}'.tr())])),
          const SizedBox(height: AppSpacing.md), DiaryStatsLists(stats: stats, names: names, onPlaceSelected: widget.onPlaceSelected),
          const SizedBox(height: AppSpacing.md), HBTile(child: Text('diary.stats.weather_summary'.tr(namedArgs: {'temperature': stats.weather.averageTemperature?.toStringAsFixed(1) ?? '-', 'rainy': '${stats.weather.rainyOutings}', 'total': '${stats.weather.withWeather}'}))),
          const SizedBox(height: AppSpacing.md), InkWell(onTap: () => context.go(AppRoutes.hunting), child: Text('diary.stats.note'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightPrimary).copyWith(decoration: TextDecoration.underline))),
        ]);
      },
    );
  }
}

class DiaryKpiGrid extends StatelessWidget {
  final DiarySeasonStats stats;
  final DiarySeasonStats? previous;
  const DiaryKpiGrid({super.key, required this.stats, this.previous});
  @override
  Widget build(BuildContext context) {
    final current = stats.totals;
    final old = previous?.totals;
    final values = <(String, String, num?, num)>[
      ('diary.stats.outings', '${current.outings}', old?.outings, current.outings), ('diary.stats.hours', current.hours.toStringAsFixed(1), old?.hours, current.hours), ('diary.stats.harvests', '${current.harvests}', old?.harvests, current.harvests), ('diary.stats.with_harvest', 'diary.stats.of_total'.tr(namedArgs: {'n': '${current.outingsWithHarvest}', 'm': '${current.outings}'}), old?.outingsWithHarvest, current.outingsWithHarvest), ('diary.stats.distance', (current.distanceM / 1000).toStringAsFixed(1), old == null ? null : old.distanceM / 1000, current.distanceM / 1000), ('diary.stats.zones', '${current.zones}', old?.zones, current.zones), ('diary.stats.best_outing', 'diary.stats.harvest_count'.tr(namedArgs: {'n': '${current.bestOutingHarvest}'}), old?.bestOutingHarvest, current.bestOutingHarvest),
    ];
    return LayoutBuilder(builder: (_, constraints) { final columns = constraints.maxWidth >= 760 ? 4 : 2; final width = (constraints.maxWidth - (columns - 1) * AppSpacing.md) / columns; return Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [for (final item in values) SizedBox(width: width, child: DiaryKpiTile(label: item.$1.tr(), value: item.$2, previous: item.$3, current: item.$4))]); });
  }
}

class DiaryKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final num? previous;
  final num current;
  const DiaryKpiTile({super.key, required this.label, required this.value, this.previous, required this.current});
  @override
  Widget build(BuildContext context) { final delta = previous == null ? null : current - previous!; final kind = delta == null || delta == 0 ? HBStatusKind.neutral : delta > 0 ? HBStatusKind.approved : HBStatusKind.rejected; return HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), const SizedBox(height: AppSpacing.xs), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.headlineSmall), if (delta != null) ...[const SizedBox(height: AppSpacing.xs), HBStatusChip(kind: kind, label: delta == 0 ? '=' : '${delta > 0 ? '+' : ''}${delta is double ? delta.toStringAsFixed(1) : delta}')]])); }
}

class DiaryChartTile extends StatelessWidget {
  final String title;
  final List<Widget> controls;
  final Widget chart;
  const DiaryChartTile({super.key, required this.title, this.controls = const [], required this.chart});
  @override
  Widget build(BuildContext context) => HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(title, style: context.textStyles.titleMedium)), if (controls.isNotEmpty) Wrap(spacing: AppSpacing.xs, children: controls)]), const SizedBox(height: AppSpacing.md), chart]));
}

class DiaryStatsLists extends StatelessWidget {
  final DiarySeasonStats stats;
  final Map<String, String> names;
  final ValueChanged<String> onPlaceSelected;
  const DiaryStatsLists({super.key, required this.stats, required this.names, required this.onPlaceSelected});
  @override
  Widget build(BuildContext context) => Column(children: [
    HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('diary.stats.species'.tr(), style: context.textStyles.titleMedium), for (final item in stats.bySpecies) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(names[item.speciesId] ?? item.nameIt.ifEmpty(item.scientificName), style: context.textStyles.titleSmall), Text('hunting.category.${item.category}'.tr(), style: context.textStyles.bodySmall)])), Flexible(child: Text('diary.stats.species_values'.tr(namedArgs: {'harvests': '${item.harvests}', 'seen': '${item.seen}', 'shots': '${item.shots}', 'outings': '${item.outings}', 'success': item.shots == 0 ? '-' : '${(item.harvests * 100 / item.shots).round()}%'}), textAlign: TextAlign.end, style: context.textStyles.bodySmall))]))])),
    const SizedBox(height: AppSpacing.md), LayoutBuilder(builder: (_, constraints) => constraints.maxWidth >= 700 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: DiaryPlacesList(items: stats.byPlace, onSelected: onPlaceSelected)), const SizedBox(width: AppSpacing.md), Expanded(child: DiaryDogsList(items: stats.byDog))]) : Column(children: [DiaryPlacesList(items: stats.byPlace, onSelected: onPlaceSelected), const SizedBox(height: AppSpacing.md), DiaryDogsList(items: stats.byDog)])),
  ]);
}

class DiaryPlacesList extends StatelessWidget {
  final List<DiaryPlaceStat> items;
  final ValueChanged<String> onSelected;
  const DiaryPlacesList({super.key, required this.items, required this.onSelected});
  @override
  Widget build(BuildContext context) => HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('diary.stats.places'.tr(), style: context.textStyles.titleMedium), for (final item in items) InkWell(onTap: item.unitId == null ? null : () => onSelected(item.unitId!), child: Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Row(children: [Expanded(child: Text(item.label)), Text('diary.stats.outings_harvests'.tr(namedArgs: {'outings': '${item.outings}', 'harvests': '${item.harvests}'})), if (item.unitId != null) const Icon(Icons.chevron_right_rounded, size: 18)]))) ]));
}

class DiaryDogsList extends StatelessWidget {
  final List<DiaryDogStat> items;
  const DiaryDogsList({super.key, required this.items});
  @override
  Widget build(BuildContext context) => HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('diary.stats.dogs'.tr(), style: context.textStyles.titleMedium),
    for (final item in items) InkWell(
      onTap: item.dogId.isEmpty ? null : () => context.push(AppRoutes.dogDetailPath(item.dogId)),
      child: Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Row(children: [HBAvatar(name: item.name, imageUrl: item.avatarUrl, size: 36), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name), if (item.breed != null) Text(item.breed!, style: context.textStyles.bodySmall)])), Text('diary.stats.outings_harvests'.tr(namedArgs: {'outings': '${item.outings}', 'harvests': '${item.harvests}'})), const Icon(Icons.chevron_right_rounded, size: 18)])),
    ),
  ]));
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}