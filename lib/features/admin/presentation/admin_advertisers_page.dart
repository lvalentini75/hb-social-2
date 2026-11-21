import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/domain/admin_p42_models.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/providers/admin_p42_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminAdvertisersPage extends ConsumerStatefulWidget {
  const AdminAdvertisersPage({super.key});
  @override ConsumerState<AdminAdvertisersPage> createState() => _AdminAdvertisersPageState();
}

class _AdminAdvertisersPageState extends ConsumerState<AdminAdvertisersPage> {
  int tab = 0;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.advertisers.title'.tr(), style: context.textStyles.headlineSmall), Text('admin.advertisers.subtitle'.tr())])), if (tab == 1 && ref.watch(adminAccessProvider).value?.canWrite('advertisers') == true) HBButton.primary(label: 'admin.promo.new'.tr(), icon: Icons.add, onPressed: () => showDialog<void>(context: context, builder: (_) => const AdminPromoDialog()))]), const SizedBox(height: AppSpacing.md), HBSegmentedTabs(labels: ['admin.advertisers.tabs.charges'.tr(), 'admin.advertisers.tabs.promo'.tr(), 'admin.advertisers.tabs.review'.tr()], selectedIndex: tab, onChanged: (value) => setState(() => tab = value)), const SizedBox(height: AppSpacing.md), Expanded(child: switch (tab) { 0 => const AdminAdChargesTab(), 1 => const AdminPromoCodesTab(), _ => HBCard(child: HBEmptyState(icon: Icons.fact_check_outlined, title: 'admin.advertisers.review_title'.tr(), message: 'admin.advertisers.review_help'.tr(), action: HBButton.primary(label: 'admin.advertisers.open_review'.tr(), onPressed: () => context.go('/admin/ads')))) })]);
}

class AdminAdChargesTab extends ConsumerStatefulWidget {
  const AdminAdChargesTab({super.key});
  @override ConsumerState<AdminAdChargesTab> createState() => _AdminAdChargesTabState();
}

class _AdminAdChargesTabState extends ConsumerState<AdminAdChargesTab> {
  String query = '';
  String? status;
  Timer? debounce;
  late Future<List<AdminAdCharge>> future = load();
  Future<List<AdminAdCharge>> load() => ref.read(adminP42RepositoryProvider).adCharges(status: status, query: query);
  void reload() => setState(() => future = load());
  @override void dispose() { debounce?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) => HBCard(child: Column(children: [HBInput(hint: 'admin.advertisers.search'.tr(), prefixIcon: const Icon(Icons.search), onChanged: (value) { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 350), () { query = value; reload(); }); }), const SizedBox(height: AppSpacing.sm), FutureBuilder<List<AdminAdCharge>>(future: future, builder: (context, snapshot) { if (!snapshot.hasData) return snapshot.hasError ? Text('errors.network'.tr()) : const LinearProgressIndicator(); return Expanded(child: SingleChildScrollView(child: AdminDataTable(headers: [for (final key in ['date','account','owner','amount','reason','status','attempts','error','receipt']) 'admin.advertisers.columns.$key'.tr()], columnWidths: const [120,190,160,120,110,120,80,150,80], emptyMessage: 'admin.advertisers.empty'.tr(), rows: [for (final charge in snapshot.data!) [Text(charge.createdAt == null ? '' : DateFormat.yMd(context.locale.toString()).format(charge.createdAt!.toLocal())), Text('${charge.data['account_name'] ?? ''}\n${'admin.advertisers.kind.${charge.data['account_kind'] ?? 'personal'}'.tr()}'), Text(charge.data['owner_username']?.toString() ?? ''), Text(_money(context, charge.amountMinor, charge.currencyCode)), Text('admin.advertisers.reason.${charge.data['reason'] ?? 'manual'}'.tr()), HBStatusChip(kind: charge.status == 'succeeded' ? HBStatusKind.approved : charge.status == 'failed' ? HBStatusKind.rejected : HBStatusKind.pending, label: 'admin.advertisers.status.${charge.status}'.tr()), Text('${p42Int(charge.data['attempts'])}'), Text(charge.data['failure_code']?.toString() ?? ''), IconButton(icon: const Icon(Icons.open_in_new, size: 18), onPressed: charge.data['receipt_url'] == null ? null : () => launchUrl(Uri.parse(charge.data['receipt_url'].toString())))]]))); })]));
}

