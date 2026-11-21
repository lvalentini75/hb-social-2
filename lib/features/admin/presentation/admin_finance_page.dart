import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/features/admin/domain/admin_finance_models.dart';
import 'package:hb_social/features/admin/providers/admin_finance_providers.dart';
import 'package:hb_social/features/orders/domain/order.dart';
import 'package:hb_social/features/orders/presentation/order_detail_page.dart';
import 'package:hb_social/features/orders/providers/order_providers.dart';

class AdminFinancePage extends ConsumerStatefulWidget {
  const AdminFinancePage({super.key});
  @override ConsumerState<AdminFinancePage> createState() => _AdminFinancePageState();
}

class _AdminFinancePageState extends ConsumerState<AdminFinancePage> {
  int tab = 0;
  String? selectedOrderId;
  @override Widget build(BuildContext context) => ref.watch(adminFinanceProvider).when(loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.account_balance_outlined, title: 'admin.finance.error_title'.tr(), message: 'admin.finance.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(adminFinanceProvider)))), data: (data) => Column(children: [HBSegmentedTabs(labels: ['admin.finance.tabs.orders'.tr(), 'admin.finance.tabs.sellers'.tr(), 'admin.finance.tabs.stripe'.tr(), 'admin.finance.tabs.settings'.tr()], selectedIndex: tab, scrollable: true, onChanged: (value) => setState(() { tab = value; selectedOrderId = null; })), const SizedBox(height: AppSpacing.md), if (tab == 0) FinanceKpis(kpis: data.kpis, activeSellers: data.sellers.where((seller) => seller.chargesEnabled).length), const SizedBox(height: AppSpacing.md), Expanded(child: switch (tab) { 0 => Row(children: [Expanded(child: FinanceOrdersTable(orders: data.orders, onSelect: (id) => setState(() => selectedOrderId = id))), if (selectedOrderId != null) ...[const SizedBox(width: AppSpacing.md), SizedBox(width: 390, child: FinanceOrderPanel(orderId: selectedOrderId!, stripeEvents: data.stripeEvents.where((event) => event.orderId == selectedOrderId).toList(), onChanged: () => ref.invalidate(adminFinanceProvider), onClose: () => setState(() => selectedOrderId = null)))]]), 1 => FinanceSellersTable(sellers: data.sellers), 2 => FinanceStripeTable(events: data.stripeEvents), _ => FinanceSettings(settings: data.settings) })]));
}

class FinanceKpis extends StatelessWidget {
  final List<FinanceCurrencyKpi> kpis;
  final int activeSellers;
  const FinanceKpis({super.key, required this.kpis, required this.activeSellers});
  @override Widget build(BuildContext context) => Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final item in kpis) HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.currencyCode, style: context.textStyles.labelLarge), Text('admin.finance.kpi.orders'.tr(namedArgs: {'count': '${item.paidOrders}'})), Text('admin.finance.kpi.volume'.tr(namedArgs: {'amount': _money(context, item.grossMinor, item.currencyCode)})), Text('admin.finance.kpi.fees'.tr(namedArgs: {'amount': _money(context, item.feesMinor, item.currencyCode)})), Text('admin.finance.kpi.refunds_disputes'.tr(namedArgs: {'refunds': '${item.refunds}', 'disputes': '${item.disputes}'}))])), HBTile(child: Text('admin.finance.kpi.active_sellers'.tr(namedArgs: {'count': '$activeSellers'})))]);
}

class FinanceOrdersTable extends StatefulWidget {
  final List<FinanceOrder> orders;
  final ValueChanged<String> onSelect;
  const FinanceOrdersTable({super.key, required this.orders, required this.onSelect});
  @override State<FinanceOrdersTable> createState() => _FinanceOrdersTableState();
}

