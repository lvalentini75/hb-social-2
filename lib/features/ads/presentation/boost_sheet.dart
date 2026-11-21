import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/ads/domain/boost_models.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';

Future<void> showBoostSheet(BuildContext context, {required String targetType, required String targetId}) async {
  final content = BoostSheet(targetType: targetType, targetId: targetId);
  if (MediaQuery.sizeOf(context).width >= 700) {
    await showDialog<void>(context: context, builder: (_) => Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760), child: content)));
  } else {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: (_) => FractionallySizedBox(heightFactor: .92, child: content));
  }
}

class BoostSheet extends ConsumerStatefulWidget {
  final String targetType;
  final String targetId;
  const BoostSheet({super.key, required this.targetType, required this.targetId});
  @override ConsumerState<BoostSheet> createState() => _BoostSheetState();
}

class _BoostSheetState extends ConsumerState<BoostSheet> {
  int budget = 1000;
  int days = 7;
  String audience = 'auto';
  Timer? debounce;
  BoostQuoteRequest? request;
  BoostResult? result;
  bool creating = false;
  late final TextEditingController custom = TextEditingController();

  @override void initState() { super.initState(); request = BoostQuoteRequest(targetType: widget.targetType, targetId: widget.targetId, budgetMinor: budget, days: days, audience: audience); }
  @override void dispose() { debounce?.cancel(); custom.dispose(); super.dispose(); }

  void update({int? nextBudget, int? nextDays, String? nextAudience}) {
    if (nextBudget != null) budget = nextBudget;
    if (nextDays != null) days = nextDays;
    if (nextAudience != null) audience = nextAudience;
    debounce?.cancel();
    setState(() {});
    debounce = Timer(const Duration(milliseconds: 300), () { if (mounted) setState(() => request = BoostQuoteRequest(targetType: widget.targetType, targetId: widget.targetId, budgetMinor: budget, days: days, audience: audience)); });
  }

  Future<void> create(BoostQuote quote) async {
    setState(() => creating = true);
    try {
      final value = await ref.read(adsRepositoryProvider).createBoost(targetType: widget.targetType, targetId: widget.targetId, budgetMinor: budget, days: days, audience: audience);
      ref.invalidate(boostStatusProvider(BoostTargetRequest(widget.targetType, widget.targetId)));
      ref.invalidate(myBoostsProvider);
      ref.invalidate(adAccountsProvider);
      if (mounted) setState(() => result = value);
    } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
    finally { if (mounted) setState(() => creating = false); }
  }

  @override Widget build(BuildContext context) {
    if (result != null) return BoostConfirmation(targetType: widget.targetType, result: result!);
    final quote = ref.watch(boostQuoteProvider(request!));
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.sm), child: Row(children: [Expanded(child: Text('boost.title'.tr(), style: context.textStyles.titleLarge)), HBButton.icon(icon: Icons.close_rounded, onPressed: () => context.pop())])),
      const Divider(height: 1),
      Expanded(child: quote.when(
        loading: () => const BoostSheetSkeleton(),
        error: (_, __) => HBCard(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('boost.quote_error'.tr()), const SizedBox(height: AppSpacing.md), HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(boostQuoteProvider(request!)))])),
        data: (value) => value.eligible ? BoostEligibleForm(quote: value, budget: budget, days: days, audience: audience, custom: custom, creating: creating, onBudget: (value) { custom.clear(); update(nextBudget: value); }, onDays: (value) => update(nextDays: value), onAudience: (value) => update(nextAudience: value), onCustom: (value) { final parsed = int.tryParse(value); if (parsed != null) update(nextBudget: parsed); }, onCreate: () => create(value)) : BoostIneligible(reason: value.reason),
      )),
    ]);
  }
}

class BoostEligibleForm extends ConsumerWidget {
  final BoostQuote quote;
  final int budget;
  final int days;
  final String audience;
  final TextEditingController custom;
  final bool creating;
  final ValueChanged<int> onBudget;
  final ValueChanged<int> onDays;
  final ValueChanged<String> onAudience;
  final ValueChanged<String> onCustom;
  final VoidCallback onCreate;
  const BoostEligibleForm({super.key, required this.quote, required this.budget, required this.days, required this.audience, required this.custom, required this.creating, required this.onBudget, required this.onDays, required this.onAudience, required this.onCustom, required this.onCreate});
  String money(BuildContext context, int value) => MoneyFormatter.format(amountMinor: value, currencyCode: quote.currencyCode, locale: context.locale);

