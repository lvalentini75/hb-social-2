import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_bar_chart.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/domain/ad_models.dart';
import 'package:hb_social/features/ads/domain/ad_reports.dart';
import 'package:hb_social/features/ads/presentation/ad_account_billing.dart';
import 'package:hb_social/features/ads/presentation/widgets/ad_preview_card.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:share_plus/share_plus.dart';

enum AdsEntityLevel { campaigns, adSets, ads }
enum AdsBreakdown { none, day, placement }

class AdCampaignsManager extends ConsumerStatefulWidget {
  final AdAccount account;
  const AdCampaignsManager({super.key, required this.account});
  @override ConsumerState<AdCampaignsManager> createState() => _AdCampaignsManagerState();
}

class _AdCampaignsManagerState extends ConsumerState<AdCampaignsManager> {
  AdsEntityLevel level = AdsEntityLevel.campaigns;
  AdsBreakdown breakdown = AdsBreakdown.none;
  AdCampaignStatus? statusFilter;
  String columnPreset = 'performance';
  final selectedCampaigns = <String>{};
  String? detailCampaignId;
  bool busy = false;

  bool get writable => widget.account.kind != 'personal' && widget.account.myRole != AdAccountRole.analyst && widget.account.status == AdAccountStatus.active;
  AdReportRequest get request { final range = ref.read(adsDatePresetProvider).range; return AdReportRequest(widget.account.id, range.from, range.to); }

  Future<void> setStatus(List<AdCampaign> campaigns, AdCampaignStatus status) async {
    if (campaigns.isEmpty) return;
    final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text('ads_manager.confirm_status'.tr()), content: Text('ads_manager.confirm_count'.tr(namedArgs: {'count': '${campaigns.length}'})), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop(false)), HBButton.primary(label: 'ads_manager.confirm'.tr(), onPressed: () => dialog.pop(true))])) ?? false;
    if (!confirmed || !mounted) return;
    setState(() => busy = true);
    try { for (final campaign in campaigns) { await ref.read(adsRepositoryProvider).setCampaignStatus(campaign.id, status); } _refresh(); } on AppException catch (error) { _error(error); } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> duplicate(AdCampaign campaign) async {
    setState(() => busy = true);
    try {
      final id = await ref.read(adsRepositoryProvider).duplicateCampaign(campaign, 'ads_manager.copy_suffix'.tr());
      _refresh();
      if (mounted) context.go(AppRoutes.adCampaignEditPath(widget.account.id, id));
    } on AppException catch (error) { _error(error); } finally { if (mounted) setState(() => busy = false); }
  }

  void _refresh() { ref.invalidate(adCampaignsProvider(widget.account.id)); ref.invalidate(adAccountPeriodReportProvider(request)); ref.invalidate(adAccountCampaignReportsProvider(request)); }
  void _error(AppException error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(adsDatePresetProvider).range;
    final currentRequest = AdReportRequest(widget.account.id, range.from, range.to);
    final reports = ref.watch(adAccountCampaignReportsProvider(currentRequest));
    final report = ref.watch(adAccountPeriodReportProvider(currentRequest));
    final billing = ref.watch(adAccountPeriodBillingProvider(currentRequest));
    final campaigns = ref.watch(adCampaignsProvider(widget.account.id));
    final search = ref.watch(adsManagerSearchProvider).trim().toLowerCase();
    final mobile = MediaQuery.sizeOf(context).width < 1024;
    final allCampaigns = campaigns.value ?? const <AdCampaign>[];
    final visibleCampaigns = allCampaigns.where((item) => (statusFilter == null || item.status == statusFilter) && (search.isEmpty || item.name.toLowerCase().contains(search) || item.objective.labelKey.tr().toLowerCase().contains(search))).toList();
    final selected = allCampaigns.where((item) => selectedCampaigns.contains(item.id)).toList();
    return Stack(children: [
      CustomScrollView(slivers: [SliverPadding(padding: EdgeInsets.fromLTRB(mobile ? AppSpacing.sm : AppSpacing.lg, AppSpacing.lg, mobile ? AppSpacing.sm : AppSpacing.lg, mobile ? 100 : AppSpacing.lg), sliver: SliverList.list(children: [
        AdsManagerKpis(report: report, billing: billing, account: widget.account, mobile: mobile), const SizedBox(height: AppSpacing.md),
        HBCard(padding: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0), child: HBSegmentedTabs(variant: mobile ? HBSegmentedTabsVariant.pill : HBSegmentedTabsVariant.underlined, labels: ['ads_manager.level.campaigns'.tr(namedArgs: {'count': '${allCampaigns.length}'}), 'ads_manager.level.adSets'.tr(namedArgs: {'count': '${_setCount(reports.value)}'}), 'ads_manager.level.ads'.tr(namedArgs: {'count': '${_adCount(reports.value)}'})], selectedIndex: level.index, onChanged: (value) => setState(() => level = AdsEntityLevel.values[value]))),
          if (selectedCampaigns.isNotEmpty && level != AdsEntityLevel.campaigns) Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: Align(alignment: Alignment.centerLeft, child: HBChip(label: 'ads_manager.filtered_campaigns'.tr(namedArgs: {'count': '${selectedCampaigns.length}'}), selected: true, onTap: () => setState(selectedCampaigns.clear)))),
          if (!mobile) AdsManagerToolbar(level: level, writable: writable, selectedCount: level == AdsEntityLevel.campaigns ? selected.length : 0, busy: busy, onCreate: () => context.go(AppRoutes.adCampaignNewPath(widget.account.id)), onDuplicate: selected.length == 1 ? () => duplicate(selected.single) : null, onEdit: selected.length == 1 ? () => context.go(AppRoutes.adCampaignEditPath(widget.account.id, selected.single.id)) : null, onToggle: selected.isEmpty ? null : () => setStatus(selected, selected.every((item) => item.status == AdCampaignStatus.paused) ? AdCampaignStatus.active : AdCampaignStatus.paused), statusFilter: statusFilter, onStatusFilter: (value) => setState(() => statusFilter = value), columnPreset: columnPreset, onColumnPreset: (value) => setState(() => columnPreset = value), breakdown: breakdown, onBreakdown: (value) => setState(() => breakdown = value), onExport: () => _export(report.value)),
          AnimatedSwitcher(duration: AppMotion.of(context).medium, transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween(begin: const Offset(.02, 0), end: Offset.zero).animate(animation), child: child)), child: reports.when(loading: () => const AdsManagerTableSkeleton(key: ValueKey('loading')), error: (_, __) => HBEmptyState(key: const ValueKey('error'), icon: Icons.error_outline_rounded, title: 'ads.errors.load_title'.tr(), message: 'ads.errors.load_message'.tr()), data: (values) => level == AdsEntityLevel.campaigns ? CampaignManagerTable(key: const ValueKey('campaigns'), account: widget.account, campaigns: visibleCampaigns, report: report.value, selected: selectedCampaigns, breakdown: breakdown, writable: writable, onSelected: (id, value) => setState(() => value ? selectedCampaigns.add(id) : selectedCampaigns.remove(id)), onOpen: (id) => setState(() => detailCampaignId = id), onStatus: (campaign, status) => setStatus([campaign], status), mobile: mobile) : level == AdsEntityLevel.adSets ? AdSetsManagerTable(key: const ValueKey('sets'), reports: values, campaignFilter: selectedCampaigns, account: widget.account, writable: writable, mobile: mobile, search: search) : AdsManagerAdsTable(key: const ValueKey('ads'), reports: values, campaignFilter: selectedCampaigns, account: widget.account, mobile: mobile, search: search))),
        ])),
      ]))]),
      if (mobile && writable) Positioned(right: AppSpacing.md, bottom: AppSpacing.md, child: HBButton.primary(label: 'ads_manager.create_campaign'.tr(), icon: Icons.add_rounded, onPressed: () => context.go(AppRoutes.adCampaignNewPath(widget.account.id)))),
      if (detailCampaignId != null) CampaignDetailOverlay(campaignId: detailCampaignId!, account: widget.account, onClose: () => setState(() => detailCampaignId = null)),
    ]);
  }

  Future<void> _export(AdAccountReport? report) async {
    if (report == null) return;
    final rows = <List<String>>[['ads_manager.columns.campaign'.tr(), 'ads_p37b.impressions'.tr(), 'ads_p37b.clicks'.tr(), 'ads_p37b.spend'.tr()], for (final row in report.campaigns) [row['name']?.toString() ?? '', '${row['impressions'] ?? 0}', '${row['clicks'] ?? 0}', '${row['spend_minor'] ?? 0}']];
    final csv = rows.map((row) => row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(',')).join('\n');
    await Share.shareXFiles([XFile.fromData(Uint8List.fromList(utf8.encode(csv)), mimeType: 'text/csv', name: 'campaigns.csv')]);
  }
}