class _FinanceOrdersTableState extends State<FinanceOrdersTable> {
  final search = TextEditingController(); String status = 'all'; String kind = 'all'; String currency = 'all';
  @override void dispose() { search.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { final query = search.text.trim().toLowerCase(); final items = widget.orders.where((order) => (status == 'all' || order.status == status) && (kind == 'all' || order.kind == kind) && (currency == 'all' || order.currencyCode == currency) && (query.isEmpty || '${order.title} ${order.buyerName} ${order.sellerName}'.toLowerCase().contains(query))).toList(); final currencies = widget.orders.map((order) => order.currencyCode).toSet(); return HBCard(child: Column(children: [HBInput(controller: search, hint: 'admin.finance.search'.tr(), prefixIcon: const Icon(Icons.search), onChanged: (_) => setState(() {})), const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.sm, children: [_dropdown('admin.finance.filters.status'.tr(), status, const ['all', 'paid', 'shipped', 'completed', 'refund_requested', 'refunded', 'disputed'], (value) => setState(() => status = value)), _dropdown('admin.finance.filters.type'.tr(), kind, const ['all', 'listing', 'event_ticket'], (value) => setState(() => kind = value)), _dropdown('admin.finance.filters.currency'.tr(), currency, ['all', ...currencies], (value) => setState(() => currency = value))]), const SizedBox(height: AppSpacing.sm), Expanded(child: SingleChildScrollView(child: AdminDataTable(headers: ['admin.finance.columns.date'.tr(), 'admin.finance.columns.title'.tr(), 'admin.finance.columns.buyer'.tr(), 'admin.finance.columns.seller'.tr(), 'admin.finance.columns.total'.tr(), 'admin.finance.columns.fee'.tr(), 'admin.finance.columns.status'.tr(), 'admin.finance.columns.stripe'.tr()], emptyMessage: 'admin.finance.empty'.tr(), rowCallbacks: [for (final order in items) () => widget.onSelect(order.id)], rows: [for (final order in items) [Text(DateFormat.yMd(context.locale.toString()).format(order.createdAt.toLocal())), Text(order.title, overflow: TextOverflow.ellipsis), Text(order.buyerName), Text(order.sellerName), Text(_money(context, order.totalMinor, order.currencyCode)), Text(_money(context, order.feeMinor, order.currencyCode)), HBStatusChip(kind: _statusKind(order.status), label: 'orders.status.${order.status}'.tr()), Icon(order.hasPayment ? Icons.credit_card_rounded : Icons.money_off_rounded, size: 18)]])))])); }
  Widget _dropdown(String hint, String value, Iterable<String> values, ValueChanged<String> changed) => DropdownButton<String>(value: value, hint: Text(hint), items: [for (final item in values) DropdownMenuItem(value: item, child: Text(item == 'all' ? 'admin.finance.filters.all'.tr() : item))], onChanged: (item) { if (item != null) changed(item); });
}

class FinanceOrderPanel extends ConsumerWidget {
  final String orderId; final List<StripeEventRecord> stripeEvents; final VoidCallback onChanged; final VoidCallback onClose;
  const FinanceOrderPanel({super.key, required this.orderId, required this.stripeEvents, required this.onChanged, required this.onClose});
  Future<void> action(BuildContext context, WidgetRef ref, OrderRefundAction action) async { final value = await showModalBottomSheet<OrderRefundValue>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => OrderRefundSheet(action: action)); if (value == null || !context.mounted) return; try { final repository = ref.read(ordersRepositoryProvider); OrderActionResult? result; if (action == OrderRefundAction.cancelSeller) result = await repository.cancel(orderId, reason: value.note); if (action == OrderRefundAction.approve) result = await repository.decideRefund(orderId, approve: true, note: value.note); if (action == OrderRefundAction.decline) result = await repository.decideRefund(orderId, approve: false, note: value.note); if (result?.needsStripeRefund == true) await ref.read(paymentsRepositoryProvider).refund(orderId); ref.invalidate(orderDetailProvider(orderId)); onChanged(); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs)))); } }
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(orderDetailProvider(orderId)).when(loading: () => const HBCard(child: Center(child: CircularProgressIndicator())), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'orders.unavailable_title'.tr(), message: 'orders.unavailable_message'.tr())), data: (detail) => HBCard(child: ListView(children: [Row(children: [Expanded(child: Text(detail.order.title, style: context.textStyles.titleMedium)), IconButton(onPressed: onClose, icon: const Icon(Icons.close))]), HBStatusChip(kind: detail.order.status.chipKind, label: detail.order.status.labelKey.tr()), const SizedBox(height: AppSpacing.md), Text('${detail.buyer.displayName} -> ${detail.seller.displayName}'), Text(_money(context, detail.order.totalMinor, detail.order.currencyCode)), const Divider(), OrderTimeline(events: detail.events), const SizedBox(height: AppSpacing.md), Text('admin.finance.stripe_linked'.tr(), style: context.textStyles.titleSmall), for (final event in stripeEvents) ListTile(contentPadding: EdgeInsets.zero, title: Text(event.type), subtitle: Text('${event.result} · ${relativeTime(context, event.receivedAt)}')), if (detail.order.status == OrderStatus.paid) HBButton.primary(label: 'p34b.cancel_refund'.tr(), onPressed: () => action(context, ref, OrderRefundAction.cancelSeller)), if (detail.order.status == OrderStatus.refundRequested) Wrap(spacing: AppSpacing.sm, children: [HBButton.primary(label: 'p34b.accept_refund'.tr(), onPressed: () => action(context, ref, OrderRefundAction.approve)), HBButton.secondary(label: 'p34b.decline_refund'.tr(), onPressed: () => action(context, ref, OrderRefundAction.decline))])])));
}

