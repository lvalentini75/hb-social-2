import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_bar_chart.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';

class AdAccountReportTab extends ConsumerWidget {
  final String accountId;
  const AdAccountReportTab({super.key, required this.accountId});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(adAccountReportProvider(accountId)).when(loading: () => const HBListSkeleton(), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'ads.errors.load_title'.tr(), message: 'ads.errors.load_message'.tr())), data: (report) { if (report == null) return HBCard(child: HBEmptyState(icon: Icons.lock_outline, title: 'ads.errors.permission_title'.tr(), message: 'ads.errors.permission_message'.tr())); final currency = report.account.currencyCode; return Column(children: [Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [_tile(context, 'ads_p37b.impressions', '${report.totals.impressions}'), _tile(context, 'ads_p37b.clicks', '${report.totals.clicks}'), _tile(context, 'ads_p37b.conversions', '${report.totals.conversions}'), _tile(context, 'ads_p37b.spend', MoneyFormatter.format(amountMinor: report.totals.spendMinor, currencyCode: currency, locale: context.locale))]), const SizedBox(height: AppSpacing.md), HBCard(child: report.daily.isEmpty ? HBEmptyState(icon: Icons.bar_chart, title: 'ads_p37b.no_period_data'.tr(), message: 'ads_p37b.no_period_data_message'.tr()) : HbBarChart(points: [for (final row in report.daily) HbBarChartPoint(day: row.day, value: row.impressions)])), const SizedBox(height: AppSpacing.md), HBCard(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: AdminDataTable(headers: ['ads.fields.name'.tr(), 'ads_p37b.status_label'.tr(), 'ads_p37b.impressions'.tr(), 'ads_p37b.clicks'.tr(), 'ads_p37b.ctr'.tr(), 'ads_p37b.spend'.tr(), 'ads.fields.total_budget_short'.tr()], emptyMessage: 'ads.campaigns.empty_title'.tr(), rowCallbacks: [for (final row in report.campaigns) () => context.go(AppRoutes.adCampaignPath(row['id'].toString()))], rows: [for (final row in report.campaigns) [Text(row['name']?.toString() ?? ''), Text('ads.campaign_status.${row['status']}'.tr()), Text('${row['impressions'] ?? 0}'), Text('${row['clicks'] ?? 0}'), Text('${row['ctr'] ?? 0}%'), Text(MoneyFormatter.format(amountMinor: (row['spend_minor'] as num?)?.toInt() ?? 0, currencyCode: currency, locale: context.locale)), Text(MoneyFormatter.format(amountMinor: (row['total_budget_minor'] as num?)?.toInt() ?? 0, currencyCode: currency, locale: context.locale))]]))), const SizedBox(height: AppSpacing.md), HBTile(child: Text('ads_p37b.report_counts'.tr(namedArgs: {'members': '${report.members}', 'audiences': '${report.audiences}', 'creatives': '${report.creatives}'})))]); });
  Widget _tile(BuildContext context, String key, String value) => SizedBox(width: 180, child: HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(key.tr()), Text(value, style: context.textStyles.titleLarge)])));
}