class AdminPromoCodesTab extends ConsumerWidget {
  const AdminPromoCodesTab({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(adminPromoCodesProvider).when(loading: () => const LinearProgressIndicator(), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'admin.promo.error'.tr(), message: 'errors.network'.tr()), data: (items) => items.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.confirmation_number_outlined, title: 'admin.promo.empty'.tr(), message: 'admin.promo.empty_message'.tr(), action: ref.watch(adminAccessProvider).value?.canWrite('advertisers') == true ? HBButton.primary(label: 'admin.promo.new'.tr(), onPressed: () => showDialog<void>(context: context, builder: (_) => const AdminPromoDialog())) : null)) : HBCard(child: SingleChildScrollView(child: AdminDataTable(headers: [for (final key in ['code','credit','used','validity','status','creator','actions']) 'admin.promo.columns.$key'.tr()], columnWidths: const [150,130,110,220,120,160,80], emptyMessage: 'admin.promo.empty'.tr(), rows: [for (final item in items) [Text(item.code, style: context.textStyles.titleSmall), Text(_money(context, item.creditMinor, item.currencyCode)), Text('${item.redeemedCount}/${item.maxRedemptions?.toString() ?? '∞'}'), Text('${item.data['valid_from'] ?? '—'} — ${item.data['valid_to'] ?? '—'}'), HBStatusChip(kind: item.status == 'active' ? HBStatusKind.approved : HBStatusKind.neutral, label: 'admin.promo.status.${item.status}'.tr()), Text(item.data['created_by_name']?.toString() ?? ''), PopupMenuButton<String>(onSelected: (value) async { if (value == 'edit') { await showDialog<void>(context: context, builder: (_) => AdminPromoDialog(item: item)); } else { await ref.read(adminP42RepositoryProvider).setPromoStatus(item.id, value); } ref.invalidate(adminPromoCodesProvider); }, itemBuilder: (_) => [PopupMenuItem(value: 'edit', child: Text('common.edit'.tr())), PopupMenuItem(value: item.status == 'active' ? 'disabled' : 'active', child: Text((item.status == 'active' ? 'admin.promo.disable' : 'admin.promo.enable').tr()))])]]))));
}

class AdminPromoDialog extends ConsumerStatefulWidget {
  final AdminPromoCode? item;
  const AdminPromoDialog({super.key, this.item});
  @override ConsumerState<AdminPromoDialog> createState() => _AdminPromoDialogState();
}

class _AdminPromoDialogState extends ConsumerState<AdminPromoDialog> {
  late final code = TextEditingController(text: widget.item?.code ?? '');
  late final credit = TextEditingController(text: widget.item == null ? '' : _major(widget.item!.creditMinor));
  late final maximum = TextEditingController(text: widget.item?.maxRedemptions?.toString() ?? '');
  late final note = TextEditingController(text: widget.item?.data['note']?.toString() ?? '');
  late String currency = widget.item?.currencyCode ?? 'EUR';
  bool saving = false;
  @override void dispose() { code.dispose(); credit.dispose(); maximum.dispose(); note.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AlertDialog(title: Text((widget.item == null ? 'admin.promo.new' : 'admin.promo.edit').tr()), content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(children: [HBFormField(label: 'admin.promo.fields.code'.tr(), child: HBInput(controller: code, maxLength: 32, inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9_-]')), UpperCaseTextFormatter()])), HBFormField(label: 'admin.promo.fields.credit'.tr(), child: HBInput(controller: credit, enabled: widget.item?.redeemedCount == 0 || widget.item == null, keyboardType: const TextInputType.numberWithOptions(decimal: true))), HBFormField(label: 'admin.promo.fields.currency'.tr(), child: HBSelect<String>(value: currency, options: const [HBSelectOption(value: 'EUR', label: 'EUR'), HBSelectOption(value: 'GBP', label: 'GBP'), HBSelectOption(value: 'USD', label: 'USD'), HBSelectOption(value: 'CHF', label: 'CHF')], onChanged: widget.item?.redeemedCount == 0 || widget.item == null ? (value) { if (value != null) setState(() => currency = value); } : null)), HBFormField(label: 'admin.promo.fields.maximum'.tr(), child: HBInput(controller: maximum, keyboardType: TextInputType.number)), HBFormField(label: 'admin.promo.fields.note'.tr(), child: HBInput(controller: note, maxLines: 3))]))), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop()), HBButton.primary(label: 'common.save'.tr(), isLoading: saving, onPressed: saving ? null : save)]);
  Future<void> save() async { final amount = _minor(credit.text); if (code.text.trim().length < 4 || amount < 100) return; setState(() => saving = true); try { await ref.read(adminP42RepositoryProvider).upsertPromo(id: widget.item?.id, code: code.text, creditMinor: amount, currencyCode: currency, maxRedemptions: int.tryParse(maximum.text), note: note.text); ref.invalidate(adminPromoCodesProvider); if (mounted) context.pop(); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } finally { if (mounted) setState(() => saving = false); } }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) => newValue.copyWith(text: newValue.text.toUpperCase(), selection: newValue.selection);
}
String _money(BuildContext context, int amount, String currency) => MoneyFormatter.format(amountMinor: amount, currencyCode: currency, locale: context.locale);
String _major(int minor) => '${minor ~/ 100},${(minor % 100).toString().padLeft(2, '0')}';
int _minor(String value) { final parts = value.trim().replaceAll(',', '.').split('.'); final major = int.tryParse(parts.first) ?? 0; final cents = parts.length > 1 ? int.tryParse(parts[1].padRight(2, '0').substring(0, 2)) ?? 0 : 0; return major * 100 + cents; }