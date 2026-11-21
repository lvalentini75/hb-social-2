import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/admin/domain/admin_finance_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminFinanceRepository {
  final SupabaseClient _client;
  const AdminFinanceRepository(this._client);

  Future<FinanceSnapshot> load() async {
    try {
      final since = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();
      final rawOrders = await _client.from('orders').select('id,kind,status,title,buyer_id,seller_id,total_minor,platform_fee_minor,currency_code,payment_intent_id,created_at').gte('created_at', since).order('created_at', ascending: false).limit(200);
      final ids = <String>{for (final row in rawOrders as List) ...[row['buyer_id']?.toString() ?? '', row['seller_id']?.toString() ?? '']}..remove('');
      final profiles = ids.isEmpty ? const <dynamic>[] : await _client.from('user_profiles').select('id,display_name,username').inFilter('id', ids.toList());
      final names = <String, String>{for (final row in profiles as List) row['id'].toString(): (row['display_name'] ?? row['username'] ?? '').toString()};
      final orders = rawOrders.map((row) => FinanceOrder.fromJson(Map<String, dynamic>.from(row as Map), names)).toList();
      final rawSellers = await _client.from('seller_accounts').select('user_id,onboarding_status,charges_enabled,default_currency').order('updated_at', ascending: false);
      final sellers = (rawSellers as List).map((raw) { final row = Map<String, dynamic>.from(raw as Map); final userId = row['user_id'].toString(); final sellerOrders = orders.where((order) => order.sellerId == userId && const {'paid', 'shipped', 'completed'}.contains(order.status)); return FinanceSeller(userId: userId, name: names[userId] ?? '', status: row['onboarding_status']?.toString() ?? 'pending', chargesEnabled: row['charges_enabled'] as bool? ?? false, currencyCode: row['default_currency']?.toString().toUpperCase() ?? 'EUR', orderCount: sellerOrders.length, revenueMinor: sellerOrders.fold(0, (sum, order) => sum + order.totalMinor - order.feeMinor)); }).toList();
      final rawStripe = await _client.from('stripe_events').select('id,order_id,type,result,received_at,processed_at').order('received_at', ascending: false).limit(200);
      final stripe = (rawStripe as List).map((row) => StripeEventRecord.fromJson(Map<String, dynamic>.from(row as Map))).toList();
      final rawSettings = await _client.from('platform_settings').select('key,value').inFilter('key', const ['marketplace_fee', 'event_ticket_fee', 'order_timeouts', 'limits', 'ads_billing', 'boost']);
      final settings = <String, Map<String, dynamic>>{for (final row in rawSettings as List) row['key'].toString(): Map<String, dynamic>.from(row['value'] as Map? ?? const {})};
      final currencies = orders.map((order) => order.currencyCode).toSet();
      final kpis = [for (final currency in currencies) _kpi(currency, orders)];
      return FinanceSnapshot(orders: orders, sellers: sellers, stripeEvents: stripe, kpis: kpis, settings: settings);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  FinanceCurrencyKpi _kpi(String currency, List<FinanceOrder> orders) { final rows = orders.where((order) => order.currencyCode == currency).toList(); final paid = rows.where((order) => const {'paid', 'shipped', 'completed'}.contains(order.status)).toList(); return FinanceCurrencyKpi(currencyCode: currency, paidOrders: paid.length, grossMinor: paid.fold(0, (sum, order) => sum + order.totalMinor), feesMinor: paid.fold(0, (sum, order) => sum + order.feeMinor), refunds: rows.where((order) => order.status == 'refunded').length, disputes: rows.where((order) => order.status == 'disputed').length); }

  Future<void> setSetting(String key, Map<String, dynamic> value) async { try { await _client.rpc('set_platform_setting', params: {'p_key': key, 'p_value': value}); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
}