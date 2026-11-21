import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/domain/ad_models.dart';
import 'package:hb_social/features/ads/presentation/ad_manager_tabs.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';

class AdCampaignWizardPage extends ConsumerStatefulWidget {
  final String accountId;
  final String? campaignId;
  const AdCampaignWizardPage({super.key, required this.accountId, this.campaignId});
  @override ConsumerState<AdCampaignWizardPage> createState() => _AdCampaignWizardPageState();
}

class _AdCampaignWizardPageState extends ConsumerState<AdCampaignWizardPage> {
  int step = 0;
  int reached = 0;
  String? campaignId;
  String? adSetId;
  final name = TextEditingController();
  final totalBudget = TextEditingController(text: '5,00');
  final dailyBudget = TextEditingController();
  final bid = TextEditingController(text: '1,00');
  AdCampaignObjective objective = AdCampaignObjective.awareness;
  String? audienceId;
  Set<AdPlacement> placements = {AdPlacement.feed};
  String bidType = 'cpm';
  int frequency = 3;
  String pacing = 'standard';
  DateTime startAt = DateTime.now();
  DateTime? endAt;
  final selectedCreativeIds = <String>{};
  bool loading = false;
  DateTime? savedAt;
  bool submitted = false;

  @override void initState() { super.initState(); campaignId = widget.campaignId; name.addListener(_refreshValidation); totalBudget.addListener(_refreshValidation); if (campaignId != null) Future.microtask(_load); }
  void _refreshValidation() { if (mounted) setState(() {}); }
  @override void dispose() { name.dispose(); totalBudget.dispose(); dailyBudget.dispose(); bid.dispose(); super.dispose(); }
  Future<void> _load() async { final campaigns = await ref.read(adCampaignsProvider(widget.accountId).future); final campaign = campaigns.where((item) => item.id == campaignId).firstOrNull; if (campaign == null || !mounted) return; setState(() { name.text = campaign.name; objective = campaign.objective; totalBudget.text = _moneyInput(campaign.budgetMinor); dailyBudget.text = campaign.dailyBudgetMinor == null ? '' : _moneyInput(campaign.dailyBudgetMinor!); startAt = campaign.startsAt; endAt = campaign.endsAt; }); final sets = await ref.read(adsRepositoryProvider).adSets(campaign.id); if (sets.items.isNotEmpty && mounted) { final set = sets.items.first; setState(() { adSetId = set.id; audienceId = set.audienceId; placements = set.placements.toSet(); bidType = set.optimization; bid.text = _moneyInput(set.bidMinor); frequency = set.frequencyCap; pacing = set.pacing; reached = 5; step = 5; }); final ads = await ref.read(adsRepositoryProvider).ads(set.id); selectedCreativeIds.addAll(ads.items.where((item) => item.status != 'archived').map((item) => item.creativeId)); } }
  Future<bool> _saveCampaign() async { final total = _minor(totalBudget.text); final daily = dailyBudget.text.trim().isEmpty ? null : _minor(dailyBudget.text); if (name.text.trim().length < 2 || total < 500) { _message('ads.errors.ads_budget_invalid'); return false; } campaignId = await ref.read(adsRepositoryProvider).upsertCampaign(accountId: widget.accountId, id: campaignId, name: name.text.trim(), objective: objective, startsAt: startAt, endsAt: endAt, budgetMinor: total, dailyBudgetMinor: daily); ref.invalidate(adCampaignsProvider(widget.accountId)); if (mounted) setState(() => savedAt = DateTime.now()); return true; }
  Future<void> _next() async { setState(() => loading = true); try { if (step == 0 && !await _saveCampaign()) return; if (step == 2) { if (!await _saveCampaign()) return; adSetId = await ref.read(adsRepositoryProvider).upsertAdSet(campaignId: campaignId!, id: adSetId, name: 'ads.wizard.group_one'.tr(), audienceId: audienceId, placements: placements.toList(), optimization: bidType, bidMinor: _minor(bid.text), dailyBudgetMinor: dailyBudget.text.trim().isEmpty ? null : _minor(dailyBudget.text), frequencyCap: frequency, pacing: pacing, startsAt: startAt, endsAt: endAt); } if (step == 3 && selectedCreativeIds.isEmpty) { _message('ads.wizard.creative_required'); return; } if (step == 4) { for (final creativeId in selectedCreativeIds) { await ref.read(adsRepositoryProvider).upsertAd(adSetId: adSetId!, creativeId: creativeId, name: 'ads.wizard.ad_name'.tr(), status: 'draft'); } } if (mounted) setState(() { reached = reached < step + 1 ? step + 1 : reached; step++; }); } on AppException catch (error) { if (mounted) _message(error.messageKey); } finally { if (mounted) setState(() => loading = false); } }
  Future<void> _submit() async { setState(() => loading = true); try { await ref.read(adsRepositoryProvider).setCampaignStatus(campaignId!, AdCampaignStatus.inReview); ref.invalidate(adCampaignsProvider(widget.accountId)); if (mounted) setState(() => submitted = true); } on AppException catch (error) { if (mounted) _message(error.messageKey); } finally { if (mounted) setState(() => loading = false); } }
  Future<void> _exit() async { final leave = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text('ads.wizard.exit_title'.tr()), content: Text('ads.wizard.exit_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop(false)), HBButton.primary(label: 'common.exit'.tr(), onPressed: () => dialog.pop(true))])) ?? false; if (leave && mounted) context.go(AppRoutes.adAccountPath(widget.accountId)); }

  Future<void> _createAudience() async { final changed = await showModalBottomSheet<bool>(context: context, useSafeArea: true, isScrollControlled: true, builder: (_) => AdAudienceForm(accountId: widget.accountId)); if (changed == true) ref.invalidate(adAudiencesProvider(widget.accountId)); }

  Future<void> _createCreative(AdAccount account) async {
    final existing = (ref.read(adCreativesProvider(widget.accountId)).value ?? const <AdCreative>[]).map((item) => item.id).toSet();
    final preferred = switch (objective) { AdCampaignObjective.listingPromo => AdCreativeKind.listing, AdCampaignObjective.eventPromo => AdCreativeKind.event, AdCampaignObjective.pageFollowers => AdCreativeKind.page, _ => AdCreativeKind.image };
    final changed = await showModalBottomSheet<bool>(context: context, useSafeArea: true, isScrollControlled: true, builder: (_) => AdCreativeForm(account: account, initialKind: preferred));
    if (changed != true) return;
    ref.invalidate(adCreativesProvider(widget.accountId));
    final items = (await ref.read(adsRepositoryProvider).creatives(widget.accountId)).items;
    final created = items.where((item) => !existing.contains(item.id)).firstOrNull;
    if (created != null && mounted) setState(() => selectedCreativeIds.add(created.id));
  }

  bool get _stepValid => switch (step) { 0 => name.text.trim().length >= 2 && _minor(totalBudget.text) >= 500, 2 => placements.isNotEmpty, 3 => selectedCreativeIds.isNotEmpty, _ => true };

  @override
  Widget build(BuildContext context) => PageColumns(
    centerMaxWidth: 1200,
    center: ref.watch(adAccountProvider(widget.accountId)).when(
      loading: () => const CustomScrollView(slivers: [SliverToBoxAdapter(child: HBListSkeleton())]),
      error: (_, __) => CustomScrollView(slivers: [SliverToBoxAdapter(child: HBEmptyState(icon: Icons.lock_outline_rounded, title: 'ads.errors.permission_title'.tr(), message: 'ads.errors.permission_message'.tr()))]),
       data: (account) => submitted ? CampaignSubmitted(accountId: widget.accountId, onAnother: () => setState(() { submitted = false; step = 0; reached = 0; campaignId = null; adSetId = null; selectedCreativeIds.clear(); name.clear(); })) : PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) { if (!didPop) _exit(); },
        child: Column(children: [Expanded(child: CustomScrollView(slivers: [
          SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
              Row(children: [HBButton.icon(icon: Icons.close_rounded, tooltip: 'common.close'.tr(), onPressed: _exit), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('ads.wizard.title'.tr(), style: context.textStyles.headlineSmall))]),
              const SizedBox(height: AppSpacing.md),
              AdWizardProgress(step: step, reached: reached, onChanged: (value) { if (value <= reached) setState(() => step = value); }),
               const SizedBox(height: AppSpacing.sm),
               Text(_summary(account), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
              const SizedBox(height: AppSpacing.lg),
               LayoutBuilder(builder: (context, box) { final desktop = MediaQuery.sizeOf(context).width >= 1024; final form = ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: HBCard(child: _body(account))); final tips = WizardTips(step: step, estimatedReach: _estimatedReach()); return desktop ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: form), const SizedBox(width: AppSpacing.lg), SizedBox(width: 320, child: tips)]) : Column(children: [tips, const SizedBox(height: AppSpacing.md), form]); }),
               if (!_stepValid && step == 3) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text('ads_manager.wizard.creative_required_help'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))),
            ]),
          ),
         ])), WizardNavigation(step: step, loading: loading, valid: _stepValid, savedAt: savedAt, onBack: step > 0 ? () => setState(() => step--) : null, onNext: _next, onSaveDraft: () => context.go(AppRoutes.adAccountCampaignsPath(widget.accountId)), onSubmit: _submit)],
      ),
    ),
    ),
  );

  Widget _body(AdAccount account) => switch (step) { 0 => AdObjectiveStep(name: name, objective: objective, totalBudget: totalBudget, currency: account.currencyCode, onObjective: (value) => setState(() { objective = value; placements = _defaults(value); })), 1 => AdAudienceStep(accountId: account.id, selectedId: audienceId, onSelected: (value) => setState(() => audienceId = value), onCreate: _createAudience), 2 => AdDeliveryStep(placements: placements, bidType: bidType, bid: bid, totalBudget: totalBudget, dailyBudget: dailyBudget, frequency: frequency, pacing: pacing, onPlacement: (value) => setState(() => placements.contains(value) ? placements.remove(value) : placements.add(value)), onBidType: (value) => setState(() => bidType = value), onFrequency: (value) => setState(() => frequency = value), onPacing: (value) => setState(() => pacing = value)), 3 => AdCreativeStep(accountId: account.id, selected: selectedCreativeIds, onToggle: (id) => setState(() => selectedCreativeIds.contains(id) ? selectedCreativeIds.remove(id) : selectedCreativeIds.length < 5 ? selectedCreativeIds.add(id) : null), onCreate: () => _createCreative(account)), 4 => AdItemsStep(accountId: account.id, selected: selectedCreativeIds), _ => AdReviewStep(account: account, objective: objective, audienceId: audienceId, placements: placements, totalBudgetMinor: _minor(totalBudget.text), dailyBudgetMinor: dailyBudget.text.trim().isEmpty ? null : _minor(dailyBudget.text), creativeCount: selectedCreativeIds.length, onEdit: (value) => setState(() => step = value)) };
  int _estimatedReach() { final items = ref.watch(adAudiencesProvider(widget.accountId)).value ?? const <AdAudience>[]; return items.where((item) => item.id == audienceId).firstOrNull?.estimatedReach ?? 0; }
  String _summary(AdAccount account) { final audience = (ref.watch(adAudiencesProvider(widget.accountId)).value ?? const <AdAudience>[]).where((item) => item.id == audienceId).firstOrNull?.name ?? 'ads.wizard.everyone'.tr(); final daily = dailyBudget.text.trim().isEmpty ? null : MoneyFormatter.format(amountMinor: _minor(dailyBudget.text), currencyCode: account.currencyCode, locale: Localizations.localeOf(context)); return '${objective.labelKey.tr()} · ${'ads.wizard.audience'.tr()}: $audience${daily == null ? '' : ' · ${'pd2b.summary_daily'.tr(namedArgs: {'amount': daily})}'}'; }
  void _message(String key) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr())));
}

