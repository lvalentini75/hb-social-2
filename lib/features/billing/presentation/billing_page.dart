import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/config/app_config.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/billing/domain/payment_method.dart';
import 'package:hb_social/features/billing/providers/billing_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class BillingPage extends ConsumerStatefulWidget {
  final String? setupResult;
  const BillingPage({super.key, this.setupResult});
  @override ConsumerState<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends ConsumerState<BillingPage> {
  bool working = false;

  @override void initState() {
    super.initState();
    if (widget.setupResult == 'success') Future.microtask(_syncAfterReturn);
    if (widget.setupResult == 'cancel') Future.microtask(() => _message('billing.setup_cancelled'));
  }

  Future<void> _syncAfterReturn() async {
    setState(() => working = true);
    try {
      await ref.read(billingRepositoryProvider).syncCards();
      ref.invalidate(paymentMethodsProvider);
      if (mounted) _message('billing.card_saved');
    } on AppException catch (error) { if (mounted) _error(error); } finally { if (mounted) setState(() => working = false); }
  }

  Future<void> _addCard() async {
    setState(() => working = true);
    try {
      final returnUrl = Uri.base.resolve(AppRoutes.billing).replace(queryParameters: {'setup': 'success'}).toString();
      final uri = await ref.read(billingRepositoryProvider).setupCard(returnUrl);
      await launchUrl(uri, mode: LaunchMode.platformDefault, webOnlyWindowName: '_self');
    } on AppException catch (error) { if (mounted) _error(error); } finally { if (mounted) setState(() => working = false); }
  }

  Future<void> _setDefault(String id) async {
    try { await ref.read(billingRepositoryProvider).setDefault(id); ref.invalidate(paymentMethodsProvider); } on AppException catch (error) { if (mounted) _error(error); }
  }

  Future<void> _remove(BillingPaymentMethod method) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text('billing.remove_title'.tr()), content: Text('billing.remove_message'.tr(namedArgs: {'last4': method.last4})), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop(false)), HBButton.primary(label: 'common.remove'.tr(), onPressed: () => dialog.pop(true))])) ?? false;
    if (!confirmed || !mounted) return;
    try { await ref.read(billingRepositoryProvider).remove(method.id); ref.invalidate(paymentMethodsProvider); } on AppException catch (error) { if (mounted) _error(error); }
  }

  @override Widget build(BuildContext context) => PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [Text('billing.title'.tr(), style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.xs), Text('billing.description'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)), const SizedBox(height: AppSpacing.sm), HBTile(child: Text('billing.free_note'.tr())), const SizedBox(height: AppSpacing.lg), Text('billing.cards'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.sm), ref.watch(paymentMethodsProvider).when(loading: () => const HBListSkeleton(), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.credit_card_off_outlined, title: 'billing.load_error_title'.tr(), message: 'billing.load_error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(paymentMethodsProvider)))), data: (methods) => BillingCardsList(methods: methods, onSetDefault: _setDefault, onRemove: _remove)), const SizedBox(height: AppSpacing.md), if (kIsWeb) SizedBox(width: double.infinity, child: HBButton.primary(label: 'billing.add_card'.tr(), icon: Icons.add_card_rounded, isLoading: working, onPressed: working ? null : _addCard)) else BillingMobileCard(onOpen: () => launchUrl(Uri.parse('${AppConfig.appUrl}${AppRoutes.billing}'), mode: LaunchMode.externalApplication)), const SizedBox(height: AppSpacing.xl), Text('billing.charges'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.sm), HBCard(child: HBEmptyState(icon: Icons.receipt_long_outlined, title: 'billing.charges_empty'.tr(), message: 'billing.charges_empty_message'.tr(), action: HBButton.secondary(label: 'ads.center.title'.tr(), onPressed: () => context.go(AppRoutes.ads)))), const SizedBox(height: AppSpacing.md), HBTile(child: Row(children: [const Icon(Icons.lock_outline_rounded), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('billing.legal_note'.tr()))])), const SizedBox(height: AppSpacing.xl)]))]));

  void _message(String key) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr())));
  void _error(AppException error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
}

class BillingCardsList extends StatelessWidget {
  final List<BillingPaymentMethod> methods;
  final ValueChanged<String> onSetDefault;
  final ValueChanged<BillingPaymentMethod> onRemove;
  const BillingCardsList({super.key, required this.methods, required this.onSetDefault, required this.onRemove});
  @override Widget build(BuildContext context) {
    if (methods.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.credit_card_outlined, title: 'billing.empty_title'.tr(), message: 'billing.empty_message'.tr()));
    return HBCard(child: Column(children: [for (var index = 0; index < methods.length; index++) ...[BillingCardRow(method: methods[index], onSetDefault: onSetDefault, onRemove: onRemove), if (index < methods.length - 1) const Divider(height: 1)]]));
  }
}

class BillingCardRow extends StatelessWidget {
  final BillingPaymentMethod method;
  final ValueChanged<String> onSetDefault;
  final ValueChanged<BillingPaymentMethod> onRemove;
  const BillingCardRow({super.key, required this.method, required this.onSetDefault, required this.onRemove});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Row(children: [Icon(_brandIcon(method.brand), color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [Text('${method.brand.toUpperCase()}  •••• ${method.last4}', style: context.textStyles.bodyMedium?.bold), if (method.isDefault) HBChip(label: 'billing.default'.tr(), selected: true), if (method.status == 'failed') HBStatusChip(kind: HBStatusKind.rejected, label: 'billing.failed'.tr()), if (method.status == 'expired') HBStatusChip(kind: HBStatusKind.rejected, label: 'billing.expired'.tr())]), Text('billing.expires'.tr(namedArgs: {'month': method.expMonth.toString().padLeft(2, '0'), 'year': (method.expYear % 100).toString().padLeft(2, '0')})), if (method.status == 'failed') Text('billing.failure.${method.lastFailureCode ?? 'other'}'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))])), PopupMenuButton<String>(onSelected: (value) => value == 'default' ? onSetDefault(method.id) : onRemove(method), itemBuilder: (_) => [if (!method.isDefault && method.status == 'active') PopupMenuItem(value: 'default', child: Text('billing.set_default'.tr())), PopupMenuItem(value: 'remove', child: Text('billing.remove'.tr()))]) ]));
}

class BillingMobileCard extends StatelessWidget {
  final VoidCallback onOpen;
  const BillingMobileCard({super.key, required this.onOpen});
  @override Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('billing.mobile_title'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.xs), Text('billing.mobile_message'.tr()), const SizedBox(height: AppSpacing.md), HBButton.secondary(label: 'billing.open_site'.tr(), icon: Icons.open_in_new_rounded, onPressed: onOpen)]));
}

IconData _brandIcon(String brand) => switch (brand) { 'visa' => Icons.credit_card_rounded, 'mastercard' => Icons.payment_rounded, 'amex' => Icons.account_balance_wallet_outlined, _ => Icons.credit_card_rounded };