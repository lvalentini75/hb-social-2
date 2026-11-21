import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_page_header.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/ads/domain/boost_models.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';

class MyBoostsPage extends ConsumerStatefulWidget {
  const MyBoostsPage({super.key});
  @override ConsumerState<MyBoostsPage> createState() => _MyBoostsPageState();
}

class _MyBoostsPageState extends ConsumerState<MyBoostsPage> {
  int tab = 0;
  @override Widget build(BuildContext context) {
    final value = ref.watch(myBoostsProvider);
    return PageColumns(center: NotificationListener<ScrollNotification>(onNotification: (value) { if (value.metrics.extentAfter < 400) ref.read(myBoostsProvider.notifier).loadMore(); return false; }, child: CustomScrollView(slivers: [
      SliverPadding(padding: const EdgeInsets.only(top: AppSpacing.sm), sliver: SliverToBoxAdapter(child: HBPageHeader(title: 'boost.my_title'.tr(), subtitle: 'boost.my_subtitle'.tr()))),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
      SliverToBoxAdapter(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: HBSegmentedTabs(labels: ['boost.active'.tr(), 'boost.finished'.tr()], selectedIndex: tab, onChanged: (value) => setState(() => tab = value)))),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
      ...value.when(loading: () => [const SliverToBoxAdapter(child: HBListSkeleton())], error: (_, __) => [SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'boost.error_title'.tr(), message: 'boost.quote_error'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(myBoostsProvider)))))], data: (items) { final visible = items.where((item) => tab == 0 ? item.isActive : !item.isActive).toList(); if (visible.isEmpty) return [SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.rocket_launch_outlined, title: 'boost.empty_title'.tr(), message: 'boost.empty_message'.tr())))]; return [SliverList.separated(itemCount: visible.length, separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md), itemBuilder: (_, index) => BoostListCard(boost: visible[index]))]; }),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
    ])));
  }
}

class BoostListCard extends ConsumerWidget {
  final Boost boost;
  const BoostListCard({super.key, required this.boost});
  Future<void> stop(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text('boost.stop_title'.tr()), content: Text('boost.stop_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop(false)), HBButton.primary(label: 'boost.stop'.tr(), onPressed: () => dialog.pop(true))])) ?? false;
    if (!confirmed) return;
    try { await ref.read(adsRepositoryProvider).stopBoost(boost.campaignId); ref.invalidate(myBoostsProvider); ref.invalidate(boostStatusProvider(BoostTargetRequest(boost.targetType, boost.targetId))); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }
  @override Widget build(BuildContext context, WidgetRef ref) {
    final progress = boost.totalBudgetMinor == 0 ? 0.0 : (boost.spentMinor / boost.totalBudgetMinor).clamp(0.0, 1.0);
    final money = (int value) => MoneyFormatter.format(amountMinor: value, currencyCode: boost.currencyCode, locale: context.locale);
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: SizedBox(width: 72, height: 72, child: boost.destination.imagePath?.isNotEmpty == true ? Image.network(boost.destination.imagePath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.rocket_launch_outlined))) : const ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.rocket_launch_outlined)))), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(boost.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.xs), Wrap(spacing: AppSpacing.xs, children: [HBChip(label: 'boost.type.${boost.targetType}'.tr(), tag: true), HBStatusChip(kind: boostStatusKind(boost.status), label: 'boost.status.${boost.status}'.tr())])]))]),
      const SizedBox(height: AppSpacing.md), Text('boost.spent_of'.tr(namedArgs: {'spent': money(boost.spentMinor), 'total': money(boost.totalBudgetMinor)})), const SizedBox(height: AppSpacing.xs), LinearProgressIndicator(value: progress, minHeight: 6, borderRadius: BorderRadius.circular(AppRadius.pill)), const SizedBox(height: AppSpacing.sm), Text('boost.metrics'.tr(namedArgs: {'impressions': '${boost.impressions}', 'clicks': '${boost.clicks}', 'conversions': '${boost.conversions}'})), if (boost.endAt != null) Text((boost.isActive ? 'boost.until' : 'boost.ended_on').tr(namedArgs: {'date': DateFormat.yMMMd(context.locale.toLanguageTag()).format(boost.endAt!.toLocal())}), style: context.textStyles.bodySmall), const SizedBox(height: AppSpacing.md), Wrap(spacing: AppSpacing.sm, children: [if (boost.isActive) HBButton.secondary(label: 'boost.stop'.tr(), onPressed: () => stop(context, ref)), HBButton.primary(label: 'boost.open'.tr(), onPressed: boost.destination.route?.startsWith('/') == true ? () => context.push(boost.destination.route!) : null)])
    ]));
  }
}

HBStatusKind boostStatusKind(String status) => switch (status) { 'active' => HBStatusKind.approved, 'in_review' || 'scheduled' => HBStatusKind.pending, 'paused' => HBStatusKind.info, 'rejected' => HBStatusKind.rejected, _ => HBStatusKind.neutral };