class AdsManagerKpis extends StatelessWidget {
  final AsyncValue<AdAccountReport?> report;
  final AsyncValue<AdAccountBilling?> billing;
  final AdAccount account;
  final bool mobile;
  const AdsManagerKpis({super.key, required this.report, required this.billing, required this.account, required this.mobile});
  @override Widget build(BuildContext context) => report.when(loading: () => const AdsManagerKpiSkeleton(), error: (_, __) => const AdsManagerKpiSkeleton(), data: (value) { final totals = value?.totals; final tiles = [AdsManagerKpi(label: 'ads_manager.kpi.spend'.tr(), value: _money(context, totals?.spendMinor ?? 0), delta: null), AdsManagerKpi(label: 'ads_p37b.impressions'.tr(), value: '${totals?.impressions ?? 0}', delta: null), AdsManagerKpi(label: 'ads_p37b.clicks'.tr(), value: '${totals?.clicks ?? 0}', delta: null), AdsManagerKpi(label: 'ads_manager.kpi.ctr_cpc'.tr(), value: '${_percent(totals?.ctrBasisPoints ?? 0)} · ${_money(context, totals?.cpcMinor ?? 0)}', delta: null)]; if (mobile) return Column(children: [GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 1.55, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm, children: tiles), const SizedBox(height: AppSpacing.sm), billing.when(loading: () => const HBSkeleton(height: 112), error: (_, __) => const SizedBox.shrink(), data: (data) => data == null ? const SizedBox.shrink() : AdsNextChargeCard(account: account, billing: data))]); return SizedBox(height: 174, child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final tile in tiles) ...[Expanded(child: tile), const SizedBox(width: AppSpacing.sm)], Expanded(flex: 2, child: billing.when(loading: () => const HBSkeleton(height: 174), error: (_, __) => const SizedBox.shrink(), data: (data) => data == null ? const SizedBox.shrink() : AdsNextChargeCard(account: account, billing: data)))])); });
  String _money(BuildContext context, int value) => MoneyFormatter.format(amountMinor: value, currencyCode: account.currencyCode, locale: context.locale);
}

class AdsManagerKpi extends StatelessWidget {
  final String label;
  final String value;
  final int? delta;
  const AdsManagerKpi({super.key, required this.label, required this.value, this.delta});
  @override Widget build(BuildContext context) => HBCard(compact: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: context.textStyles.bodySmall), TweenAnimationBuilder<double>(duration: AppMotion.of(context).count, tween: Tween(begin: 0, end: 1), builder: (_, animation, child) => Opacity(opacity: animation, child: child), child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.displaySmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]))), Text(delta == null ? '—' : '${delta! >= 0 ? '+' : ''}$delta%', style: context.textStyles.labelSmall?.withColor(delta == null ? LightModeColors.lightTextTertiary : delta! >= 0 ? LightModeColors.lightSuccess : LightModeColors.lightError))]));
}

