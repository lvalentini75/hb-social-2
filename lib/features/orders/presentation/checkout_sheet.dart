import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/features/marketplace/domain/listing.dart';
import 'package:hb_social/features/orders/domain/order.dart';
import 'package:hb_social/features/orders/providers/order_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showCheckoutSheet(BuildContext context, Listing listing) => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => CheckoutSheet(listing: listing));

class CheckoutSheet extends ConsumerStatefulWidget {
  final Listing listing;
  const CheckoutSheet({super.key, required this.listing});
  @override ConsumerState<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  String delivery = 'pickup';
  OrderQuote? quote;
  bool loading = true;
  bool paying = false;
  final name = TextEditingController(); final line1 = TextEditingController(); final line2 = TextEditingController(); final postal = TextEditingController(); final city = TextEditingController(); final province = TextEditingController(); final phone = TextEditingController(); final note = TextEditingController();
  String country = 'IT';
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { final preferences = await SharedPreferences.getInstance(); final saved = jsonDecode(preferences.getString('checkout_shipping_address') ?? '{}') as Map<String, dynamic>; name.text = saved['name']?.toString() ?? ''; line1.text = saved['line1']?.toString() ?? ''; line2.text = saved['line2']?.toString() ?? ''; postal.text = saved['postal_code']?.toString() ?? ''; city.text = saved['city']?.toString() ?? ''; province.text = saved['province']?.toString() ?? ''; phone.text = saved['phone']?.toString() ?? ''; country = saved['country_code']?.toString() ?? 'IT'; await refreshQuote(); }
  Future<void> refreshQuote() async { setState(() => loading = true); try { quote = await ref.read(ordersRepositoryProvider).quote(widget.listing.id, delivery); } on AppException catch (error) { if (mounted) _error(error); } finally { if (mounted) setState(() => loading = false); } }
  Map<String, dynamic> get address => {'name': name.text.trim(), 'line1': line1.text.trim(), if (line2.text.trim().isNotEmpty) 'line2': line2.text.trim(), 'postal_code': postal.text.trim(), 'city': city.text.trim(), if (province.text.trim().isNotEmpty) 'province': province.text.trim(), 'country_code': country, if (phone.text.trim().isNotEmpty) 'phone': phone.text.trim()};
  bool get addressValid => delivery == 'pickup' || name.text.trim().isNotEmpty && line1.text.trim().isNotEmpty && postal.text.trim().isNotEmpty && city.text.trim().isNotEmpty;
  Future<void> pay() async { if (!addressValid) { _error(const AppException('payments.errors.order_address_required')); return; } setState(() => paying = true); try { if (delivery == 'shipping') { final preferences = await SharedPreferences.getInstance(); await preferences.setString('checkout_shipping_address', jsonEncode(address)); } final base = Uri.base; final result = await ref.read(paymentsRepositoryProvider).checkout(listingId: widget.listing.id, deliveryMethod: delivery, shippingAddress: delivery == 'shipping' ? address : null, buyerNote: note.text.trim().isEmpty ? null : note.text.trim(), successUrl: base.resolve('/orders/{ORDER_ID}?checkout=success').toString(), cancelUrl: base.resolve('/orders/{ORDER_ID}?checkout=cancel').toString()); if (!mounted) return; await launchUrl(result.url, mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication, webOnlyWindowName: kIsWeb ? '_self' : null); } on AppException catch (error) { if (mounted) _error(error); } finally { if (mounted) setState(() => paying = false); } }
  @override void dispose() { for (final controller in [name, line1, line2, postal, city, province, phone, note]) { controller.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) { final value = quote; return Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('orders.checkout_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), Row(children: [if (widget.listing.mediaPath != null) ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: Image.network(widget.listing.mediaPath!, width: 72, height: 72, fit: BoxFit.cover)), if (widget.listing.mediaPath != null) const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.listing.title, style: context.textStyles.titleMedium), Text(_money(widget.listing.originalPrice.amountMinor, widget.listing.originalPrice.currencyCode))]))]), const SizedBox(height: AppSpacing.md), HBFormField(label: 'orders.delivery_title'.tr(), child: HBChoice<String>(options: value?.deliveryMethods ?? const ['pickup'], value: delivery, labelBuilder: (item) => 'orders.delivery.$item'.tr(), onChanged: (item) { setState(() => delivery = item); refreshQuote(); })), if (delivery == 'shipping') ...[const SizedBox(height: AppSpacing.md), HBFormSection(title: 'orders.shipping_address'.tr(), children: [HBFormField(label: 'orders.address.name'.tr(), required: true, child: HBInput(controller: name, onChanged: (_) => setState(() {}))), HBFormField(label: 'orders.address.line1'.tr(), required: true, child: HBInput(controller: line1, onChanged: (_) => setState(() {}))), HBFormField(label: 'orders.address.line2'.tr(), child: HBInput(controller: line2)), Row(children: [Expanded(child: HBFormField(label: 'orders.address.postal_code'.tr(), required: true, child: HBInput(controller: postal, onChanged: (_) => setState(() {})))), const SizedBox(width: AppSpacing.sm), Expanded(child: HBFormField(label: 'orders.address.city'.tr(), required: true, child: HBInput(controller: city, onChanged: (_) => setState(() {}))))]), HBFormField(label: 'orders.address.province'.tr(), child: HBInput(controller: province)), HBFormField(label: 'orders.address.country'.tr(), required: true, child: HBSelect<String>(value: country, options: ['IT', 'FR', 'ES', 'DE', 'AT', 'GB'].map((item) => HBSelectOption(value: item, label: 'zone.country_${item.toLowerCase()}'.tr())).toList(), onChanged: (item) { if (item != null) setState(() => country = item); })), HBFormField(label: 'orders.address.phone'.tr(), child: HBInput(controller: phone, keyboardType: TextInputType.phone))])], const SizedBox(height: AppSpacing.md), HBFormField(label: 'orders.buyer_note'.tr(), child: HBInput(controller: note, maxLines: 3, maxLength: 500)), const SizedBox(height: AppSpacing.md), if (loading) const LinearProgressIndicator() else if (value != null) ...[OrderCheckoutRow(label: 'orders.item_price'.tr(), value: _money(value.amountMinor, value.currencyCode)), if (value.platformFeeMinor > 0) OrderCheckoutRow(label: 'orders.platform_fee'.tr(), value: _money(value.platformFeeMinor, value.currencyCode)), OrderCheckoutRow(label: 'orders.total'.tr(), value: _money(value.totalMinor, value.currencyCode), strong: true), if (value.displayCurrency != value.currencyCode) Text('orders.converted_total'.tr(namedArgs: {'amount': _money(value.displayTotalMinor, value.displayCurrency)}))], const SizedBox(height: AppSpacing.md), HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('orders.stripe_secure'.tr()), Text('orders.delivery_assurance'.tr())])), const SizedBox(height: AppSpacing.lg), SizedBox(width: double.infinity, child: HBButton.primary(label: 'orders.proceed_payment'.tr(), isLoading: paying, onPressed: loading || paying || !addressValid ? null : pay))]))); }
  String _money(int amount, String currency) => MoneyFormatter.format(amountMinor: amount, currencyCode: currency, locale: context.locale);
  void _error(AppException error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
}

class OrderCheckoutRow extends StatelessWidget { final String label; final String value; final bool strong; const OrderCheckoutRow({super.key, required this.label, required this.value, this.strong = false}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text(label)), Text(value, style: strong ? context.textStyles.bodyMedium?.bold : null)])); }