  @override Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final country = 'zone.country_${(profile?.countryCode ?? 'IT').toLowerCase()}'.tr();
    final invalidBudget = budget < quote.minBudgetMinor || budget > quote.maxBudgetMinor;
    return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
      BoostPreview(target: quote.target),
      const SizedBox(height: AppSpacing.lg), Text('boost.budget'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm),
      Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final value in quote.presets) HBChip(label: money(context, value), selected: budget == value, onTap: () => onBudget(value))]),
      const SizedBox(height: AppSpacing.sm), HBInput(controller: custom, label: 'boost.other_amount'.tr(), hint: 'boost.min_max'.tr(namedArgs: {'min': money(context, quote.minBudgetMinor), 'max': money(context, quote.maxBudgetMinor)}), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], errorText: invalidBudget ? 'boost.invalid_budget'.tr() : null, onChanged: onCustom),
      const SizedBox(height: AppSpacing.lg), Text('boost.duration'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final value in quote.durationsDays) HBChip(label: 'boost.days'.plural(value), selected: days == value, onTap: () => onDays(value))]),
      const SizedBox(height: AppSpacing.lg), Text('boost.audience'.tr(), style: context.textStyles.titleMedium), RadioListTile<String>(value: 'auto', groupValue: audience, onChanged: (value) => onAudience(value!), title: Text('boost.audience_auto'.tr(namedArgs: {'area': country}))), RadioListTile<String>(value: 'all', groupValue: audience, onChanged: (value) => onAudience(value!), title: Text('boost.audience_all'.tr())),
      const SizedBox(height: AppSpacing.md), AnimatedSwitcher(duration: AppMotion.of(context).fast, child: BoostEstimate(key: ValueKey('${quote.estimatedImpressions}-${quote.estimatedReach}'), quote: quote)),
      const SizedBox(height: AppSpacing.md), BoostPaymentCard(quote: quote),
      const SizedBox(height: AppSpacing.md), Text('boost.legal'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.textSecondary)),
      const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: HBButton.secondary(label: 'common.cancel'.tr(), onPressed: () => context.pop())), const SizedBox(width: AppSpacing.sm), Expanded(child: HBButton.primary(label: 'boost.promote_for'.tr(namedArgs: {'amount': money(context, budget)}), isLoading: creating, onPressed: !quote.paymentReady || invalidBudget || creating ? null : onCreate))]),
    ]);
  }
}

class BoostPreview extends StatelessWidget {
  final BoostTargetPreview? target;
  const BoostPreview({super.key, required this.target});
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('boost.preview_label'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.textSecondary)), const SizedBox(height: AppSpacing.sm), Row(children: [ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: SizedBox(width: 56, height: 56, child: target?.imagePath?.isNotEmpty == true ? Image.network(target!.imagePath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.campaign_outlined))) : const ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.campaign_outlined)))), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(target?.title ?? 'boost.title'.tr(), maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall), if (target?.subtitle?.isNotEmpty == true) Text(target!.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis)]))])]);
}

class BoostEstimate extends StatelessWidget {
  final BoostQuote quote;
  const BoostEstimate({super.key, required this.quote});
  @override Widget build(BuildContext context) => HBCard(color: LightModeColors.boscoSoft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('boost.estimate'.tr(namedArgs: {'impressions': NumberFormat.decimalPattern(context.locale.toLanguageTag()).format(quote.estimatedImpressions), 'reach': NumberFormat.decimalPattern(context.locale.toLanguageTag()).format(quote.estimatedReach)}), style: AppText.kpi.withColor(LightModeColors.text)), const SizedBox(height: 4), Text('boost.estimate_detail'.tr(namedArgs: {'daily': MoneyFormatter.format(amountMinor: quote.dailyBudgetMinor, currencyCode: quote.currencyCode, locale: context.locale), 'cpm': MoneyFormatter.format(amountMinor: quote.cpmMinor, currencyCode: quote.currencyCode, locale: context.locale)}), style: AppText.caption.withColor(LightModeColors.textSecondary))]));
}

class BoostPaymentCard extends StatelessWidget {
  final BoostQuote quote;
  const BoostPaymentCard({super.key, required this.quote});
  @override Widget build(BuildContext context) {
    final card = quote.paymentMethod;
    final money = (int value) => MoneyFormatter.format(amountMinor: value, currencyCode: quote.currencyCode, locale: context.locale);
    if (!quote.paymentReady) return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('boost.card_required'.tr()), const SizedBox(height: AppSpacing.sm), HBButton.secondary(label: 'boost.add_card'.tr(), onPressed: () => context.push(AppRoutes.billing))]));
    return HBCard(color: LightModeColors.surfaceSoft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('boost.payment_title'.tr(), style: context.textStyles.titleSmall), if (card != null) Text('${card.brand} •••• ${card.last4}') else Text('boost.credit'.tr(namedArgs: {'credit': money(quote.creditBalanceMinor)})), if (card != null) Text('boost.pay_later'.tr(namedArgs: {'threshold': money(quote.thresholdMinor)}), style: context.textStyles.bodySmall), HBButton.ghost(label: 'boost.change'.tr(), onPressed: () => context.push(AppRoutes.billing))]));
  }
}