class AdsManagerKpiSkeleton extends StatelessWidget { const AdsManagerKpiSkeleton({super.key}); @override Widget build(BuildContext context) => const Column(children: [Row(children: [Expanded(child: HBSkeleton(height: 110)), SizedBox(width: 12), Expanded(child: HBSkeleton(height: 110)), SizedBox(width: 12), Expanded(child: HBSkeleton(height: 110)), SizedBox(width: 12), Expanded(child: HBSkeleton(height: 110))]), SizedBox(height: 12), HBSkeleton(height: 150)]); }

class AdsNextChargeCard extends ConsumerWidget {
  final AdAccount account;
  final AdAccountBilling billing;
  const AdsNextChargeCard({super.key, required this.account, required this.billing});
  @override Widget build(BuildContext context, WidgetRef ref) { final warning = billing.billingStatus != 'ok'; final method = billing.paymentMethod; String money(int value) => MoneyFormatter.format(amountMinor: value, currencyCode: billing.currencyCode, locale: context.locale); return HBCard(color: warning ? LightModeColors.lightErrorContainer : LightModeColors.lightSurface, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(method == null ? 'ads_manager.billing.connect'.tr() : 'ads_manager.billing.next'.tr(namedArgs: {'last4': method['last4']?.toString() ?? ''}), style: context.textStyles.titleMedium)), if (warning) HBStatusChip(kind: HBStatusKind.rejected, label: 'ads_p37b.billing_banner.${billing.billingStatus}'.tr())]), const SizedBox(height: AppSpacing.sm), TweenAnimationBuilder<double>(duration: AppMotion.of(context).count, tween: Tween(begin: 0, end: billing.thresholdProgress / 100), builder: (_, value, __) => LinearProgressIndicator(value: value)), const SizedBox(height: AppSpacing.xs), Text('ads_manager.billing.progress'.tr(namedArgs: {'unbilled': money(billing.unbilledMinor), 'threshold': money(billing.thresholdMinor)})), Text('ads_manager.billing.help'.tr(namedArgs: {'date': billing.nextCutoffOn == null ? '—' : DateFormat.yMd(context.locale.toString()).format(billing.nextCutoffOn!), 'credit': money(billing.creditBalanceMinor)}), style: context.textStyles.bodySmall), if (method == null) HBButton.ghost(label: 'ads_p37b.connect_card'.tr(), onPressed: () => context.go(AppRoutes.billing)), if (warning) Wrap(spacing: AppSpacing.sm, children: [if (billing.charges.isNotEmpty) HBButton.secondary(label: 'ads_p37b.retry_now'.tr(), onPressed: () => _retry(context, ref)), HBButton.ghost(label: 'ads_p37b.change_card'.tr(), onPressed: () => context.go(AppRoutes.billing))]) ])); }

  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    final failed = billing.charges.where((charge) => charge['status'] == 'failed').firstOrNull ?? billing.charges.firstOrNull;
    if (failed == null) return;
    try {
      await ref.read(adsRepositoryProvider).retryAdCharge(failed['id'].toString());
      ref.invalidate(adAccountBillingProvider(account.id));
      ref.invalidate(adAccountPeriodBillingProvider);
    } on AppException catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
    }
  }
}

class AdsManagerToolbar extends StatelessWidget {
  final AdsEntityLevel level;
  final bool writable;
  final int selectedCount;
  final bool busy;
  final VoidCallback onCreate;
  final VoidCallback? onDuplicate;
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;
  final AdCampaignStatus? statusFilter;
  final ValueChanged<AdCampaignStatus?> onStatusFilter;
  final String columnPreset;
  final ValueChanged<String> onColumnPreset;
  final AdsBreakdown breakdown;
  final ValueChanged<AdsBreakdown> onBreakdown;
  final VoidCallback onExport;
  const AdsManagerToolbar({super.key, required this.level, required this.writable, required this.selectedCount, required this.busy, required this.onCreate, this.onDuplicate, this.onEdit, this.onToggle, required this.statusFilter, required this.onStatusFilter, required this.columnPreset, required this.onColumnPreset, required this.breakdown, required this.onBreakdown, required this.onExport});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [if (writable) HBButton.primary(label: 'ads_manager.toolbar.create'.tr(), icon: Icons.add_rounded, onPressed: busy ? null : onCreate, size: HBButtonSize.sm), if (writable) HBButton.secondary(label: 'ads_manager.toolbar.duplicate'.tr(), icon: Icons.copy_outlined, onPressed: onDuplicate, size: HBButtonSize.sm), if (writable) HBButton.secondary(label: 'ads_manager.toolbar.edit'.tr(), icon: Icons.edit_outlined, onPressed: onEdit, size: HBButtonSize.sm), if (writable) HBButton.secondary(label: 'ads_manager.toolbar.pause'.tr(), icon: Icons.pause_circle_outline, onPressed: onToggle, size: HBButtonSize.sm), PopupMenuButton<AdCampaignStatus?>(initialValue: statusFilter, onSelected: onStatusFilter, itemBuilder: (_) => [PopupMenuItem<AdCampaignStatus?>(value: null, child: Text('ads.filters.all'.tr())), for (final item in AdCampaignStatus.values) PopupMenuItem<AdCampaignStatus?>(value: item, child: Text(item.labelKey.tr()))], child: _ToolbarPill(label: statusFilter == null ? 'ads_manager.toolbar.filters'.tr() : statusFilter!.labelKey.tr(), icon: Icons.filter_list_rounded)), PopupMenuButton<String>(initialValue: columnPreset, onSelected: onColumnPreset, itemBuilder: (_) => [for (final item in const ['performance', 'delivery', 'billing', 'custom']) PopupMenuItem(value: item, child: Text('ads_manager.columns.$item'.tr()))], child: _ToolbarPill(label: 'ads_manager.columns.$columnPreset'.tr())), PopupMenuButton<AdsBreakdown>(initialValue: breakdown, onSelected: onBreakdown, itemBuilder: (_) => [for (final item in AdsBreakdown.values) PopupMenuItem(value: item, child: Text('ads_manager.breakdown.${item.name}'.tr()))], child: _ToolbarPill(label: 'ads_manager.toolbar.breakdown'.tr())), HBButton.ghost(label: 'ads_manager.toolbar.export'.tr(), icon: Icons.download_outlined, onPressed: onExport, size: HBButtonSize.sm)]));
}