class AdWizardProgress extends StatelessWidget {
  final int step;
  final int reached;
  final ValueChanged<int> onChanged;
  const AdWizardProgress({super.key, required this.step, required this.reached, required this.onChanged});
  @override Widget build(BuildContext context) => Row(children: [
    for (var index = 0; index < 6; index++)
      Expanded(child: InkWell(onTap: index <= reached ? () => onChanged(index) : null, child: Column(children: [
        CircleAvatar(radius: 15, backgroundColor: index == step ? LightModeColors.lightPrimary : LightModeColors.lightBackgroundSoft, child: Text('${index + 1}', style: TextStyle(color: index == step ? LightModeColors.lightOnPrimary : LightModeColors.lightOnSurfaceVariant))),
        const SizedBox(height: 4),
        Text('ads.wizard.steps.${index + 1}'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall),
      ]))),
  ]);
}
class AdObjectiveStep extends StatelessWidget { final TextEditingController name; final AdCampaignObjective objective; final TextEditingController totalBudget; final String currency; final ValueChanged<AdCampaignObjective> onObjective; const AdObjectiveStep({super.key, required this.name, required this.objective, required this.totalBudget, required this.currency, required this.onObjective}); @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('ads.wizard.objective_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final value in AdCampaignObjective.values) ChoiceChip(label: SizedBox(width: 180, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value.labelKey.tr()), Text('ads.objective_help.${value.code}'.tr(), style: context.textStyles.bodySmall)])), selected: objective == value, onSelected: (_) => onObjective(value))]), const SizedBox(height: AppSpacing.lg), HBFormField(label: 'ads.fields.campaign_name'.tr(), required: true, child: HBInput(controller: name, maxLength: 80)), const SizedBox(height: AppSpacing.md), HBFormField(label: 'ads.fields.total_budget'.tr(namedArgs: {'currency': currency}), required: true, child: HBInput(controller: totalBudget, keyboardType: TextInputType.number))]); }
class AdAudienceStep extends ConsumerWidget { final String accountId; final String? selectedId; final ValueChanged<String?> onSelected; final VoidCallback onCreate; const AdAudienceStep({super.key, required this.accountId, required this.selectedId, required this.onSelected, required this.onCreate}); @override Widget build(BuildContext context, WidgetRef ref) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('ads.wizard.audience_title'.tr(), style: context.textStyles.titleLarge), RadioListTile<String?>(value: null, groupValue: selectedId, title: Text('ads.wizard.everyone'.tr()), onChanged: onSelected), ref.watch(adAudiencesProvider(accountId)).when(loading: () => const HBListSkeleton(), error: (_, __) => const SizedBox.shrink(), data: (items) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final item in items) RadioListTile<String?>(value: item.id, groupValue: selectedId, title: Text(item.name), subtitle: Text('ads.audiences.reach'.tr(namedArgs: {'count': '${item.estimatedReach}'})), onChanged: onSelected), if (items.isEmpty) HBEmptyState(icon: Icons.groups_outlined, title: 'ads.audiences.empty_title'.tr(), message: 'ads.audiences.empty_message'.tr(), action: HBButton.primary(label: 'pd2b.create_first_audience'.tr(), onPressed: onCreate))]))]); }
class AdDeliveryStep extends StatelessWidget { final Set<AdPlacement> placements; final String bidType; final TextEditingController bid; final TextEditingController totalBudget; final TextEditingController dailyBudget; final int frequency; final String pacing; final ValueChanged<AdPlacement> onPlacement; final ValueChanged<String> onBidType; final ValueChanged<int> onFrequency; final ValueChanged<String> onPacing; const AdDeliveryStep({super.key, required this.placements, required this.bidType, required this.bid, required this.totalBudget, required this.dailyBudget, required this.frequency, required this.pacing, required this.onPlacement, required this.onBidType, required this.onFrequency, required this.onPacing}); @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('ads.wizard.delivery_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), Wrap(spacing: AppSpacing.xs, children: [for (final value in AdPlacement.values) FilterChip(label: Text(value.labelKey.tr()), selected: placements.contains(value), onSelected: (_) => onPlacement(value))]), const SizedBox(height: AppSpacing.md), HBChoice(options: const ['cpm', 'cpc'], value: bidType, onChanged: onBidType, labelBuilder: (value) => 'ads.bid.$value'.tr(), descriptions: {'cpm': 'ads.bid.cpm_help'.tr(), 'cpc': 'ads.bid.cpc_help'.tr()}), const SizedBox(height: AppSpacing.md), HBInput(controller: bid, label: 'ads.fields.bid'.tr(), keyboardType: TextInputType.number), const SizedBox(height: AppSpacing.md), HBInput(controller: totalBudget, label: 'ads.fields.total_budget_short'.tr(), keyboardType: TextInputType.number), const SizedBox(height: AppSpacing.md), HBInput(controller: dailyBudget, label: 'ads.fields.daily_budget'.tr(), keyboardType: TextInputType.number), const SizedBox(height: AppSpacing.md), HBSelect(value: frequency, items: [for (var value = 1; value <= 20; value++) HBSelectItem(value: value, label: '$value')], onChanged: (value) => onFrequency(value!)), const SizedBox(height: AppSpacing.md), HBChoice(options: const ['standard', 'accelerated'], value: pacing, onChanged: onPacing, labelBuilder: (value) => 'ads.pacing.$value'.tr())]); }
class AdCreativeStep extends ConsumerWidget { final String accountId; final Set<String> selected; final ValueChanged<String> onToggle; final VoidCallback onCreate; const AdCreativeStep({super.key, required this.accountId, required this.selected, required this.onToggle, required this.onCreate}); @override Widget build(BuildContext context, WidgetRef ref) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Expanded(child: Text('ads.wizard.creative_title'.tr(), style: context.textStyles.titleLarge)), HBButton.secondary(label: 'ads_manager.wizard.new_creative'.tr(), icon: Icons.add_rounded, onPressed: onCreate)]), const SizedBox(height: AppSpacing.md), ref.watch(adCreativesProvider(accountId)).when(loading: () => const HBListSkeleton(), error: (_, __) => const SizedBox.shrink(), data: (items) => items.isEmpty ? HBEmptyState(icon: Icons.image_outlined, title: 'ads_manager.wizard.first_creative_title'.tr(), message: 'ads_manager.wizard.first_creative_message'.tr(), action: HBButton.primary(label: 'ads_manager.wizard.create_first_creative'.tr(), onPressed: onCreate)) : GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: .8, mainAxisSpacing: AppSpacing.sm, crossAxisSpacing: AppSpacing.sm, children: [for (final item in items) Stack(children: [Positioned.fill(child: AdCreativeCard(creative: item, onTap: () => onToggle(item.id), selected: selected.contains(item.id))), if (selected.contains(item.id)) const Positioned(top: 8, right: 8, child: Icon(Icons.check_circle, color: LightModeColors.lightPrimary))])]))]); }
class AdItemsStep extends ConsumerWidget { final String accountId; final Set<String> selected; const AdItemsStep({super.key, required this.accountId, required this.selected}); @override Widget build(BuildContext context, WidgetRef ref) { final creatives = ref.watch(adCreativesProvider(accountId)).value ?? const <AdCreative>[]; return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('ads.wizard.ads_title'.tr(), style: context.textStyles.titleLarge), Text('ads.wizard.ads_help'.tr()), const SizedBox(height: AppSpacing.md), for (final item in creatives.where((item) => selected.contains(item.id))) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: HBCard(child: Row(children: [Expanded(child: Text(item.headline.isEmpty ? item.kind.labelKey.tr() : item.headline)), HBStatusChip(kind: HBStatusKind.neutral, label: 'ads.campaign_status.draft'.tr())]))) ]); } }
class AdReviewStep extends StatelessWidget { final AdAccount account; final AdCampaignObjective objective; final String? audienceId; final Set<AdPlacement> placements; final int totalBudgetMinor; final int? dailyBudgetMinor; final int creativeCount; final ValueChanged<int> onEdit; const AdReviewStep({super.key, required this.account, required this.objective, required this.audienceId, required this.placements, required this.totalBudgetMinor, this.dailyBudgetMinor, required this.creativeCount, required this.onEdit}); @override Widget build(BuildContext context) { final locale = Localizations.localeOf(context); final requiredCredit = dailyBudgetMinor ?? 500; final canPay = account.cardLast4 != null || account.promotionalCreditMinor >= (requiredCredit > 500 ? requiredCredit : 500); return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('ads.wizard.review_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), ReviewSection(label: 'pd2b.review_objective_budget'.tr(), value: '${objective.labelKey.tr()} · ${MoneyFormatter.format(amountMinor: totalBudgetMinor, currencyCode: account.currencyCode, locale: locale)}', onEdit: () => onEdit(0)), ReviewSection(label: 'ads.wizard.audience'.tr(), value: audienceId == null ? 'ads.wizard.everyone'.tr() : 'ads.wizard.saved_audience'.tr(), onEdit: () => onEdit(1)), ReviewSection(label: 'ads.wizard.delivery_title'.tr(), value: placements.map((item) => item.labelKey.tr()).join(', '), onEdit: () => onEdit(2)), ReviewSection(label: 'ads.wizard.creative_title'.tr(), value: '$creativeCount', onEdit: () => onEdit(3)), ReviewSection(label: 'ads.wizard.ads'.tr(), value: '$creativeCount', onEdit: () => onEdit(4)), const Divider(height: 32), Text('ads.wizard.payment_title'.tr(), style: context.textStyles.titleMedium), if (account.cardLast4 != null) Text('${account.cardBrand?.toUpperCase()} •••• ${account.cardLast4}'), if (account.promotionalCreditMinor > 0) Text('ads.billing.credit_available'.tr(namedArgs: {'amount': MoneyFormatter.format(amountMinor: account.promotionalCreditMinor, currencyCode: account.currencyCode, locale: locale)})), if (!canPay) HBCard(child: Text(account.myRole == AdAccountRole.owner ? 'ads.wizard.connect_card'.tr() : 'ads.wizard.owner_connect_card'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightWarning))), if (account.billingStatus != 'ok') HBCard(child: Text('ads.wizard.billing_failed'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightError))), const SizedBox(height: AppSpacing.md), Text('ads.wizard.review_timing'.tr())]); } }
class ReviewSection extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;
  const ReviewSection({super.key, required this.label, required this.value, required this.onEdit});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: context.textStyles.labelMedium), Text(value, maxLines: 2, overflow: TextOverflow.ellipsis)])), HBButton.ghost(label: 'common.edit'.tr(), size: HBButtonSize.sm, onPressed: onEdit)]));
}

