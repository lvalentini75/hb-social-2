import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_bar_chart.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/domain/ad_models.dart';
import 'package:hb_social/features/ads/domain/ad_reports.dart';
import 'package:hb_social/features/ads/presentation/ad_manager_tabs.dart';
import 'package:hb_social/features/ads/presentation/widgets/ad_preview_card.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';

class AdCampaignDetailPage extends ConsumerStatefulWidget {
  final String campaignId;
  const AdCampaignDetailPage({super.key, required this.campaignId});
  @override ConsumerState<AdCampaignDetailPage> createState() => _AdCampaignDetailPageState();
}

class _AdCampaignDetailPageState extends ConsumerState<AdCampaignDetailPage> {
  int tab = 0;
  Future<void> _status(AdCampaign campaign, AdCampaignStatus status) async { try { await ref.read(adsRepositoryProvider).setCampaignStatus(campaign.id, status); ref.invalidate(adCampaignAggregateProvider(widget.campaignId)); ref.invalidate(adCampaignsProvider(campaign.accountId)); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
  @override Widget build(BuildContext context) => PageColumns(center: ref.watch(adCampaignAggregateProvider(widget.campaignId)).when(loading: () => const CustomScrollView(slivers: [SliverToBoxAdapter(child: HBListSkeleton())]), error: (_, __) => CustomScrollView(slivers: [SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'ads.errors.load_title'.tr(), message: 'ads.errors.load_message'.tr())))]), data: (report) => report == null ? CustomScrollView(slivers: [SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.lock_outline, title: 'ads.errors.permission_title'.tr(), message: 'ads.errors.permission_message'.tr())))]) : CampaignDetailScroll(report: report, tab: tab, onTab: (value) => setState(() => tab = value), onStatus: (status) => _status(report.campaign, status))));
}

class CampaignDetailScroll extends ConsumerWidget {
  final AdCampaignAggregateReport report;
  final int tab;
  final ValueChanged<int> onTab;
  final ValueChanged<AdCampaignStatus> onStatus;
  const CampaignDetailScroll({super.key, required this.report, required this.tab, required this.onTab, required this.onStatus});
  @override Widget build(BuildContext context, WidgetRef ref) { final campaign = report.campaign; return CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [CampaignHeader(report: report, onStatus: onStatus), const SizedBox(height: AppSpacing.lg), HBSegmentedTabs(scrollable: true, labels: ['ads_p37b.tabs.overview'.tr(), 'ads_p37b.tabs.groups'.tr(), 'ads_p37b.tabs.creatives'.tr(), 'ads_p37b.tabs.settings'.tr()], selectedIndex: tab, onChanged: onTab), const SizedBox(height: AppSpacing.lg), if (tab == 0) CampaignOverview(report: report), if (tab == 1) CampaignGroups(report: report), if (tab == 2) CampaignCreatives(report: report), if (tab == 3) CampaignSettings(campaign: campaign)]))]); }
}

class CampaignHeader extends StatelessWidget {
  final AdCampaignAggregateReport report;
  final ValueChanged<AdCampaignStatus> onStatus;
  const CampaignHeader({super.key, required this.report, required this.onStatus});
  @override Widget build(BuildContext context) { final c = report.campaign; final locale = context.locale; final progress = c.budgetMinor == 0 ? 0.0 : (c.spentMinor / c.budgetMinor).clamp(0.0, 1.0); return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.name, style: context.textStyles.headlineSmall), InkWell(onTap: () => context.go(AppRoutes.adAccountPath(c.accountId)), child: Text(report.accountName, style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightPrimary)))])), HBStatusChip(kind: c.status == AdCampaignStatus.active ? HBStatusKind.approved : c.status == AdCampaignStatus.rejected ? HBStatusKind.rejected : HBStatusKind.pending, label: c.status.labelKey.tr()), PopupMenuButton<AdCampaignStatus>(onSelected: onStatus, itemBuilder: (_) => [for (final status in _actions(c.status)) PopupMenuItem(value: status, child: Text('ads.actions.${status.code}'.tr()))])]), Text('${c.objective.labelKey.tr()} · ${DateFormat.yMd(context.locale.toString()).format(c.startsAt.toLocal())}${c.endsAt == null ? '' : ' - ${DateFormat.yMd(context.locale.toString()).format(c.endsAt!.toLocal())}'}'), if (c.pauseReason?.isNotEmpty == true || c.rejectionReason?.isNotEmpty == true) ...[const SizedBox(height: AppSpacing.sm), HBTile(child: Text(c.rejectionReason ?? 'ads_p37b.pause.${c.pauseReason}'.tr()))], const SizedBox(height: AppSpacing.md), LinearProgressIndicator(value: progress), const SizedBox(height: AppSpacing.xs), Text('ads.campaigns.spent'.tr(namedArgs: {'spent': MoneyFormatter.format(amountMinor: c.spentMinor, currencyCode: c.currencyCode, locale: locale), 'total': MoneyFormatter.format(amountMinor: c.budgetMinor, currencyCode: c.currencyCode, locale: locale)}))])); }
}