class _ToolbarPill extends StatelessWidget { final String label; final IconData? icon; const _ToolbarPill({required this.label, this.icon}); @override Widget build(BuildContext context) => Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), decoration: BoxDecoration(border: Border.all(color: LightModeColors.lightBorder), borderRadius: BorderRadius.circular(AppRadius.pill)), child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: AppSpacing.xs)], Text(label, style: context.textStyles.labelMedium), const Icon(Icons.arrow_drop_down_rounded)])); }

class CampaignManagerTable extends StatelessWidget {
  final AdAccount account;
  final List<AdCampaign> campaigns;
  final AdAccountReport? report;
  final Set<String> selected;
  final AdsBreakdown breakdown;
  final bool writable;
  final bool mobile;
  final void Function(String, bool) onSelected;
  final ValueChanged<String> onOpen;
  final void Function(AdCampaign, AdCampaignStatus) onStatus;
  const CampaignManagerTable({super.key, required this.account, required this.campaigns, this.report, required this.selected, required this.breakdown, required this.writable, required this.mobile, required this.onSelected, required this.onOpen, required this.onStatus});
  @override Widget build(BuildContext context) { final rowsById = {for (final row in report?.campaigns ?? const <Map<String, dynamic>>[]) row['id']?.toString(): row}; final visible = campaigns; if (visible.isEmpty) return Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: HBEmptyState(icon: Icons.campaign_outlined, title: 'ads_manager.empty.campaigns'.tr(), message: 'ads.campaigns.empty_message'.tr(), action: writable ? HBButton.primary(label: 'ads_manager.create_campaign'.tr(), onPressed: () => context.go(AppRoutes.adCampaignNewPath(account.id))) : null)); if (mobile) return Column(children: [for (final campaign in visible) CampaignMobileCard(campaign: campaign, metrics: rowsById[campaign.id], writable: writable, onOpen: () => context.go(AppRoutes.adCampaignPath(campaign.id)), onStatus: onStatus)]); return SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: 1460, child: Column(children: [const CampaignTableHeader(), for (final campaign in visible) ...[CampaignTableRow(campaign: campaign, metrics: rowsById[campaign.id], selected: selected.contains(campaign.id), writable: writable, onSelected: (value) => onSelected(campaign.id, value), onOpen: () => onOpen(campaign.id), onStatus: onStatus), if (breakdown != AdsBreakdown.none) CampaignBreakdownRows(campaignId: campaign.id, breakdown: breakdown)], CampaignTotalsFooter(count: visible.length, rows: rowsById.values.toList(), currency: account.currencyCode)]))); }
}

class CampaignTableHeader extends StatelessWidget { const CampaignTableHeader({super.key}); @override Widget build(BuildContext context) => Container(height: 44, color: LightModeColors.lightBackgroundSoft, child: Row(children: [const SizedBox(width: 96), _Cell('ads_manager.columns.campaign'.tr(), 280, header: true), _Cell('ads_manager.columns.delivery'.tr(), 160, header: true), _Cell('ads_manager.columns.budget'.tr(), 170, header: true), _Cell('ads_manager.columns.results'.tr(), 130, end: true, header: true), _Cell('ads_p37b.reach'.tr(), 110, end: true, header: true), _Cell('ads_p37b.impressions'.tr(), 120, end: true, header: true), _Cell('ads_manager.columns.cost_result'.tr(), 150, end: true, header: true), _Cell('ads_p37b.spend'.tr(), 130, end: true, header: true), _Cell('ads_manager.columns.end'.tr(), 110, header: true)])); }