class BoostIneligible extends StatelessWidget {
  final String? reason;
  const BoostIneligible({super.key, this.reason});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: HBCard(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.info_outline_rounded, size: 40), const SizedBox(height: AppSpacing.md), Text('boost.reason.${reason ?? 'boost_target_invalid'}'.tr(), textAlign: TextAlign.center), const SizedBox(height: AppSpacing.md), HBButton.primary(label: 'albums_p23b.close'.tr(), onPressed: () => context.pop())])));
}

class BoostConfirmation extends StatelessWidget {
  final String targetType;
  final BoostResult result;
  const BoostConfirmation({super.key, required this.targetType, required this.result});
  @override Widget build(BuildContext context) { final review = result.status == 'in_review'; return Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 72, height: 72, decoration: const BoxDecoration(color: LightModeColors.boscoSoft, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 40, color: LightModeColors.bosco)), const SizedBox(height: AppSpacing.lg), Text((review ? 'boost.confirm_review' : 'boost.confirm_active').tr(namedArgs: {'type': 'boost.type.$targetType'.tr()}), style: context.textStyles.titleLarge, textAlign: TextAlign.center), const SizedBox(height: AppSpacing.sm), Text(review ? 'boost.review_help'.tr() : 'boost.until'.tr(namedArgs: {'date': DateFormat.yMMMd(context.locale.toLanguageTag()).format(result.endsAt.toLocal())}), textAlign: TextAlign.center), const SizedBox(height: AppSpacing.sm), Text('boost.manage_help'.tr(), textAlign: TextAlign.center), const SizedBox(height: AppSpacing.lg), HBButton.primary(label: 'boost.view_promotions'.tr(), onPressed: () => context.go(AppRoutes.boosts)), const SizedBox(height: AppSpacing.sm), HBButton.ghost(label: 'albums_p23b.done'.tr(), onPressed: () => context.pop())])); }
}

class BoostSheetSkeleton extends StatelessWidget {
  const BoostSheetSkeleton({super.key});
  @override Widget build(BuildContext context) => const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Column(children: [HBSkeleton(height: 72), SizedBox(height: AppSpacing.md), HBSkeleton(height: 120), SizedBox(height: AppSpacing.md), HBSkeleton(height: 88)]));
}

class BoostStatusControl extends ConsumerWidget {
  final String targetType;
  final String targetId;
  const BoostStatusControl({super.key, required this.targetType, required this.targetId});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final request = BoostTargetRequest(targetType, targetId);
    final status = ref.watch(boostStatusProvider(request)).value;
    if (status == null) return const SizedBox.shrink();
    return InkWell(onTap: () => showModalBottomSheet<void>(context: context, useSafeArea: true, showDragHandle: true, builder: (_) => BoostStatusPanel(status: status, request: request)), child: HBStatusChip(kind: _statusKind(status.status), label: 'boost.status.${status.status}'.tr()));
  }
}

class BoostStatusPanel extends ConsumerWidget {
  final BoostStatus status;
  final BoostTargetRequest request;
  const BoostStatusPanel({super.key, required this.status, required this.request});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final progress = status.totalBudgetMinor == 0 ? 0.0 : (status.spentMinor / status.totalBudgetMinor).clamp(0.0, 1.0);
    final money = (int value) => MoneyFormatter.format(amountMinor: value, currencyCode: status.currencyCode, locale: context.locale);
    return Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('boost.status_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), Text('boost.metrics'.tr(namedArgs: {'impressions': '${status.impressions}', 'clicks': '${status.clicks}', 'conversions': '${status.conversions}'})), const SizedBox(height: AppSpacing.sm), Text('boost.spent_of'.tr(namedArgs: {'spent': money(status.spentMinor), 'total': money(status.totalBudgetMinor)})), const SizedBox(height: AppSpacing.xs), LinearProgressIndicator(value: progress, minHeight: 6, borderRadius: BorderRadius.circular(AppRadius.pill)), if (status.endsAt != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text('boost.until'.tr(namedArgs: {'date': DateFormat.yMMMd(context.locale.toLanguageTag()).format(status.endsAt!.toLocal())}))), const SizedBox(height: AppSpacing.md), Row(children: [if (const {'active', 'in_review', 'scheduled', 'paused'}.contains(status.status)) Expanded(child: HBButton.secondary(label: 'boost.stop'.tr(), onPressed: () async { try { await ref.read(adsRepositoryProvider).stopBoost(status.campaignId); ref.invalidate(boostStatusProvider(request)); ref.invalidate(myBoostsProvider); if (context.mounted) context.pop(); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } })), const SizedBox(width: AppSpacing.sm), Expanded(child: HBButton.primary(label: 'boost.manage'.tr(), onPressed: () => context.go(AppRoutes.boosts)))]) ]));
  }
}

HBStatusKind _statusKind(String status) => switch (status) { 'active' => HBStatusKind.approved, 'in_review' || 'scheduled' => HBStatusKind.pending, 'paused' => HBStatusKind.info, 'rejected' => HBStatusKind.rejected, _ => HBStatusKind.neutral };