class CampaignOverview extends StatelessWidget {
  final AdCampaignAggregateReport report;
  const CampaignOverview({super.key, required this.report});
  @override Widget build(BuildContext context) { final t = report.totals; final currency = report.campaign.currencyCode; final locale = context.locale; if (report.daily.isEmpty && !{AdCampaignStatus.active, AdCampaignStatus.completed}.contains(report.campaign.status)) return HBCard(child: HBEmptyState(icon: Icons.insights_outlined, title: 'ads_p37b.no_delivery'.tr(), message: 'ads_p37b.no_delivery_message'.tr())); return Column(children: [Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [_metric(context, 'ads_p37b.impressions', '${t.impressions}'), _metric(context, 'ads_p37b.clicks', '${t.clicks}'), _metric(context, 'ads_p37b.conversions', '${t.conversions}'), _metric(context, 'ads_p37b.reach', '${t.reach}'), _metric(context, 'ads_p37b.ctr', '${t.ctrBasisPoints ~/ 100},${(t.ctrBasisPoints % 100).toString().padLeft(2, '0')}%'), _metric(context, 'ads_p37b.cpm', MoneyFormatter.format(amountMinor: t.cpmMinor, currencyCode: currency, locale: locale)), _metric(context, 'ads_p37b.cpc', MoneyFormatter.format(amountMinor: t.cpcMinor, currencyCode: currency, locale: locale)), _metric(context, 'ads_p37b.spend', MoneyFormatter.format(amountMinor: t.spendMinor, currencyCode: currency, locale: locale))]), const SizedBox(height: AppSpacing.md), HBCard(child: report.daily.isEmpty ? HBEmptyState(icon: Icons.bar_chart, title: 'ads_p37b.no_period_data'.tr(), message: 'ads_p37b.no_period_data_message'.tr()) : HbBarChart(points: [for (final point in report.daily) HbBarChartPoint(day: point.day, value: point.impressions)])), const SizedBox(height: AppSpacing.md), HBCard(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: AdminDataTable(headers: ['ads_p37b.placement'.tr(), 'ads_p37b.impressions'.tr(), 'ads_p37b.clicks'.tr(), 'ads_p37b.ctr'.tr(), 'ads_p37b.spend'.tr()], emptyMessage: 'ads_p37b.no_period_data'.tr(), rows: [for (final row in report.byPlacement) [Text('ads.placement.${row['placement']}'.tr()), Text('${row['impressions'] ?? 0}'), Text('${row['clicks'] ?? 0}'), Text('${row['ctr'] ?? 0}%'), Text(MoneyFormatter.format(amountMinor: (row['spend_minor'] as num?)?.toInt() ?? 0, currencyCode: currency, locale: locale))]])))]); }
  Widget _metric(BuildContext context, String key, String value) => SizedBox(width: 155, child: HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(key.tr(), style: context.textStyles.bodySmall), Text(value, style: context.textStyles.titleLarge)])));
}