class CampaignTableRow extends StatelessWidget {
  final AdCampaign campaign;
  final Map<String, dynamic>? metrics;
  final bool selected;
  final bool writable;
  final ValueChanged<bool> onSelected;
  final VoidCallback onOpen;
  final void Function(AdCampaign, AdCampaignStatus) onStatus;
  const CampaignTableRow({super.key, required this.campaign, this.metrics, required this.selected, required this.writable, required this.onSelected, required this.onOpen, required this.onStatus});
  @override Widget build(BuildContext context) { final active = campaign.status == AdCampaignStatus.active || campaign.status == AdCampaignStatus.scheduled; final toggleable = writable && {AdCampaignStatus.active, AdCampaignStatus.scheduled, AdCampaignStatus.paused}.contains(campaign.status); final impressions = _int(metrics?['impressions']); final results = _results(campaign.objective, metrics); final cost = results == 0 ? 0 : _int(metrics?['spend_minor']) ~/ results; return InkWell(onTap: onOpen, hoverColor: LightModeColors.lightBackground, child: AnimatedContainer(duration: AppMotion.of(context).fast, height: 56, color: selected ? LightModeColors.lightBackground : Colors.transparent, child: Row(children: [SizedBox(width: 48, child: Checkbox(value: selected, onChanged: (value) => onSelected(value ?? false))), SizedBox(width: 48, child: Tooltip(message: toggleable ? campaign.status.labelKey.tr() : 'ads_manager.toggle_disabled'.tr(), child: AdsStatusSwitch(value: active, enabled: toggleable, onChanged: (value) => onStatus(campaign, value ? AdCampaignStatus.active : AdCampaignStatus.paused))),), _RichCell(campaign.name, '${campaign.objective.labelKey.tr()} · ${metrics?['ad_sets_count'] ?? 0} · ${metrics?['ads_count'] ?? 0}', 280), _DeliveryCell(campaign: campaign), _RichCell(campaign.dailyBudgetMinor == null ? MoneyFormatter.format(amountMinor: campaign.budgetMinor, currencyCode: campaign.currencyCode, locale: context.locale) : '${MoneyFormatter.format(amountMinor: campaign.dailyBudgetMinor!, currencyCode: campaign.currencyCode, locale: context.locale)} ${'ads_manager.per_day'.tr()}', campaign.dailyBudgetMinor == null ? 'ads_manager.total'.tr() : '${'ads_manager.total'.tr()} ${MoneyFormatter.format(amountMinor: campaign.budgetMinor, currencyCode: campaign.currencyCode, locale: context.locale)}', 170), _RichCell('$results', _resultLabel(campaign.objective), 130, end: true), _Cell('${metrics?['reach'] ?? 0}', 110, end: true), _Cell('$impressions', 120, end: true), _Cell(MoneyFormatter.format(amountMinor: cost, currencyCode: campaign.currencyCode, locale: context.locale), 150, end: true), _Cell(MoneyFormatter.format(amountMinor: _int(metrics?['spend_minor']), currencyCode: campaign.currencyCode, locale: context.locale), 130, end: true, strong: true), _Cell(campaign.endsAt == null ? 'ads_manager.continues'.tr() : DateFormat.yMd(context.locale.toString()).format(campaign.endsAt!.toLocal()), 110)]))); }
}

class AdsStatusSwitch extends StatelessWidget { final bool value; final bool enabled; final ValueChanged<bool> onChanged; const AdsStatusSwitch({super.key, required this.value, required this.enabled, required this.onChanged}); @override Widget build(BuildContext context) => GestureDetector(onTap: enabled ? () => onChanged(!value) : null, child: AnimatedContainer(duration: AppMotion.of(context).base, width: 38, height: 22, padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: value ? LightModeColors.lightPrimary : LightModeColors.lightOutline, borderRadius: BorderRadius.circular(AppRadius.pill)), alignment: value ? Alignment.centerRight : Alignment.centerLeft, child: Container(width: 18, height: 18, decoration: const BoxDecoration(color: LightModeColors.lightSurface, shape: BoxShape.circle)))); }

class _DeliveryCell extends StatelessWidget { final AdCampaign campaign; const _DeliveryCell({required this.campaign}); @override Widget build(BuildContext context) { final color = campaign.status == AdCampaignStatus.active ? LightModeColors.lightSuccess : campaign.status == AdCampaignStatus.rejected ? LightModeColors.lightError : campaign.status == AdCampaignStatus.scheduled ? LightModeColors.lightInfo : LightModeColors.lightNeutralStatus; final reason = campaign.pauseReason == null ? campaign.status.labelKey.tr() : 'ads_manager.delivery.${campaign.pauseReason}'.tr(); return SizedBox(width: 160, child: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: AppSpacing.xs), Expanded(child: Text(reason, overflow: TextOverflow.ellipsis))])); } }
class _Cell extends StatelessWidget { final String value; final double width; final bool end; final bool strong; final bool header; const _Cell(this.value, this.width, {this.end = false, this.strong = false, this.header = false}); @override Widget build(BuildContext context) => SizedBox(width: width, child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), child: Text(value, textAlign: end ? TextAlign.end : TextAlign.start, maxLines: 2, overflow: TextOverflow.ellipsis, style: (header ? context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant) : strong ? context.textStyles.bodyMedium?.semiBold : context.textStyles.bodyMedium)?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])))); }
class _RichCell extends StatelessWidget { final String title; final String subtitle; final double width; final bool end; const _RichCell(this.title, this.subtitle, this.width, {this.end = false}); @override Widget build(BuildContext context) => SizedBox(width: width, child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodyMedium?.semiBold), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]))); }

class CampaignBreakdownRows extends ConsumerWidget { final String campaignId; final AdsBreakdown breakdown; const CampaignBreakdownRows({super.key, required this.campaignId, required this.breakdown}); @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(adCampaignAggregateProvider(campaignId)).when(loading: () => const HBSkeleton(height: 40), error: (_, __) => const SizedBox.shrink(), data: (report) { final rows = breakdown == AdsBreakdown.day ? report?.daily.map((item) => <String, Object?>{'label': DateFormat.yMd(context.locale.toString()).format(item.day), 'impressions': item.impressions, 'clicks': item.clicks, 'spend_minor': item.spendMinor}).toList() ?? const [] : report?.byPlacement.map((item) => <String, Object?>{...item, 'label': 'ads.placement.${item['placement']}'.tr()}).toList() ?? const []; return AnimatedSize(duration: AppMotion.of(context).medium, child: Column(children: [for (final row in rows) Container(height: 40, color: LightModeColors.lightBackgroundSoft, padding: const EdgeInsets.only(left: 96), child: Row(children: [_Cell(row['label']?.toString() ?? '', 610), _Cell('${row['clicks'] ?? 0}', 130, end: true), _Cell('${row['impressions'] ?? 0}', 120, end: true), _Cell('${row['spend_minor'] ?? 0}', 280, end: true)]))])); }); }
class CampaignTotalsFooter extends StatelessWidget { final int count; final List<Map<String, dynamic>> rows; final String currency; const CampaignTotalsFooter({super.key, required this.count, required this.rows, required this.currency}); @override Widget build(BuildContext context) => Container(height: 52, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), decoration: const BoxDecoration(border: Border(top: BorderSide(color: LightModeColors.lightDivider))), child: Row(children: [Expanded(child: Text('ads_manager.results_count'.tr(namedArgs: {'count': '$count'}), style: context.textStyles.labelMedium)), Text('${rows.fold<int>(0, (sum, row) => sum + _int(row['impressions']))} ${'ads_p37b.impressions'.tr().toLowerCase()} · ${MoneyFormatter.format(amountMinor: rows.fold<int>(0, (sum, row) => sum + _int(row['spend_minor'])), currencyCode: currency, locale: context.locale)}', style: context.textStyles.labelMedium)])); }