class FinanceSellersTable extends StatelessWidget { final List<FinanceSeller> sellers; const FinanceSellersTable({super.key, required this.sellers}); @override Widget build(BuildContext context) => HBCard(child: SingleChildScrollView(child: AdminDataTable(headers: ['admin.finance.columns.seller'.tr(), 'admin.finance.columns.onboarding'.tr(), 'admin.finance.columns.currency'.tr(), 'admin.finance.columns.orders'.tr(), 'admin.finance.columns.revenue'.tr()], emptyMessage: 'admin.finance.sellers_empty'.tr(), rows: [for (final seller in sellers) [Text(seller.name), HBStatusChip(kind: seller.chargesEnabled ? HBStatusKind.approved : HBStatusKind.pending, label: seller.status), Text(seller.currencyCode), Text('${seller.orderCount}'), Text(_money(context, seller.revenueMinor, seller.currencyCode))]]))); }

class FinanceStripeTable extends StatelessWidget { final List<StripeEventRecord> events; const FinanceStripeTable({super.key, required this.events}); @override Widget build(BuildContext context) => HBCard(child: SingleChildScrollView(child: AdminDataTable(headers: ['admin.finance.columns.type'.tr(), 'admin.finance.columns.order'.tr(), 'admin.finance.columns.result'.tr(), 'admin.finance.columns.received'.tr(), 'admin.finance.columns.processed'.tr()], emptyMessage: 'admin.finance.stripe_empty'.tr(), rows: [for (final event in events) [Text(event.type, style: TextStyle(color: event.stalled ? LightModeColors.lightError : null)), Text(event.orderId ?? 'common.unavailable'.tr()), Text(event.result), Text(relativeTime(context, event.receivedAt)), Text(event.processedAt == null ? 'admin.finance.not_processed'.tr() : relativeTime(context, event.processedAt!))]]))); }

class FinanceSettings extends ConsumerStatefulWidget {
  final Map<String, Map<String, dynamic>> settings;
  const FinanceSettings({super.key, required this.settings});
  @override ConsumerState<FinanceSettings> createState() => _FinanceSettingsState();
}

