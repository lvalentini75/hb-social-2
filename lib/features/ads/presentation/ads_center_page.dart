import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/ads/domain/ad_models.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';
import 'package:hb_social/features/ads/presentation/ads_dashboard.dart';
import 'package:hb_social/features/pages/domain/community_page.dart';
import 'package:hb_social/features/pages/providers/page_providers.dart';

class AdsCenterPage extends ConsumerStatefulWidget {
  const AdsCenterPage({super.key});

  @override ConsumerState<AdsCenterPage> createState() => _AdsCenterPageState();
}

class _AdsCenterPageState extends ConsumerState<AdsCenterPage> {
  bool handledCreate = false;

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = MediaQuery.sizeOf(context).width >= 900
        ? await showDialog<({String name, String? pageId})>(context: context, builder: (_) => Dialog(backgroundColor: LightModeColors.lightSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)), elevation: 8, shadowColor: LightModeColors.lightShadow, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 480), child: AdAccountForm())))
        : await showModalBottomSheet<({String name, String? pageId})>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const AdAccountForm());
    if (result == null || !context.mounted) return;
    try {
      final id = await ref.read(adsRepositoryProvider).createAccount(name: result.name, pageId: result.pageId);
      ref.invalidate(adAccountsProvider);
      if (context.mounted) context.go(AppRoutes.adAccountCampaignsPath(id));
    } on AppException catch (error) { if (context.mounted) _error(context, error); }
  }

  @override
  Widget build(BuildContext context) {
    if (!handledCreate && GoRouterState.of(context).uri.queryParameters['create'] == '1') { handledCreate = true; WidgetsBinding.instance.addPostFrameCallback((_) => _create(context, ref)); }
    return CustomScrollView(slivers: [
    SliverPadding(padding: const EdgeInsets.all(AppSpacing.lg), sliver: SliverList.list(children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ads_manager.nav.overview'.tr(), style: context.textStyles.displayMedium), Text('ads.center.subtitle'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant))])), HBButton.primary(label: 'ads_manager.new_account'.tr(), icon: Icons.add_rounded, onPressed: () => _create(context, ref))]),
      const SizedBox(height: AppSpacing.lg),
      ref.watch(adAccountsProvider).when(loading: () => const HBListSkeleton(count: 3), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'ads.errors.load_title'.tr(), message: 'ads.errors.load_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(adAccountsProvider)))), data: (accounts) => accounts.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.campaign_outlined, title: 'ads.account.empty_title'.tr(), message: 'ads.account.empty_message'.tr(), action: HBButton.primary(label: 'ads.account.first'.tr(), onPressed: () => _create(context, ref)))) : Column(children: [const AdsDashboardPanel(), const SizedBox(height: AppSpacing.xl), for (final account in accounts) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: AdAccountCard(account: account))])),
    ])),
  ]);
  }
}

class AdAccountCard extends StatelessWidget {
  final AdAccount account;
  const AdAccountCard({super.key, required this.account});
  @override Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final canManage = account.myRole?.name == 'owner' || account.myRole?.name == 'admin';
    return HBCard(child: InkWell(onTap: () => context.go(AppRoutes.adAccountPath(account.id)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [HBAvatar(size: 44, name: account.pageName ?? account.name, imageUrl: account.pageAvatarUrl), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(account.name, style: context.textStyles.titleMedium?.bold), if (account.pageName != null) Text(account.pageName!, style: context.textStyles.bodySmall)])), HBChip(label: account.myRole?.labelKey.tr() ?? '', selected: false), const SizedBox(width: AppSpacing.xs), HBStatusChip(kind: account.status.name == 'active' ? HBStatusKind.approved : HBStatusKind.rejected, label: account.status.labelKey.tr())]),
      const SizedBox(height: AppSpacing.md),
      Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.sm, children: [Text('ads.account.campaigns_count'.tr(namedArgs: {'active': '${account.activeCampaigns}', 'total': '${account.totalCampaigns}'})), Text('ads.account.lifetime_spend'.tr(namedArgs: {'amount': MoneyFormatter.format(amountMinor: account.lifetimeSpendMinor, currencyCode: account.currencyCode, locale: locale)}))]),
      if (canManage) ...[const Divider(height: 28), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [if (account.cardLast4 != null) Text('${account.cardBrand?.toUpperCase() ?? 'CARD'} •••• ${account.cardLast4}') else HBChip(label: 'ads.billing.no_card'.tr(), selected: false), if (account.billingStatus != 'ok') HBStatusChip(kind: HBStatusKind.rejected, label: 'ads.billing.${account.billingStatus}'.tr()), if (account.promotionalCreditMinor > 0) HBChip(label: 'ads.billing.credit'.tr(namedArgs: {'amount': MoneyFormatter.format(amountMinor: account.promotionalCreditMinor, currencyCode: account.currencyCode, locale: locale)}), selected: false), HBButton.ghost(label: 'ads.tabs.billing'.tr(), onPressed: () => context.go(AppRoutes.adAccountSectionPath(account.id, 'billing')), size: HBButtonSize.sm)])],
    ])));
  }
}

class AdAccountForm extends ConsumerStatefulWidget {
  const AdAccountForm({super.key});
  @override ConsumerState<AdAccountForm> createState() => _AdAccountFormState();
}

class _AdAccountFormState extends ConsumerState<AdAccountForm> {
  final name = TextEditingController();
  String? pageId;
  @override void dispose() { name.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final pages = ref.watch(myPagesProvider).value ?? const <CommunityPage>[];
    final valid = name.text.trim().length >= 2 && name.text.trim().length <= 60;
    return Material(color: Colors.transparent, child: SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('ads.account.create_title'.tr(), style: context.textStyles.titleLarge),
      const SizedBox(height: AppSpacing.xs),
      Text('ads_manager.account.create_help'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
      const SizedBox(height: AppSpacing.lg),
      HBFormField(label: 'ads.fields.name'.tr(), required: true, child: HBInput(controller: name, maxLength: 60, onChanged: (_) => setState(() {}))),
      const SizedBox(height: AppSpacing.md),
      HBFormField(label: 'ads.account.page_optional'.tr(), helper: 'ads_manager.account.page_help'.tr(), child: HBSelect<String>(value: pageId ?? '', options: [HBSelectOption(value: '', label: 'ads.account.no_page'.tr()), for (final page in pages) HBSelectOption(value: page.id, label: page.name)], onChanged: (value) => setState(() => pageId = value?.isEmpty == true ? null : value))),
      const SizedBox(height: AppSpacing.lg),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [HBButton.secondary(label: 'common.cancel'.tr(), onPressed: () => context.pop()), const SizedBox(width: AppSpacing.sm), HBButton.primary(label: 'pd2b.create_action'.tr(), onPressed: valid ? () => context.pop((name: name.text.trim(), pageId: pageId)) : null)]),
    ]))));
  }
}

void _error(BuildContext context, AppException error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));