class WizardTips extends StatelessWidget {
  final int step;
  final int estimatedReach;
  const WizardTips({super.key, required this.step, required this.estimatedReach});
  @override Widget build(BuildContext context) {
    final content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 36, height: 36, decoration: const BoxDecoration(color: LightModeColors.lightPrimaryContainer, shape: BoxShape.circle), child: const Icon(Icons.lightbulb_outline_rounded, color: LightModeColors.lightPrimary)), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('ads_manager.wizard.tips.title'.tr(), style: context.textStyles.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w600)))]),
      if (step == 1) ...[const SizedBox(height: AppSpacing.md), Text('$estimatedReach', style: context.textStyles.displayLarge?.copyWith(fontSize: 26, fontWeight: FontWeight.w700)), Text('ads_manager.wizard.tips.estimated_reach'.tr(), style: context.textStyles.bodySmall)],
      const SizedBox(height: AppSpacing.md),
      for (var index = 1; index <= _tipCount(step); index++) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Text('ads_manager.wizard.tips.${step + 1}.$index'.tr(), style: context.textStyles.bodyMedium)),
    ]);
    if (MediaQuery.sizeOf(context).width < 1024) return HBCard(compact: true, child: ExpansionTile(tilePadding: EdgeInsets.zero, childrenPadding: const EdgeInsets.only(top: AppSpacing.sm), leading: const Icon(Icons.lightbulb_outline_rounded, color: LightModeColors.lightPrimary), title: Text('ads_manager.wizard.tips.title'.tr()), children: [content]));
    return HBCard(child: content);
  }
}