class _FinanceSettingsState extends ConsumerState<FinanceSettings> {
  late final marketplace = TextEditingController(text: _integer('marketplace_fee', 'bps'));
  late final tickets = TextEditingController(text: _integer('event_ticket_fee', 'bps'));
  late final checkout = TextEditingController(text: _integer('order_timeouts', 'checkout_minutes'));
  late final completion = TextEditingController(text: _integer('order_timeouts', 'auto_complete_days'));
  late final cancellation = TextEditingController(text: _integer('order_timeouts', 'seller_cancel_hours'));
  late final activeListings = TextEditingController(text: _integer('limits', 'active_listings', fallback: 50));
  late final dogs = TextEditingController(text: _integer('limits', 'dogs', fallback: 30));
  late final alerts = TextEditingController(text: _integer('limits', 'sighting_alerts', fallback: 10));
  late final photos = TextEditingController(text: _integer('limits', 'listing_photos', fallback: 10));
  late final albums = TextEditingController(text: _integer('limits', 'albums', fallback: 100));
  late final cutoff = TextEditingController(text: _integer('ads_billing', 'monthly_cutoff_day', fallback: 1));
  late final minimumCharge = TextEditingController(text: _major(_minor('min_charge_minor', 50)));
  late final attempts = TextEditingController(text: _integer('ads_billing', 'max_attempts', fallback: 3));
  late final retryHours = TextEditingController(text: _integer('ads_billing', 'retry_hours', fallback: 24));
  late final graceDays = TextEditingController(text: _integer('ads_billing', 'grace_days', fallback: 3));
  late final welcomeCredit = TextEditingController(text: _major(_minor('welcome_credit_minor', 0)));
  late final spendCap = TextEditingController(text: widget.settings['ads_billing']?['default_spend_cap_minor'] == null ? '' : _major(_minor('default_spend_cap_minor', 0)));
  late final List<TextEditingController> thresholds = [for (final value in widget.settings['ads_billing']?['thresholds_minor'] as List? ?? const [1000, 2500, 5000, 10000]) TextEditingController(text: _major((value as num).toInt()))];
  late final boostPresets = TextEditingController(text: (widget.settings['boost']?['budget_presets_minor'] as List? ?? const []).join(','));
  late final boostDurations = TextEditingController(text: (widget.settings['boost']?['durations_days'] as List? ?? const []).join(','));
  late final boostMin = TextEditingController(text: _integer('boost', 'min_budget_minor'));
  late final boostMax = TextEditingController(text: _integer('boost', 'max_budget_minor'));
  late final boostCpm = TextEditingController(text: _integer('boost', 'cpm_minor'));
  late final boostFrequency = TextEditingController(text: _integer('boost', 'frequency_cap_per_day', fallback: 3));
  late final boostActive = TextEditingController(text: _integer('boost', 'max_active_per_user', fallback: 3));
  late bool boostAutoApprove = widget.settings['boost']?['auto_approve'] != false;
  bool saving = false;

  String _integer(String group, String key, {int fallback = 0}) => ((widget.settings[group]?[key] as num?)?.toInt() ?? fallback).toString();
  int _minor(String key, int fallback) => (widget.settings['ads_billing']?[key] as num?)?.toInt() ?? fallback;

  @override void dispose() {
    for (final item in [marketplace, tickets, checkout, completion, cancellation, activeListings, dogs, alerts, photos, albums, cutoff, minimumCharge, attempts, retryHours, graceDays, welcomeCredit, spendCap, boostPresets, boostDurations, boostMin, boostMax, boostCpm, boostFrequency, boostActive, ...thresholds]) { item.dispose(); }
    super.dispose();
  }

