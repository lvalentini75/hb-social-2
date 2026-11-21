import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/features/reels/domain/reel.dart';
import 'package:hb_social/features/reels/providers/reels_providers.dart';

Future<void> showReelInsights(BuildContext context, String postId) => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: (_) => FractionallySizedBox(heightFactor: .9, child: ReelInsightsSheet(postId: postId)));

class ReelInsightsSheet extends ConsumerWidget {
  final String postId;
  const ReelInsightsSheet({super.key, required this.postId});
  @override Widget build(BuildContext context, WidgetRef ref) => Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: ref.watch(reelInsightsProvider(postId)).when(loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'reels.errors.title'.tr(), message: 'reels.errors.generic'.tr()), data: (value) => ReelInsightsContent(value: value)));
}

class ReelInsightsContent extends StatelessWidget {
  final ReelInsights value;
  const ReelInsightsContent({super.key, required this.value});
  @override Widget build(BuildContext context) {
    final maxViews = value.viewsByDay.fold<int>(1, (max, row) => ((row['views'] as num?)?.toInt() ?? 0) > max ? (row['views'] as num).toInt() : max);
    final bars = <Widget>[];
    for (final row in value.viewsByDay) {
      final views = (row['views'] as num?)?.toInt() ?? 0;
      bars.add(Expanded(child: Tooltip(message: '${row['day']}: $views', child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Container(height: 150 * views / maxViews, decoration: BoxDecoration(color: LightModeColors.bosco, borderRadius: BorderRadius.circular(AppRadius.xs)))))));
    }
    return CustomScrollView(slivers: [SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('reels.insights.title'.tr(), style: AppText.heading),
      const SizedBox(height: AppSpacing.lg),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [ReelInsightKpi(label: 'reels.insights.views'.tr(), value: '${value.views}'), ReelInsightKpi(label: 'reels.insights.unique'.tr(), value: '${value.uniqueViewers}'), ReelInsightKpi(label: 'reels.insights.plays'.tr(), value: '${value.plays}'), ReelInsightKpi(label: 'reels.insights.completions'.tr(), value: '${value.completions}'), ReelInsightKpi(label: 'reels.insights.rate'.tr(), value: '${(value.completionRate * 100).toStringAsFixed(1)}%'), ReelInsightKpi(label: 'reels.insights.average'.tr(), value: '${value.averageWatchedSeconds.toStringAsFixed(1)} s')]),
      const SizedBox(height: AppSpacing.lg),
      Text('reels.insights.last_14_days'.tr(), style: AppText.cardTitle),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(height: 160, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: bars)),
      const SizedBox(height: AppSpacing.lg),
      Text('reels.insights.engagement'.tr(namedArgs: {'reactions': '${value.reactions}', 'comments': '${value.comments}', 'shares': '${value.shares}'}), style: AppText.body),
      if (value.byCountry.isNotEmpty) ...[const SizedBox(height: AppSpacing.lg), Text('reels.insights.countries'.tr(), style: AppText.cardTitle), for (final entry in value.byCountry.entries) ListTile(contentPadding: EdgeInsets.zero, title: Text(entry.key), trailing: Text('${entry.value}'))],
    ]))]);
  }
}

class ReelInsightKpi extends StatelessWidget {
  final String label; final String value;
  const ReelInsightKpi({super.key, required this.label, required this.value});
  @override Widget build(BuildContext context) => SizedBox(width: 150, child: HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: AppText.kpi), const SizedBox(height: 4), Text(label, style: AppText.caption.copyWith(color: LightModeColors.textSecondary))])));
}