class WizardNavigation extends StatelessWidget {
  final int step;
  final bool loading;
  final bool valid;
  final DateTime? savedAt;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmit;
  const WizardNavigation({super.key, required this.step, required this.loading, required this.valid, required this.savedAt, this.onBack, required this.onNext, required this.onSaveDraft, required this.onSubmit});
  @override Widget build(BuildContext context) => Material(color: LightModeColors.lightSurface, child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, MediaQuery.sizeOf(context).width < 900 ? AppSpacing.md : AppSpacing.sm), child: Row(children: [
    if (onBack != null) HBButton.secondary(label: 'common.back'.tr(), onPressed: loading ? null : onBack),
    if (savedAt != null) ...[const SizedBox(width: AppSpacing.sm), Flexible(child: Text('ads_manager.wizard.saved_at'.tr(namedArgs: {'time': DateFormat.Hm(context.locale.toString()).format(savedAt!)}), overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)))],
    const Spacer(),
    if (step == 5) ...[HBButton.ghost(label: 'ads.wizard.save_draft'.tr(), onPressed: loading ? null : onSaveDraft), const SizedBox(width: AppSpacing.sm), HBButton.primary(label: 'ads.wizard.submit'.tr(), isLoading: loading, onPressed: loading ? null : onSubmit)] else HBButton.primary(label: 'common.next'.tr(), isLoading: loading, onPressed: loading || !valid ? null : onNext),
  ])));
}

