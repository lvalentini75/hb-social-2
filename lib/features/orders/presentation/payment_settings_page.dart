import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
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
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/orders/domain/order.dart';
import 'package:hb_social/features/orders/providers/order_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentSettingsPage extends ConsumerStatefulWidget {
  final bool returnedFromOnboarding;
  const PaymentSettingsPage({super.key, this.returnedFromOnboarding = false});
  @override ConsumerState<PaymentSettingsPage> createState() => _PaymentSettingsPageState();
}

class _PaymentSettingsPageState extends ConsumerState<PaymentSettingsPage> {
  bool working = false;
  @override void initState() { super.initState(); if (widget.returnedFromOnboarding) Future.microtask(sync); }
  Future<void> sync() async { setState(() => working = true); try { await ref.read(paymentsRepositoryProvider).connectStatus(); ref.invalidate(sellerAccountProvider); ref.invalidate(payoutsSummaryProvider); } on AppException catch (error) { if (mounted) _error(context, error); } finally { if (mounted) setState(() => working = false); } }
  Future<void> onboard() async { setState(() => working = true); try { final base = Uri.base.resolve(AppRoutes.paymentSettings); final uri = await ref.read(paymentsRepositoryProvider).connectOnboard(returnUrl: base.replace(queryParameters: {'onboarding': 'return'}).toString(), refreshUrl: base.replace(queryParameters: {'onboarding': 'refresh'}).toString()); await launchUrl(uri, mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication, webOnlyWindowName: kIsWeb ? '_self' : null); } on AppException catch (error) { if (mounted) _error(context, error); } finally { if (mounted) setState(() => working = false); } }
  Future<void> dashboard() async { try { final uri = await ref.read(paymentsRepositoryProvider).connectLogin(); await launchUrl(uri, mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication); } on AppException catch (error) { if (mounted) _error(context, error); } }
  @override Widget build(BuildContext context) => PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [Text('payments.title'.tr(), style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.lg), ref.watch(sellerAccountProvider).when(loading: () => const HBSkeleton(height: 240), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.account_balance_outlined, title: 'payments.error_title'.tr(), message: 'payments.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: sync))), data: (account) => SellerPaymentsCard(account: account, working: working, onOnboard: onboard, onDashboard: dashboard, onSync: sync)), const SizedBox(height: AppSpacing.md), ref.watch(payoutsSummaryProvider).when(loading: () => const HBSkeleton(height: 120), error: (_, __) => const SizedBox.shrink(), data: (summary) => PayoutsSummaryCard(summary: summary)), const SizedBox(height: AppSpacing.md), HBTile(child: Row(children: [const Icon(Icons.lock_outline), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('payments.legal_note'.tr()))]))]))]));
}

class SellerPaymentsCard extends StatelessWidget {
  final SellerAccountStatus account;
  final bool working;
  final VoidCallback onOnboard;
  final VoidCallback onDashboard;
  final VoidCallback onSync;
  const SellerPaymentsCard({super.key, required this.account, required this.working, required this.onOnboard, required this.onDashboard, required this.onSync});
  @override Widget build(BuildContext context) { final status = account.active ? 'active' : account.exists ? account.onboardingStatus : 'none'; return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.payments_outlined, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('payments.receive_title'.tr(), style: context.textStyles.titleLarge)), if (account.exists) HBStatusChip(kind: account.active ? HBStatusKind.approved : status == 'disabled' ? HBStatusKind.rejected : HBStatusKind.pending, label: (account.active ? 'payments.active' : 'payments.status.$status').tr(namedArgs: {'currency': account.defaultCurrency}))]), const SizedBox(height: AppSpacing.sm), Text('payments.receive_description'.tr()), if (account.requirements.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), Text('payments.requirements'.tr(namedArgs: {'items': account.requirements.map((item) => 'payments.requirement.$item'.tr()).join(', ')}))], const SizedBox(height: AppSpacing.md), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [if (!account.active) HBButton.primary(label: account.exists ? 'payments.continue'.tr() : 'payments.activate'.tr(), isLoading: working, onPressed: working ? null : onOnboard), if (account.detailsSubmitted) HBButton.secondary(label: 'payments.dashboard'.tr(), onPressed: onDashboard), if (account.exists) HBButton.ghost(label: 'common.refresh'.tr(), onPressed: onSync)])])); }
}

class PayoutsSummaryCard extends StatelessWidget {
  final PayoutsSummary summary;
  const PayoutsSummaryCard({super.key, required this.summary});
  @override Widget build(BuildContext context) { if (summary.byCurrency.isEmpty) return const SizedBox.shrink(); return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('payments.payouts_title'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), for (final item in summary.byCurrency) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Text((item.feesMinor > 0 ? 'payments.payout_summary_with_fees' : 'payments.payout_summary').tr(namedArgs: {'net': _money(context, item.netMinor, item.currencyCode), 'pending': _money(context, item.pendingMinor, item.currencyCode), 'fees': _money(context, item.feesMinor, item.currencyCode), 'n': '${item.orders}'}))), HBButton.ghost(label: 'payments.received_orders'.tr(), onPressed: () => context.push('${AppRoutes.orders}?role=seller'))])); }
}

String _money(BuildContext context, int amount, String currency) => MoneyFormatter.format(amountMinor: amount, currencyCode: currency, locale: context.locale);
void _error(BuildContext context, AppException error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));