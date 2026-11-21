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
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/domain/ad_models.dart';
import 'package:hb_social/features/ads/presentation/ad_account_billing.dart';
import 'package:hb_social/features/ads/presentation/ad_account_report.dart';
import 'package:hb_social/features/ads/presentation/ad_campaigns_manager.dart';
import 'package:hb_social/features/ads/presentation/ad_manager_tabs.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';

class AdAccountPage extends ConsumerWidget {
  final String accountId;
  final String initialSection;
  const AdAccountPage({super.key, required this.accountId, this.initialSection = 'campaigns'});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(adAccountProvider(accountId)).when(
    loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: HBListSkeleton()),
    error: (_, __) => Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: HBCard(child: HBEmptyState(icon: Icons.lock_outline_rounded, title: 'ads.errors.permission_title'.tr(), message: 'ads.errors.permission_message'.tr()))),
    data: (account) {
      final readOnly = account.status == AdAccountStatus.closed;
      if (initialSection == 'campaigns') return AdCampaignsManager(account: account);
      final content = switch (initialSection) {
        'audiences' => AdAudiencesTab(account: account, readOnly: readOnly),
        'creatives' => AdCreativesTab(account: account, readOnly: readOnly),
        'billing' => AdAccountBillingTab(account: account),
        'report' => AdAccountReportTab(accountId: account.id),
        'settings' => AdAccountSettings(account: account, readOnly: readOnly),
        _ => AdCampaignsManager(account: account),
      };
      return CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.all(AppSpacing.lg), sliver: SliverList.list(children: [Text('ads_manager.nav.$initialSection'.tr(), style: context.textStyles.displayMedium), const SizedBox(height: AppSpacing.lg), content]))]);
    },
  );
}

class AdAccountSettings extends ConsumerWidget {
  final AdAccount account;
  final bool readOnly;
  const AdAccountSettings({super.key, required this.account, required this.readOnly});

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text('ads.account.close_title'.tr()), content: Text('ads.account.close_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop(false)), HBButton.primary(label: 'ads.account.close'.tr(), onPressed: () => dialog.pop(true))])) ?? false;
    if (!confirmed || !context.mounted) return;
    try { await ref.read(adsRepositoryProvider).updateAccount(accountId: account.id, status: AdAccountStatus.closed); ref.invalidate(adAccountsProvider); if (context.mounted) context.go(AppRoutes.ads); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs)))); }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = account.myRole == AdAccountRole.owner || account.myRole == AdAccountRole.admin;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ads_manager.settings.identity'.tr(), style: context.textStyles.titleLarge), ListTile(contentPadding: EdgeInsets.zero, title: Text('ads.fields.name'.tr()), subtitle: Text(account.name)), ListTile(contentPadding: EdgeInsets.zero, title: Text('ads_manager.settings.page'.tr()), subtitle: Text(account.pageName ?? 'ads.account.no_page'.tr())), ListTile(contentPadding: EdgeInsets.zero, title: Text('ads_p37b.spend_cap'.tr()), subtitle: Text(account.spendCapMinor == null ? 'ads_p37b.no_limit'.tr() : MoneyFormatter.format(amountMinor: account.spendCapMinor!, currencyCode: account.currencyCode, locale: context.locale)))])),
      const SizedBox(height: AppSpacing.md), AdMembersTab(account: account, readOnly: readOnly),
      if (manager && account.myRole == AdAccountRole.owner && !readOnly) ...[const SizedBox(height: AppSpacing.md), HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ads_manager.settings.danger'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), HBButton.secondary(label: 'ads.account.close'.tr(), onPressed: () => _close(context, ref))]))],
    ]);
  }
}