class CampaignSubmitted extends StatelessWidget {
  final String accountId;
  final VoidCallback onAnother;
  const CampaignSubmitted({super.key, required this.accountId, required this.onAnother});
  @override Widget build(BuildContext context) => CustomScrollView(slivers: [SliverFillRemaining(hasScrollBody: false, child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: HBCard(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 64, height: 64, decoration: const BoxDecoration(color: LightModeColors.lightPrimaryContainer, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 34, color: LightModeColors.lightPrimary)),
    const SizedBox(height: AppSpacing.lg), Text('pd2b.confirmation_title'.tr(), textAlign: TextAlign.center, style: context.textStyles.headlineMedium),
    const SizedBox(height: AppSpacing.sm), Text('pd2b.confirmation_message'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
    const SizedBox(height: AppSpacing.lg), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, alignment: WrapAlignment.center, children: [HBButton.secondary(label: 'pd2b.go_campaigns'.tr(), onPressed: () => context.go(AppRoutes.adAccountCampaignsPath(accountId))), HBButton.primary(label: 'pd2b.create_another'.tr(), onPressed: onAnother)]),
  ])))))]);
}

int _tipCount(int step) => switch (step) { 0 => 3, 1 => 2, 2 => 3, 3 => 3, 4 => 1, _ => 2 };

Set<AdPlacement> _defaults(AdCampaignObjective value) => switch (value) { AdCampaignObjective.listingPromo => {AdPlacement.marketplace, AdPlacement.feed}, AdCampaignObjective.eventPromo => {AdPlacement.events, AdPlacement.feed}, AdCampaignObjective.pageFollowers => {AdPlacement.feed, AdPlacement.rightRail}, _ => {AdPlacement.feed} };
int _minor(String value) { final clean = value.trim().replaceAll(' ', '').replaceAll(',', '.'); final parts = clean.split('.'); final whole = int.tryParse(parts.first) ?? 0; final fraction = parts.length > 1 ? int.tryParse(parts[1].padRight(2, '0').substring(0, 2)) ?? 0 : 0; return whole * 100 + fraction; }
String _moneyInput(int minor) => '${minor ~/ 100},${(minor % 100).toString().padLeft(2, '0')}';