class CampaignMobileCard extends StatelessWidget {
  final AdCampaign campaign;
  final Map<String, dynamic>? metrics;
  final bool writable;
  final VoidCallback onOpen;
  final void Function(AdCampaign, AdCampaignStatus) onStatus;
  const CampaignMobileCard({super.key, required this.campaign, this.metrics, required this.writable, required this.onOpen, required this.onStatus});

  @override
  Widget build(BuildContext context) {
    final active = {AdCampaignStatus.active, AdCampaignStatus.scheduled}.contains(campaign.status);
    final toggleable = writable && {AdCampaignStatus.active, AdCampaignStatus.scheduled, AdCampaignStatus.paused}.contains(campaign.status);
    final result = _results(campaign.objective, metrics);
    return Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 0), child: HBCard(compact: true, onTap: onOpen, child: Row(children: [
        AdsStatusSwitch(value: active, enabled: toggleable, onChanged: (value) => onStatus(campaign, value ? AdCampaignStatus.active : AdCampaignStatus.paused)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(campaign.name, style: context.textStyles.bodyLarge?.semiBold), Text('${campaign.status.labelKey.tr()} · ${campaign.dailyBudgetMinor == null ? MoneyFormatter.format(amountMinor: campaign.budgetMinor, currencyCode: campaign.currencyCode, locale: context.locale) : MoneyFormatter.format(amountMinor: campaign.dailyBudgetMinor!, currencyCode: campaign.currencyCode, locale: context.locale)}', maxLines: 1, overflow: TextOverflow.ellipsis)])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(MoneyFormatter.format(amountMinor: _int(metrics?['spend_minor']), currencyCode: campaign.currencyCode, locale: context.locale), style: context.textStyles.bodyMedium?.semiBold), Text('$result ${_resultLabel(campaign.objective)}', style: context.textStyles.bodySmall)]),
        if (writable) PopupMenuButton<String>(onSelected: (value) { if (value == 'edit') context.go(AppRoutes.adCampaignEditPath(campaign.accountId, campaign.id)); if (value == 'status') onStatus(campaign, active ? AdCampaignStatus.paused : AdCampaignStatus.active); }, itemBuilder: (_) => [PopupMenuItem(value: 'edit', child: Text('ads_manager.toolbar.edit'.tr())), if (toggleable) PopupMenuItem(value: 'status', child: Text(active ? 'ads_manager.toolbar.pause'.tr() : 'ads.actions.active'.tr()))]),
      ])));
  }
}

class AdSetsManagerTable extends ConsumerWidget {
  final List<AdCampaignAggregateReport> reports;
  final Set<String> campaignFilter;
  final AdAccount account;
  final bool writable;
  final bool mobile;
  final String search;
  const AdSetsManagerTable({super.key, required this.reports, required this.campaignFilter, required this.account, required this.writable, required this.mobile, required this.search});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = [for (final report in reports.where((item) => campaignFilter.isEmpty || campaignFilter.contains(item.campaign.id))) for (final set in report.adSets.where((set) => search.isEmpty || (set['name']?.toString().toLowerCase().contains(search) ?? false) || report.campaign.name.toLowerCase().contains(search))) (report: report, set: set)];
    if (rows.isEmpty) return Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: HBEmptyState(icon: Icons.layers_outlined, title: 'ads_p37b.groups_empty'.tr(), message: 'ads_p37b.groups_empty_message'.tr()));
    Future<void> updateStatus(Map<String, dynamic> set, bool active) async {
      try {
        await ref.read(adsRepositoryProvider).setAdSetStatus(set['id'].toString(), active ? 'active' : 'paused');
        final range = ref.read(adsDatePresetProvider).range;
        ref.invalidate(adAccountCampaignReportsProvider(AdReportRequest(account.id, range.from, range.to)));
      } on AppException catch (error) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
      }
    }
    if (mobile) return Column(children: [for (final row in rows) AdSetMobileCard(report: row.report, data: row.set, account: account, writable: writable, onStatus: (value) => updateStatus(row.set, value))]);
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: 1120, child: Column(children: [
      Container(height: 44, color: LightModeColors.lightBackgroundSoft, child: Row(children: [const SizedBox(width: 64), _Cell('ads_p37b.tabs.groups'.tr(), 300, header: true), _Cell('ads_manager.columns.campaign'.tr(), 260, header: true), _Cell('ads_manager.columns.delivery'.tr(), 150, header: true), _Cell('ads_p37b.impressions'.tr(), 120, end: true, header: true), _Cell('ads_p37b.clicks'.tr(), 100, end: true, header: true), _Cell('ads_p37b.spend'.tr(), 126, end: true, header: true)])),
      for (final row in rows) AdSetManagerRow(report: row.report, data: row.set, account: account, writable: writable, onStatus: (value) => updateStatus(row.set, value)),
    ])));
  }
}

