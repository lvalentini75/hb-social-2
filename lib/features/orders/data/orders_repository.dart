import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/orders/domain/order.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersRepository {
  static const pageSize = 20;
  final SupabaseClient _client;
  const OrdersRepository(this._client);
  Future<OrderQuote> quote(String listingId, String deliveryMethod) async => _rpcOne('order_quote', {'p_listing_id': listingId, 'p_delivery_method': deliveryMethod}, OrderQuote.fromJson);
  Future<List<Order>> myOrders({required String role, String? status, int offset = 0}) async { try { final rows = await _client.rpc('my_orders', params: {'p_role': role, 'p_status': status, 'p_limit': pageSize, 'p_offset': offset}); return (rows as List).map((row) => _order(Map<String, dynamic>.from(row as Map))).toList(); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<OrderDetail> detail(String id) async => _rpcOne('order_detail', {'p_order_id': id}, (json) { _images(json); return OrderDetail.fromJson(json); });
  Future<void> markShipped(String id, {String? carrier, String? trackingCode}) async { try { await _client.rpc('mark_order_shipped', params: {'p_order_id': id, 'p_carrier': carrier, 'p_tracking_code': trackingCode}); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<void> confirmReceived(String id) async { try { await _client.rpc('confirm_order_received', params: {'p_order_id': id}); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<OrderActionResult> cancel(String id, {String? reason}) => _rpcOne('cancel_order', {'p_order_id': id, 'p_reason': reason}, OrderActionResult.fromJson);
  Future<void> requestRefund(String id, String reason) async { try { await _client.rpc('request_order_refund', params: {'p_order_id': id, 'p_reason': reason}); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<OrderActionResult> decideRefund(String id, {required bool approve, String? note}) => _rpcOne('decide_order_refund', {'p_order_id': id, 'p_approve': approve, 'p_note': note}, OrderActionResult.fromJson);
  Future<PayoutsSummary> payoutsSummary() => _rpcOne('my_seller_payouts_summary', const {}, PayoutsSummary.fromJson);
  Stream<Map<String, dynamic>> watchOrder(String id) => _client.from('orders').stream(primaryKey: ['id']).eq('id', id).map((rows) => rows.isEmpty ? const <String, dynamic>{} : rows.first);
  Future<T> _rpcOne<T>(String name, Map<String, dynamic> params, T Function(Map<String, dynamic>) parse) async { try { final value = await _client.rpc(name, params: params); if (value == null) throw const AppException('orders.errors.order_not_found'); return parse(Map<String, dynamic>.from(value as Map)); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Order _order(Map<String, dynamic> json) { if (json['media_path'] != null) json['image_url'] = storagePublicUrl(_client, 'listing-media', json['media_path']?.toString()); final counterpart = json['counterpart']; if (counterpart is Map && counterpart['avatar_url'] != null) counterpart['avatar_url'] = storagePublicUrl(_client, 'avatars', counterpart['avatar_url']?.toString()); return Order.fromJson(json); }
  void _images(Map<String, dynamic> json) { final order = Map<String, dynamic>.from(json['order'] as Map? ?? const {}); final listing = Map<String, dynamic>.from(json['listing'] as Map? ?? const {}); order['listing_id'] ??= listing['id']; order['media_path'] ??= listing['media_path']; if (order['media_path'] != null) order['image_url'] = storagePublicUrl(_client, 'listing-media', order['media_path']?.toString()); for (final key in ['buyer', 'seller']) { final person = Map<String, dynamic>.from(json[key] as Map? ?? const {}); if (person['avatar_url'] != null) person['avatar_url'] = storagePublicUrl(_client, 'avatars', person['avatar_url']?.toString()); json[key] = person; } json['order'] = order; }
}