  Future<void> save() async {
    final thresholdValues = thresholds.map((item) => _parseMinor(item.text)).toList();
    final presetValues = _integerList(boostPresets.text);
    final durationValues = _integerList(boostDurations.text);
    final limitValues = [activeListings, dogs, alerts, photos, albums].map((item) => int.tryParse(item.text.trim()) ?? 0).toList();
    final validThresholds = thresholdValues.length <= 8 && thresholdValues.every((value) => value >= 100) && List.generate(thresholdValues.length - 1, (index) => thresholdValues[index] < thresholdValues[index + 1]).every((value) => value);
    final cap = spendCap.text.trim().isEmpty ? null : _parseMinor(spendCap.text);
    final validBilling = validThresholds && _between(cutoff, 1, 28) && _betweenMinor(minimumCharge, 50, 10000) && _between(attempts, 1, 10) && _between(retryHours, 1, 168) && _between(graceDays, 0, 30) && _betweenMinor(welcomeCredit, 0, 50000) && (cap == null || cap >= 1000);
    final boostMinimum = int.tryParse(boostMin.text) ?? 0;
    final boostMaximum = int.tryParse(boostMax.text) ?? 0;
    final validBoost = presetValues.isNotEmpty && durationValues.isNotEmpty && boostMinimum > 0 && boostMaximum >= boostMinimum && presetValues.every((value) => value >= boostMinimum && value <= boostMaximum) && durationValues.every((value) => value > 0) && _between(boostCpm, 1, 100000) && _between(boostFrequency, 1, 100) && _between(boostActive, 1, 100);
    if (limitValues.any((value) => value < 1) || !validBilling || !validBoost) { _toast('boost.admin.invalid'); return; }
    final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text('admin_finance_p35.confirm_title'.tr()), content: Text('admin_finance_p35.confirm_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop(false)), HBButton.primary(label: 'common.save'.tr(), onPressed: () => dialog.pop(true))])) ?? false;
    if (!confirmed || !mounted) return;
    setState(() => saving = true);
    try {
      final repository = ref.read(adminFinanceRepositoryProvider);
      await repository.setSetting('marketplace_fee', {...?widget.settings['marketplace_fee'], 'bps': int.tryParse(marketplace.text) ?? 0});
      await repository.setSetting('event_ticket_fee', {...?widget.settings['event_ticket_fee'], 'bps': int.tryParse(tickets.text) ?? 0});
      await repository.setSetting('order_timeouts', {'checkout_minutes': int.tryParse(checkout.text) ?? 0, 'auto_complete_days': int.tryParse(completion.text) ?? 0, 'seller_cancel_hours': int.tryParse(cancellation.text) ?? 0});
      await repository.setSetting('limits', {'active_listings': limitValues[0], 'dogs': limitValues[1], 'sighting_alerts': limitValues[2], 'listing_photos': limitValues[3], 'albums': limitValues[4]});
      await repository.setSetting('ads_billing', {'thresholds_minor': thresholdValues, 'monthly_cutoff_day': int.parse(cutoff.text), 'min_charge_minor': _parseMinor(minimumCharge.text), 'max_attempts': int.parse(attempts.text), 'retry_hours': int.parse(retryHours.text), 'grace_days': int.parse(graceDays.text), 'welcome_credit_minor': _parseMinor(welcomeCredit.text), 'default_spend_cap_minor': cap, 'payment_method_types': ['card']});
      await repository.setSetting('boost', {'budget_presets_minor': presetValues, 'min_budget_minor': boostMinimum, 'max_budget_minor': boostMaximum, 'durations_days': durationValues, 'cpm_minor': int.parse(boostCpm.text), 'frequency_cap_per_day': int.parse(boostFrequency.text), 'max_active_per_user': int.parse(boostActive.text), 'auto_approve': boostAutoApprove});
      ref.invalidate(adminFinanceProvider);
      if (mounted) _toast('admin.finance.settings_saved');
    } on AppException catch (error) { if (mounted) _toast(error.messageKey); } finally { if (mounted) setState(() => saving = false); }
  }

  @override Widget build(BuildContext context) => ListView(children: [
    FinanceSettingsCard(titleKey: 'admin.finance.commissions', noteKey: 'admin_finance_p35.commissions_note', fields: [_field('admin.finance.marketplace_fee', marketplace), _field('admin.finance.event_fee', tickets)]),
    const SizedBox(height: AppSpacing.md),
    FinanceSettingsCard(titleKey: 'admin_finance_p35.limits', fields: [_field('admin_finance_p35.limit_active_listings', activeListings), _field('admin_finance_p35.limit_dogs', dogs), _field('admin_finance_p35.limit_alerts', alerts), _field('admin_finance_p35.limit_listing_photos', photos), _field('admin_finance_p35.limit_albums', albums)]),
    const SizedBox(height: AppSpacing.md),
    FinanceSettingsCard(titleKey: 'admin_finance_p35.ads_billing', fields: [Text('admin_finance_p35.thresholds'.tr(), style: context.textStyles.labelLarge), for (var index = 0; index < thresholds.length; index++) Row(children: [Expanded(child: _field('admin_finance_p35.threshold_value', thresholds[index], decimal: true)), if (thresholds.length > 1) HBButton.icon(icon: Icons.remove_circle_outline, onPressed: () => setState(() => thresholds.removeAt(index)))]), if (thresholds.length < 8) HBButton.secondary(label: 'admin_finance_p35.add_threshold'.tr(), onPressed: () => setState(() => thresholds.add(TextEditingController()))), _field('admin_finance_p35.cutoff_day', cutoff), _field('admin_finance_p35.minimum_charge', minimumCharge, decimal: true), _field('admin_finance_p35.max_attempts', attempts), _field('admin_finance_p35.retry_hours', retryHours), _field('admin_finance_p35.grace_days', graceDays), _field('admin_finance_p35.welcome_credit', welcomeCredit, decimal: true), _field('admin_finance_p35.default_spend_cap', spendCap, decimal: true)]),
    const SizedBox(height: AppSpacing.md),
    FinanceSettingsCard(titleKey: 'boost.admin.title', fields: [_field('boost.admin.presets', boostPresets), _field('boost.admin.minimum', boostMin), _field('boost.admin.maximum', boostMax), _field('boost.admin.durations', boostDurations), _field('boost.admin.cpm', boostCpm), _field('boost.admin.frequency', boostFrequency), _field('boost.admin.active_limit', boostActive), SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('boost.admin.auto_approve'.tr()), value: boostAutoApprove, onChanged: (value) => setState(() => boostAutoApprove = value))]),
    const SizedBox(height: AppSpacing.md),
    FinanceSettingsCard(titleKey: 'admin.finance.timeouts', fields: [_field('admin.finance.checkout_minutes', checkout), _field('admin.finance.complete_days', completion), _field('admin.finance.cancel_hours', cancellation)]),
    const SizedBox(height: AppSpacing.md),
    HBButton.primary(label: 'common.save'.tr(), isLoading: saving, onPressed: saving ? null : save),
    const SizedBox(height: AppSpacing.xl),
  ]);