class AdSetManagerRow extends StatelessWidget {
  final AdCampaignAggregateReport report;
  final Map<String, dynamic> data;
  final AdAccount account;
  final bool writable;
  final ValueChanged<bool> onStatus;
  const AdSetManagerRow({super.key, required this.report, required this.data, required this.account, required this.writable, required this.onStatus});
  @override
  Widget build(BuildContext context) { final active = data['status'] == 'active'; return Container(height: 58, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: LightModeColors.lightDivider))), child: Row(children: [SizedBox(width: 64, child: Center(child: AdsStatusSwitch(value: active, enabled: writable, onChanged: onStatus))), _RichCell(data['name']?.toString() ?? '', (data['placements'] as List? ?? const []).map((item) => 'ads.placement.$item'.tr()).join(' · '), 300), _RichCell(report.campaign.name, report.campaign.objective.labelKey.tr(), 260), _Cell('ads_p37b.status.${data['status'] ?? 'draft'}'.tr(), 150), _Cell('${data['impressions'] ?? 0}', 120, end: true), _Cell('${data['clicks'] ?? 0}', 100, end: true), _Cell(MoneyFormatter.format(amountMinor: _int(data['spend_minor']), currencyCode: account.currencyCode, locale: context.locale), 126, end: true, strong: true)])); }
}

class AdSetMobileCard extends StatelessWidget {
  final AdCampaignAggregateReport report;
  final Map<String, dynamic> data;
  final AdAccount account;
  final bool writable;
  final ValueChanged<bool> onStatus;
  const AdSetMobileCard({super.key, required this.report, required this.data, required this.account, required this.writable, required this.onStatus});
  @override
  Widget build(BuildContext context) { final active = data['status'] == 'active'; return Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 0), child: HBCard(compact: true, child: Row(children: [AdsStatusSwitch(value: active, enabled: writable, onChanged: onStatus), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['name']?.toString() ?? '', style: context.textStyles.bodyLarge?.semiBold), Text(report.campaign.name, overflow: TextOverflow.ellipsis), Text('${data['impressions'] ?? 0} ${'ads_p37b.impressions'.tr().toLowerCase()} · ${data['clicks'] ?? 0} ${'ads_p37b.clicks'.tr().toLowerCase()}', style: context.textStyles.bodySmall)])), Text(MoneyFormatter.format(amountMinor: _int(data['spend_minor']), currencyCode: account.currencyCode, locale: context.locale), style: context.textStyles.bodyMedium?.semiBold)]))); }
}

class AdsManagerAdsTable extends ConsumerWidget {
  final List<AdCampaignAggregateReport> reports;
  final Set<String> campaignFilter;
  final AdAccount account;
  final bool mobile;
  final String search;
  const AdsManagerAdsTable({super.key, required this.reports, required this.campaignFilter, required this.account, required this.mobile, required this.search});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = <({AdCampaignAggregateReport report, Map<String, dynamic> set, Map<String, dynamic> ad})>[];
    for (final report in reports.where((item) => campaignFilter.isEmpty || campaignFilter.contains(item.campaign.id))) {
      for (final set in report.adSets) {
        for (final rawAd in set['ads'] as List? ?? const []) {
          if (rawAd is! Map) continue;
          final ad = Map<String, dynamic>.from(rawAd);
          final matches = search.isEmpty || (ad['name']?.toString().toLowerCase().contains(search) ?? false) || (set['name']?.toString().toLowerCase().contains(search) ?? false) || report.campaign.name.toLowerCase().contains(search);
          if (matches) rows.add((report: report, set: set, ad: ad));
        }
      }
    }
    if (rows.isEmpty) return Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: HBEmptyState(icon: Icons.view_carousel_outlined, title: 'ads_manager.empty.ads'.tr(), message: 'ads.creatives.empty_message'.tr()));
    if (mobile) return Column(children: [for (final row in rows) AdManagerMobileCard(report: row.report, set: row.set, ad: row.ad, account: account, onTap: () => _preview(context, ref, row.report, row.ad))]);
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: 1100, child: Column(children: [
      Container(height: 44, color: LightModeColors.lightBackgroundSoft, child: Row(children: [_Cell('ads_manager.level.ads'.tr(namedArgs: {'count': ''}), 300, header: true), _Cell('ads_p37b.tabs.groups'.tr(), 250, header: true), _Cell('ads_manager.columns.campaign'.tr(), 230, header: true), _Cell('ads_manager.columns.delivery'.tr(), 140, header: true), _Cell('ads_p37b.impressions'.tr(), 90, end: true, header: true), _Cell('ads_p37b.spend'.tr(), 90, end: true, header: true)])),
      for (final row in rows) InkWell(onTap: () => _preview(context, ref, row.report, row.ad), child: Container(height: 58, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: LightModeColors.lightDivider))), child: Row(children: [_RichCell(row.ad['name']?.toString() ?? '', 'ads.review.${row.ad['review_status'] ?? 'pending'}'.tr(), 300), _Cell(row.set['name']?.toString() ?? '', 250), _Cell(row.report.campaign.name, 230), SizedBox(width: 140, child: HBStatusChip(kind: row.ad['review_status'] == 'approved' ? HBStatusKind.approved : row.ad['review_status'] == 'rejected' ? HBStatusKind.rejected : HBStatusKind.pending, label: 'ads.review.${row.ad['review_status'] ?? 'pending'}'.tr())), _Cell('${row.ad['impressions'] ?? 0}', 90, end: true), _Cell(MoneyFormatter.format(amountMinor: _int(row.ad['spend_minor']), currencyCode: account.currencyCode, locale: context.locale), 90, end: true, strong: true)]))),
    ])));
  }
  void _preview(BuildContext context, WidgetRef ref, AdCampaignAggregateReport report, Map<String, dynamic> ad) { final raw = ad['creative']; if (raw is! Map) return; showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: AdPreviewCard(client: ref.read(supabaseClientProvider), advertiserName: report.accountName, headline: raw['headline']?.toString() ?? '', body: raw['body']?.toString() ?? '', cta: raw['cta']?.toString() ?? 'learn_more', media: (raw['media'] as List? ?? const []).whereType<Map>().map((item) => AdCreativeMedia.fromJson(Map<String, dynamic>.from(item))).toList()))); }
}