class CampaignGroups extends ConsumerWidget {
  final AdCampaignAggregateReport report;
  const CampaignGroups({super.key, required this.report});
  @override Widget build(BuildContext context, WidgetRef ref) => report.adSets.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.layers_outlined, title: 'ads_p37b.groups_empty'.tr(), message: 'ads_p37b.groups_empty_message'.tr())) : Column(children: [for (final set in report.adSets) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(set['name']?.toString() ?? '', style: context.textStyles.titleMedium)), HBStatusChip(kind: set['status'] == 'active' ? HBStatusKind.approved : HBStatusKind.neutral, label: 'ads_p37b.status.${set['status']}'.tr()), Switch(value: set['status'] == 'active', onChanged: (active) async { await ref.read(adsRepositoryProvider).setAdSetStatus(set['id'].toString(), active ? 'active' : 'paused'); ref.invalidate(adCampaignAggregateProvider(report.campaign.id)); })]), Wrap(spacing: AppSpacing.xs, children: [for (final placement in set['placements'] as List? ?? const []) HBChip(label: 'ads.placement.$placement'.tr())]), Text('ads_p37b.group_totals'.tr(namedArgs: {'impressions': '${set['impressions'] ?? 0}', 'clicks': '${set['clicks'] ?? 0}'})), const Divider(), for (final ad in set['ads'] as List? ?? const []) ListTile(contentPadding: EdgeInsets.zero, title: Text((ad as Map)['name']?.toString() ?? ''), subtitle: Text('${ad['impressions'] ?? 0} · ${ad['clicks'] ?? 0}'), trailing: HBStatusChip(kind: HBStatusKind.neutral, label: 'ads_p37b.status.${ad['status']}'.tr()))])))]);
}

class CampaignCreatives extends ConsumerWidget {
  final AdCampaignAggregateReport report;
  const CampaignCreatives({super.key, required this.report});
  @override Widget build(BuildContext context, WidgetRef ref) { final creatives = <Map<String, dynamic>>[]; for (final set in report.adSets) { for (final ad in set['ads'] as List? ?? const []) { final creative = (ad as Map)['creative']; if (creative is Map && !creatives.any((item) => item['id'] == creative['id'])) creatives.add(Map<String, dynamic>.from(creative)); } } if (creatives.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.auto_awesome_motion_outlined, title: 'ads.creatives.empty_title'.tr(), message: 'ads.creatives.empty_message'.tr())); return Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [for (final raw in creatives) SizedBox(width: 350, child: Column(children: [AdPreviewCard(client: ref.watch(supabaseClientProvider), advertiserName: report.accountName, headline: raw['headline']?.toString() ?? '', body: raw['body']?.toString() ?? '', cta: raw['cta']?.toString() ?? 'learn_more', media: (raw['media'] as List? ?? const []).whereType<Map>().map((item) => AdCreativeMedia.fromJson(Map<String, dynamic>.from(item))).toList()), const SizedBox(height: AppSpacing.xs), HBStatusChip(kind: raw['review_status'] == 'approved' ? HBStatusKind.approved : raw['review_status'] == 'rejected' ? HBStatusKind.rejected : HBStatusKind.pending, label: 'ads.review.${raw['review_status']}'.tr()), if (raw['review_note'] != null) Text(raw['review_note'].toString())]))]); }
}

class CampaignSettings extends StatelessWidget {
  final AdCampaign campaign;
  const CampaignSettings({super.key, required this.campaign});
  @override Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ads_p37b.settings'.tr(), style: context.textStyles.titleMedium), ListTile(contentPadding: EdgeInsets.zero, title: Text('ads.fields.name'.tr()), subtitle: Text(campaign.name)), ListTile(contentPadding: EdgeInsets.zero, title: Text('ads.wizard.objective'.tr()), subtitle: Text(campaign.objective.labelKey.tr())), ListTile(contentPadding: EdgeInsets.zero, title: Text('ads.fields.total_budget_short'.tr()), subtitle: Text(MoneyFormatter.format(amountMinor: campaign.budgetMinor, currencyCode: campaign.currencyCode, locale: context.locale))), if ({AdCampaignStatus.draft, AdCampaignStatus.rejected, AdCampaignStatus.paused, AdCampaignStatus.scheduled, AdCampaignStatus.active}.contains(campaign.status)) HBButton.secondary(label: 'common.edit'.tr(), onPressed: () => context.go(AppRoutes.adCampaignEditPath(campaign.accountId, campaign.id)))]));
}

List<AdCampaignStatus> _actions(AdCampaignStatus status) => switch (status) { AdCampaignStatus.draft => [AdCampaignStatus.inReview, AdCampaignStatus.archived], AdCampaignStatus.inReview => [AdCampaignStatus.draft], AdCampaignStatus.active || AdCampaignStatus.scheduled => [AdCampaignStatus.paused, AdCampaignStatus.archived], AdCampaignStatus.paused => [AdCampaignStatus.active, AdCampaignStatus.archived], AdCampaignStatus.rejected => [AdCampaignStatus.draft, AdCampaignStatus.archived], _ => [AdCampaignStatus.archived] };