import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/domain/admin_p42_models.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/providers/admin_p42_providers.dart';

class AdminOrdersPage extends ConsumerStatefulWidget {
  const AdminOrdersPage({super.key});
  @override ConsumerState<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends ConsumerState<AdminOrdersPage> {
  String query = '';
  String? selectedId;
  late Future<List<AdminOrderRecord>> future = _load();
  Future<List<AdminOrderRecord>> _load() => ref.read(adminP42RepositoryProvider).orders(query: query);
  void refresh() => setState(() => future = _load());

  @override Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('admin.orders.title'.tr(), style: context.textStyles.headlineSmall),
      const SizedBox(height: AppSpacing.md),
      HBInput(hint: 'admin.orders.search'.tr(), prefixIcon: const Icon(Icons.search), onSubmitted: (value) { query = value; refresh(); }),
      const SizedBox(height: AppSpacing.md),
      Expanded(child: FutureBuilder<List<AdminOrderRecord>>(future: future, builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
        if (snapshot.hasError) return HBEmptyState(icon: Icons.error_outline, title: 'admin.orders.error'.tr(), message: 'errors.network'.tr());
        final items = snapshot.data ?? const [];
        return HBCard(child: SingleChildScrollView(child: AdminDataTable(
          headers: [for (final key in ['date','title','kind','buyer','seller','total','status','stripe']) 'admin.orders.columns.$key'.tr()],
          emptyMessage: 'admin.orders.empty'.tr(),
          rowCallbacks: [for (final item in items) () => setState(() => selectedId = item.id)],
          rows: [for (final item in items) [Text(item.createdAt == null ? '' : DateFormat.yMd(context.locale.toString()).format(item.createdAt!.toLocal())), Text(item.title), Text('admin.orders.kind.${item.kind}'.tr()), Text(item.data['buyer_name']?.toString() ?? ''), Text(item.data['seller_name']?.toString() ?? ''), Text(_money(context, item.totalMinor, item.currencyCode)), HBStatusChip(kind: _kind(item.status), label: 'admin.orders.status.${item.status}'.tr()), const Icon(Icons.receipt_long_outlined)]],
        )));
      })),
    ])),
    if (selectedId != null) ...[const SizedBox(width: AppSpacing.md), SizedBox(width: 420, child: AdminOrderDetailPanel(orderId: selectedId!, onClose: () => setState(() => selectedId = null), onChanged: refresh))],
  ]);
}

class AdminOrderDetailPanel extends ConsumerStatefulWidget {
  final String orderId;
  final VoidCallback onClose;
  final VoidCallback onChanged;
  const AdminOrderDetailPanel({super.key, required this.orderId, required this.onClose, required this.onChanged});
  @override ConsumerState<AdminOrderDetailPanel> createState() => _AdminOrderDetailPanelState();
}

class _AdminOrderDetailPanelState extends ConsumerState<AdminOrderDetailPanel> {
  late Future<Map<String, dynamic>> future = _load();
  bool retryStripe = false;
  Future<Map<String, dynamic>> _load() => ref.read(adminP42RepositoryProvider).orderDetail(widget.orderId);
  void refresh() { setState(() => future = _load()); widget.onChanged(); }
  @override Widget build(BuildContext context) => HBCard(child: FutureBuilder<Map<String, dynamic>>(future: future, builder: (context, snapshot) {
    if (!snapshot.hasData) return snapshot.hasError ? HBEmptyState(icon: Icons.error_outline, title: 'admin.orders.error'.tr(), message: 'errors.network'.tr()) : const LinearProgressIndicator();
    final order = p42Map(snapshot.data!['order']);
    final writable = ref.watch(adminAccessProvider).value?.canWrite('orders') == true;
    return ListView(children: [
      Row(children: [Expanded(child: Text(order['title']?.toString() ?? '', style: context.textStyles.titleMedium)), IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close))]),
      HBStatusChip(kind: _kind(order['status']?.toString() ?? ''), label: 'admin.orders.status.${order['status']}'.tr()),
      const Divider(),
      for (final key in ['amount_minor','shipping_minor','platform_fee_minor','total_minor','seller_payout_minor']) ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text('admin.orders.amounts.$key'.tr()), trailing: Text(_money(context, p42Int(order[key]), order['currency_code']?.toString() ?? 'EUR'))),
      if (writable) ...[
        const Divider(),
        if (retryStripe) HBButton.primary(label: 'admin.orders.retry_refund'.tr(), onPressed: () => stripeRefund(order['id'].toString())),
        if (const {'paid','shipped','completed'}.contains(order['status'])) HBButton.primary(label: 'admin.orders.refund'.tr(), onPressed: () => refund(order['id'].toString())),
        if (order['status'] == 'refund_requested') Row(children: [Expanded(child: HBButton.primary(label: 'admin.orders.approve_refund'.tr(), onPressed: () => decide(order['id'].toString(), true))), const SizedBox(width: AppSpacing.xs), Expanded(child: HBButton.secondary(label: 'admin.orders.reject_refund'.tr(), onPressed: () => decide(order['id'].toString(), false)))]),
        const SizedBox(height: AppSpacing.sm),
        HBButton.secondary(label: 'admin.orders.add_note'.tr(), onPressed: () => note(order['id'].toString())),
      ],
    ]);
  }));

  Future<String?> ask(String title, String help) async { final controller = TextEditingController(); final value = await showDialog<String>(context: context, builder: (dialog) => AlertDialog(title: Text(title.tr()), content: Column(mainAxisSize: MainAxisSize.min, children: [Text(help.tr()), HBInput(controller: controller, maxLines: 3)]), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop()), HBButton.primary(label: 'common.confirm'.tr(), onPressed: () => controller.text.trim().isEmpty ? null : dialog.pop(controller.text.trim()))])); controller.dispose(); return value; }
  Future<void> refund(String id) async { final reason = await ask('admin.orders.refund', 'admin.orders.refund_help'); if (reason == null) return; try { await ref.read(adminP42RepositoryProvider).refundOrder(id, reason); await stripeRefund(id); } on AppException catch (error) { showError(error); } }
  Future<void> stripeRefund(String id) async { try { await ref.read(adminP42RepositoryProvider).executeStripeRefund(id); retryStripe = false; toast('admin.orders.refund_started'); } on AppException { if (mounted) setState(() => retryStripe = true); toast('admin.orders.refund_stripe_failed'); } refresh(); }
  Future<void> decide(String id, bool approve) async { final value = await ask(approve ? 'admin.orders.approve_refund' : 'admin.orders.reject_refund', 'admin.orders.decision_help'); if (value == null) return; final result = await ref.read(adminP42RepositoryProvider).decideRefund(id, approve, value); if (approve && result['needs_stripe_refund'] == true) await stripeRefund(id); refresh(); }
  Future<void> note(String id) async { final value = await ask('admin.orders.add_note', 'admin.orders.note_help'); if (value == null) return; await ref.read(adminP42RepositoryProvider).addOrderNote(id, value); refresh(); }
  void toast(String key) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr()))); }
  void showError(AppException error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
}

HBStatusKind _kind(String status) => switch (status) { 'completed' || 'refunded' => HBStatusKind.approved, 'paid' || 'shipped' => HBStatusKind.info, 'refund_requested' => HBStatusKind.pending, 'disputed' || 'cancelled' => HBStatusKind.rejected, _ => HBStatusKind.neutral };
String _money(BuildContext context, int amount, String currency) => MoneyFormatter.format(amountMinor: amount, currencyCode: currency, locale: context.locale);