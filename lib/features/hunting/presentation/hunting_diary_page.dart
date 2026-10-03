import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/events/presentation/events_page.dart';
import 'package:hb_social/features/hunting/domain/hunting_outing.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';

class HuntingDiaryPage extends ConsumerWidget {
  const HuntingDiaryPage({super.key});

  void _record(BuildContext context) => showComingSoonInfo(context, icon: Icons.menu_book_outlined, title: 'common.coming_soon_title'.tr(), message: 'diary.p27_message'.tr());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(diaryViewProvider);
    final filter = ref.watch(diaryFilterProvider);
    return ListPageScaffold(
      title: 'diary.title'.tr(),
      subtitle: 'diary.subtitle'.tr(),
      action: HBButton.primary(label: 'diary.record'.tr(), icon: Icons.add_rounded, onPressed: () => _record(context)),
      filters: Column(children: [
        const DiaryStatsRow(),
        const SizedBox(height: AppSpacing.lg),
        HBSegmentedTabs(labels: ['diary.view_outings'.tr(), 'diary.view_stats'.tr()], selectedIndex: view, onChanged: (index) => ref.read(diaryViewProvider.notifier).state = index),
        if (view == 0) ...[
          const SizedBox(height: AppSpacing.md),
          HBFilterChipsRow(labels: ['diary.filter_current'.tr(), 'diary.filter_all'.tr(), 'diary.filter_harvest'.tr(), 'diary.filter_dogs'.tr()], selectedIndex: filter, onChanged: (index) => ref.read(diaryFilterProvider.notifier).state = index),
        ],
      ]),
      body: view == 0 ? DiaryOutingsList(onRecord: () => _record(context)) : const DiaryStatisticsEmpty(),
      rail: const DiaryRail(),
    );
  }
}

class DiaryStatsRow extends StatelessWidget {
  const DiaryStatsRow({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final columns = constraints.maxWidth >= 600 ? 4 : 2;
    final width = (constraints.maxWidth - (columns - 1) * AppSpacing.sm) / columns;
    final labels = ['diary.stat_outings', 'diary.stat_harvests', 'diary.stat_km', 'diary.stat_hours'];
    return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final label in labels) SizedBox(width: width, child: DiaryStatTile(label: label.tr()))]);
  });
}

class DiaryStatTile extends StatelessWidget {
  final String label;
  const DiaryStatTile({super.key, required this.label});

  @override
  Widget build(BuildContext context) => HBCard(radius: AppRadius.md, padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('—', style: context.textStyles.headlineSmall?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: AppSpacing.xs), Text(label, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant))]));
}

class DiaryOutingsList extends ConsumerWidget {
  final VoidCallback onRecord;
  const DiaryOutingsList({super.key, required this.onRecord});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(outingsProvider).when(
    loading: () => const HBListSkeleton(count: 4),
    error: (error, stack) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'diary.error_title'.tr(), message: 'diary.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(outingsProvider)))),
    data: (items) => items.isEmpty
        ? HBCard(child: HBEmptyState(icon: Icons.menu_book_outlined, title: 'diary.empty_title'.tr(), message: 'diary.empty_message'.tr(), action: HBButton.primary(label: 'diary.record'.tr(), onPressed: onRecord)))
        : Column(children: [for (final outing in items) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: DiaryOutingCard(outing: outing))]),
  );
}

class DiaryOutingCard extends StatelessWidget {
  final HuntingOuting outing;
  const DiaryOutingCard({super.key, required this.outing});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push(AppRoutes.huntingDiaryDetailPath(outing.id)),
    child: HBCard(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
      EventDateBlock(date: outing.startedAt?.toLocal()),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(outing.zoneName ?? 'diary.default_outing'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text('${outing.species.isEmpty ? '—' : outing.species.join(', ')} · ${outing.dogIds.isEmpty ? '—' : outing.dogIds.length} · ${outing.weather ?? '—'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      ])),
      const SizedBox(width: AppSpacing.sm),
      HBStatusChip(kind: HBStatusKind.neutral, label: outing.harvestCount?.toString() ?? '—'),
    ])),
  );
}

class DiaryStatisticsEmpty extends StatelessWidget {
  const DiaryStatisticsEmpty({super.key});

  @override
  Widget build(BuildContext context) => AspectRatio(aspectRatio: 16 / 9, child: Container(decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.lg)), child: HBEmptyState(icon: Icons.bar_chart_rounded, title: 'diary.chart_empty'.tr(), message: 'diary.chart_empty_message'.tr())));
}

class DiaryRail extends ConsumerWidget {
  const DiaryRail({super.key});

  void _export(BuildContext context) => showComingSoonInfo(context, icon: Icons.file_download_outlined, title: 'common.coming_soon_title'.tr(), message: 'diary.p27_message'.tr());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    return Column(children: [
      PageRailCard(label: 'diary.rail_season'.tr(), child: Column(children: [for (final key in ['diary.stat_outings', 'diary.stat_harvests', 'diary.rail_species', 'diary.rail_favorite_zone']) DiaryRailRow(label: key.tr(), value: '—')])),
      const SizedBox(height: AppSpacing.md),
      PageRailCard(label: 'diary.rail_export'.tr(), child: Row(children: [Expanded(child: HBButton.soft(label: 'PDF', onPressed: () => _export(context))), const SizedBox(width: AppSpacing.sm), Expanded(child: HBButton.soft(label: 'CSV', onPressed: () => _export(context)))])),
      const SizedBox(height: AppSpacing.md),
      PageRailCard(label: 'diary.rail_units'.tr(), child: Row(children: [Expanded(child: Text((settings.measurementSystem == MeasurementSystem.metric ? 'settings.metric' : 'settings.imperial').tr())), HBButton.ghost(label: 'diary.change'.tr(), size: HBButtonSize.sm, onPressed: () => context.go(AppRoutes.settings))])),
    ]);
  }
}

class DiaryRailRow extends StatelessWidget {
  final String label;
  final String value;
  const DiaryRailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), child: Row(children: [Expanded(child: Text(label, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))), Text(value, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600))]));
}