class AdManagerMobileCard extends StatelessWidget {
  final AdCampaignAggregateReport report;
  final Map<String, dynamic> set;
  final Map<String, dynamic> ad;
  final AdAccount account;
  final VoidCallback onTap;
  const AdManagerMobileCard({super.key, required this.report, required this.set, required this.ad, required this.account, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 0), child: HBCard(compact: true, onTap: onTap, child: Row(children: [const SizedBox(width: 48, height: 48, child: ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.image_outlined))), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(ad['name']?.toString() ?? '', style: context.textStyles.bodyLarge?.semiBold), Text('${set['name']} · ${report.campaign.name}', overflow: TextOverflow.ellipsis), HBStatusChip(kind: ad['review_status'] == 'approved' ? HBStatusKind.approved : ad['review_status'] == 'rejected' ? HBStatusKind.rejected : HBStatusKind.pending, label: 'ads.review.${ad['review_status'] ?? 'pending'}'.tr())])), Text(MoneyFormatter.format(amountMinor: _int(ad['spend_minor']), currencyCode: account.currencyCode, locale: context.locale), style: context.textStyles.bodyMedium?.semiBold)])));
}

class AdsManagerTableSkeleton extends StatelessWidget { const AdsManagerTableSkeleton({super.key}); @override Widget build(BuildContext context) => const Padding(padding: EdgeInsets.all(AppSpacing.md), child: Column(children: [HBSkeleton(height: 44), SizedBox(height: 4), HBSkeleton(height: 56), SizedBox(height: 4), HBSkeleton(height: 56), SizedBox(height: 4), HBSkeleton(height: 56), SizedBox(height: 4), HBSkeleton(height: 56)])); }

class CampaignDetailOverlay extends ConsumerWidget {
  final String campaignId;
  final AdAccount account;
  final VoidCallback onClose;
  const CampaignDetailOverlay({super.key, required this.campaignId, required this.account, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Positioned.fill(child: Stack(children: [
    GestureDetector(onTap: onClose, child: const ColoredBox(color: LightModeColors.scrim)),
    Align(alignment: Alignment.centerRight, child: TweenAnimationBuilder<double>(
      duration: AppMotion.of(context).slow,
      tween: Tween(begin: 1, end: 0),
      builder: (_, value, child) => Transform.translate(offset: Offset(value * 420, 0), child: child),
      child: Container(width: MediaQuery.sizeOf(context).width < 600 ? MediaQuery.sizeOf(context).width : 420, height: double.infinity, color: LightModeColors.lightSurface, child: ref.watch(adCampaignAggregateProvider(campaignId)).when(
        loading: () => const AdsManagerTableSkeleton(),
        error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'ads.errors.load_title'.tr(), message: 'ads.errors.load_message'.tr()),
        data: (report) {
          if (report == null) return const SizedBox.shrink();
          return CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.all(AppSpacing.lg), sliver: SliverList.list(children: [
            Row(children: [Expanded(child: Text(report.campaign.name, style: context.textStyles.headlineSmall)), HBButton.icon(icon: Icons.close_rounded, tooltip: 'common.close'.tr(), onPressed: onClose)]),
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [AdsManagerKpi(label: 'ads_p37b.impressions'.tr(), value: '${report.totals.impressions}'), AdsManagerKpi(label: 'ads_p37b.spend'.tr(), value: MoneyFormatter.format(amountMinor: report.totals.spendMinor, currencyCode: account.currencyCode, locale: context.locale))]),
            const SizedBox(height: AppSpacing.md),
            if (report.daily.isNotEmpty) HBCard(child: HbBarChart(points: [for (final item in report.daily) HbBarChartPoint(day: item.day, value: item.impressions)])),
            const SizedBox(height: AppSpacing.md),
            for (final row in report.byPlacement) ListTile(title: Text('ads.placement.${row['placement']}'.tr()), trailing: Text('${row['impressions'] ?? 0}')),
            const SizedBox(height: AppSpacing.md),
            HBButton.primary(label: 'ads_manager.open_full_report'.tr(), onPressed: () => context.go(AppRoutes.adCampaignPath(campaignId))),
          ]))]);
        },
      )),
    )),
  ]));
}

int _setCount(List<AdCampaignAggregateReport>? reports) => reports?.fold<int>(0, (sum, item) => sum + item.adSets.length) ?? 0;
int _adCount(List<AdCampaignAggregateReport>? reports) => reports?.fold<int>(0, (sum, item) => sum + item.adSets.fold<int>(0, (inner, set) => inner + (set['ads'] as List? ?? const []).length)) ?? 0;
int _int(Object? value) => (value as num?)?.toInt() ?? 0;
int _results(AdCampaignObjective objective, Map<String, dynamic>? row) => switch (objective) { AdCampaignObjective.awareness => _int(row?['reach']), AdCampaignObjective.eventPromo || AdCampaignObjective.pageFollowers => _int(row?['conversions']), _ => _int(row?['clicks']) };
String _resultLabel(AdCampaignObjective objective) => 'ads_manager.result.${objective.code}'.tr();
String _percent(int basisPoints) => '${basisPoints ~/ 100},${(basisPoints % 100).toString().padLeft(2, '0')}%';