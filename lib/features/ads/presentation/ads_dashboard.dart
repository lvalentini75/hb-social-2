import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_bar_chart.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/features/ads/domain/ad_reports.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';

class AdsDashboardPanel extends ConsumerWidget {
  const AdsDashboardPanel({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(adsDatePresetProvider).dashboardDays;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('ads_p37b.overview'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), ref.watch(adsDashboardProvider(days)).when(loading: () => const AdsDashboardSkeleton(), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'ads.errors.load_title'.tr(), message: 'ads.errors.load_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(adsDashboardProvider(days))))), data: (data) => AdsDashboardData(data: data))]);
  }
}

class AdsDashboardSkeleton extends StatelessWidget {
  const AdsDashboardSkeleton({super.key});
  @override Widget build(BuildContext context) => const Column(children: [Row(children: [Expanded(child: HBSkeleton(height: 100)), SizedBox(width: 12), Expanded(child: HBSkeleton(height: 100)), SizedBox(width: 12), Expanded(child: HBSkeleton(height: 100)), SizedBox(width: 12), Expanded(child: HBSkeleton(height: 100))]), SizedBox(height: 16), HBSkeleton(height: 240)]);
}

class AdsDashboardData extends StatelessWidget {
  final AdsDashboard data;
  const AdsDashboardData({super.key, required this.data});
  @override Widget build(BuildContext context) {
    final locale = context.locale;
    final spend = data.currencies.isEmpty ? MoneyFormatter.format(amountMinor: data.totals.spendMinor, currencyCode: 'EUR', locale: locale) : data.currencies.map((row) => MoneyFormatter.format(amountMinor: (row['spend_minor'] as num?)?.toInt() ?? 0, currencyCode: row['currency_code']?.toString() ?? 'EUR', locale: locale)).join(' · ');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [LayoutBuilder(builder: (context, box) { final width = (box.maxWidth - 36) / 4; return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [AdsKpiTile(width: width, label: 'ads_p37b.impressions'.tr(), value: '${data.totals.impressions}', current: data.totals.impressions, previous: data.previous.impressions), AdsKpiTile(width: width, label: 'ads_p37b.clicks'.tr(), value: '${data.totals.clicks}', current: data.totals.clicks, previous: data.previous.clicks), AdsKpiTile(width: width, label: 'ads_p37b.ctr'.tr(), value: _percent(data.totals.ctrBasisPoints), current: data.totals.clicks, previous: data.previous.clicks), AdsKpiTile(width: width, label: 'ads_p37b.spend'.tr(), value: spend, current: data.totals.spendMinor, previous: data.previous.spendMinor)]); }), const SizedBox(height: AppSpacing.md), Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [HBChip(label: 'ads_p37b.active_count'.tr(namedArgs: {'n': '${data.activeCampaigns}'})), HBChip(label: 'ads_p37b.review_count'.tr(namedArgs: {'n': '${data.inReview}'})), HBChip(label: 'ads_p37b.rejected_count'.tr(namedArgs: {'n': '${data.rejected}'})), HBChip(label: 'ads_p37b.paused_payment'.tr(namedArgs: {'n': '${data.pausedPayment}'})), HBChip(label: 'ads_p37b.paused_cap'.tr(namedArgs: {'n': '${data.pausedSpendCap}'})), if (data.billingIssues > 0) HBChip(label: 'ads_p37b.billing_issues'.tr(namedArgs: {'n': '${data.billingIssues}'}), selected: true), if (data.missingPaymentMethod > 0) ActionChip(label: Text('ads_p37b.connect_card'.tr()), onPressed: () => context.go(AppRoutes.billing))]), const SizedBox(height: AppSpacing.md), HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ads_p37b.daily_chart'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.md), if (data.daily.isEmpty) HBEmptyState(icon: Icons.bar_chart_rounded, title: 'ads_p37b.no_period_data'.tr(), message: 'ads_p37b.no_period_data_message'.tr()) else HbBarChart(points: [for (final point in data.daily) HbBarChartPoint(day: point.day, value: point.impressions)])])), const SizedBox(height: AppSpacing.md), AdsTopCampaigns(items: data.topCampaigns), if (data.unbilledMinor > 0 || data.outstandingMinor > 0) ...[const SizedBox(height: AppSpacing.md), HBTile(child: Text('ads_p37b.amounts_due'.tr(namedArgs: {'unbilled': MoneyFormatter.format(amountMinor: data.unbilledMinor, currencyCode: data.currencies.firstOrNull?['currency_code']?.toString() ?? 'EUR', locale: locale), 'outstanding': MoneyFormatter.format(amountMinor: data.outstandingMinor, currencyCode: data.currencies.firstOrNull?['currency_code']?.toString() ?? 'EUR', locale: locale)})))] ]);
  }
}

class AdsKpiTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final int current;
  final int previous;
  const AdsKpiTile({super.key, required this.width, required this.label, required this.value, required this.current, required this.previous});
  @override Widget build(BuildContext context) { final delta = previous == 0 ? null : ((current - previous) * 100 ~/ previous.abs()); final positive = (delta ?? 0) >= 0; return SizedBox(width: width < 150 ? 150 : width, child: HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: context.textStyles.bodySmall), Text(value, style: context.textStyles.headlineSmall), Row(children: [Icon(delta == null ? Icons.remove : positive ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: delta == null ? LightModeColors.lightTextTertiary : positive ? LightModeColors.lightSuccess : LightModeColors.lightError), Text(delta == null ? '—' : '${delta.abs()}%', style: context.textStyles.labelSmall?.withColor(delta == null ? LightModeColors.lightTextTertiary : positive ? LightModeColors.lightSuccess : LightModeColors.lightError))])]))); }
}

class AdsTopCampaigns extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const AdsTopCampaigns({super.key, required this.items});
  @override Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ads_p37b.top_campaigns'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), if (items.isEmpty) HBEmptyState(icon: Icons.campaign_outlined, title: 'ads.campaigns.empty_title'.tr(), message: 'ads.campaigns.empty_message'.tr()) else for (final item in items) ListTile(contentPadding: EdgeInsets.zero, title: Text(item['name']?.toString() ?? ''), subtitle: Text('${item['account_name'] ?? ''} · ${item['impressions'] ?? 0} ${'ads_p37b.impressions'.tr().toLowerCase()}'), trailing: HBStatusChip(kind: HBStatusKind.neutral, label: 'ads.campaign_status.${item['status']}'.tr()), onTap: () => context.go(AppRoutes.adCampaignPath(item['id'].toString())))]));
}

String _percent(int basisPoints) => '${basisPoints ~/ 100},${(basisPoints % 100).toString().padLeft(2, '0')}%';