  Widget _field(String key, TextEditingController controller, {bool decimal = false}) => Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: HBFormField(label: key.tr(), child: HBInput(controller: controller, keyboardType: TextInputType.numberWithOptions(decimal: decimal))));
  bool _between(TextEditingController controller, int min, int max) { final value = int.tryParse(controller.text.trim()); return value != null && value >= min && value <= max; }
  bool _betweenMinor(TextEditingController controller, int min, int max) { final value = _parseMinor(controller.text); return value >= min && value <= max; }
  void _toast(String key) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr())));
  List<int> _integerList(String value) => value.split(',').map((item) => int.tryParse(item.trim())).whereType<int>().toSet().toList()..sort();
}

class FinanceSettingsCard extends StatelessWidget {
  final String titleKey;
  final String? noteKey;
  final List<Widget> fields;
  const FinanceSettingsCard({super.key, required this.titleKey, this.noteKey, required this.fields});
  @override Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(titleKey.tr(), style: context.textStyles.titleMedium), if (noteKey != null) ...[const SizedBox(height: AppSpacing.xs), Text(noteKey!.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))], ...fields]));
}

String _major(int minor) => minor % 100 == 0 ? '${minor ~/ 100}' : '${minor ~/ 100},${(minor % 100).toString().padLeft(2, '0')}';
int _parseMinor(String input) { final normalized = input.trim().replaceAll(',', '.'); final parts = normalized.split('.'); final major = int.tryParse(parts.first) ?? -1; if (major < 0 || parts.length > 2) return -1; final decimals = parts.length == 1 ? '' : parts[1]; if (decimals.length > 2 || int.tryParse(decimals.isEmpty ? '0' : decimals) == null) return -1; return major * 100 + int.parse(decimals.padRight(2, '0').isEmpty ? '0' : decimals.padRight(2, '0')); }

HBStatusKind _statusKind(String status) => switch (status) { 'paid' || 'shipped' => HBStatusKind.info, 'completed' => HBStatusKind.approved, 'refund_requested' => HBStatusKind.pending, 'disputed' => HBStatusKind.rejected, _ => HBStatusKind.neutral };
String _money(BuildContext context, int amount, String currency) => MoneyFormatter.format(amountMinor: amount, currencyCode: currency, locale: context.locale);