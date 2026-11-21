import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/admin/domain/admin_p42_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminP42Repository {
  final SupabaseClient _client;
  const AdminP42Repository(this._client);

  Future<AdminListingsStats> listingStats() => _object('admin_listings_stats', const {}, AdminListingsStats.fromJson);
  Future<List<AdminListingReviewItem>> listings({required String review, String? status, String? categoryId, String? query, int limit = 50, int offset = 0}) async {
    final rows = await _rpc('admin_listings_queue', {'p_review': review, 'p_status': status, 'p_category_id': categoryId, 'p_q': _text(query), 'p_limit': limit, 'p_offset': offset});
    return [for (final raw in rows as List) AdminListingReviewItem.fromJson(_listingUrls(Map<String, dynamic>.from(raw as Map)))];
  }
  Future<void> reviewListing(String id, String decision, String? note) => _void('admin_listing_review', {'p_id': id, 'p_decision': decision, 'p_note': _text(note)});
  Future<void> setCategoryReview(String id, bool required) => _void('admin_set_category_review', {'p_category_id': id, 'p_requires_review': required});
  Future<void> removeListing(String id) => _void('set_listing_status', {'p_id': id, 'p_status': 'removed'});

  Future<Map<String, dynamic>> orderStats() => _object('admin_orders_stats', const {}, (value) => value);
  Future<List<AdminOrderRecord>> orders({String? status, String? kind, String? query, DateTime? from, DateTime? to, int limit = 50, int offset = 0}) async => _list('admin_orders_list', {'p_status': status, 'p_kind': kind, 'p_q': _text(query), 'p_from': from?.toUtc().toIso8601String(), 'p_to': to?.toUtc().toIso8601String(), 'p_limit': limit, 'p_offset': offset}, AdminOrderRecord.fromJson);
  Future<Map<String, dynamic>> orderDetail(String id) => _object('order_detail', {'p_order_id': id}, (value) => value);
  Future<Map<String, dynamic>> refundOrder(String id, String reason) => _object('admin_order_refund', {'p_order_id': id, 'p_reason': reason.trim()}, (value) => value);
  Future<Map<String, dynamic>> decideRefund(String id, bool approve, String note) => _object('decide_order_refund', {'p_order_id': id, 'p_approve': approve, 'p_note': note.trim()}, (value) => value);
  Future<void> addOrderNote(String id, String note) => _void('admin_order_note', {'p_order_id': id, 'p_note': note.trim()});
  Future<void> executeStripeRefund(String id) async {
    try {
      final session = _client.auth.currentSession;
      final response = await _client.functions.invoke('payments', body: {'action': 'refund', 'order_id': id}, headers: {'Authorization': 'Bearer ${session?.accessToken ?? ''}'});
      final data = response.data;
      if (data is Map && data['error'] != null) throw Exception(data['error']);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<AdminPromoCode>> promoCodes() => _list('admin_promo_codes_list', const {}, AdminPromoCode.fromJson);
  Future<String> upsertPromo({String? id, required String code, required int creditMinor, required String currencyCode, int? maxRedemptions, DateTime? validFrom, DateTime? validTo, String? note}) async => (await _rpc('admin_promo_code_upsert', {'p_id': id, 'p_code': code.trim().toUpperCase(), 'p_credit_minor': creditMinor, 'p_currency_code': currencyCode, 'p_max_redemptions': maxRedemptions, 'p_valid_from': validFrom?.toUtc().toIso8601String(), 'p_valid_to': validTo?.toUtc().toIso8601String(), 'p_note': _text(note)})).toString();
  Future<void> setPromoStatus(String id, String status) => _void('admin_promo_code_set_status', {'p_id': id, 'p_status': status});
  Future<List<AdminAdCharge>> adCharges({String? status, DateTime? from, DateTime? to, String? query, int limit = 50, int offset = 0}) => _list('admin_ad_charges_list', {'p_status': status, 'p_from': from?.toUtc().toIso8601String(), 'p_to': to?.toUtc().toIso8601String(), 'p_q': _text(query), 'p_limit': limit, 'p_offset': offset}, AdminAdCharge.fromJson);
  Future<AdminRevenueReport> revenue(DateTime from, DateTime to, String group) => _object('admin_revenue_report', {'p_from': _dateOnly(from), 'p_to': _dateOnly(to), 'p_group': group}, AdminRevenueReport.fromJson);

  Map<String, dynamic> _listingUrls(Map<String, dynamic> row) { row['media'] = [for (final item in p42Maps(row['media'])) {...item, 'url': storagePublicUrl(_client, 'listing-media', item['path']?.toString())}]; if (row['seller_avatar_url'] != null) row['seller_avatar_url'] = storagePublicUrl(_client, 'avatars', row['seller_avatar_url']?.toString()); return row; }
  Future<List<T>> _list<T>(String name, Map<String, dynamic> params, T Function(Map<String, dynamic>) parse) async { final rows = await _rpc(name, params); return [for (final raw in rows as List) parse(Map<String, dynamic>.from(raw as Map))]; }
  Future<T> _object<T>(String name, Map<String, dynamic> params, T Function(Map<String, dynamic>) parse) async { final raw = await _rpc(name, params); final value = raw is List && raw.isNotEmpty ? raw.first : raw; return parse(Map<String, dynamic>.from(value as Map)); }
  Future<void> _void(String name, Map<String, dynamic> params) async { await _rpc(name, params); }
  Future<Object?> _rpc(String name, Map<String, dynamic> params) async {
    try { return await _client.rpc(name, params: params); }
    catch (error) {
      final message = error.toString().toLowerCase();
      for (final key in const ['admin_permission_denied','admin_reason_required','listing_not_found','listing_review_closed','listing_review_decision_invalid','listing_limit_reached','category_not_found','order_not_found','order_transition_invalid','order_not_refundable','order_refund_window','admin_note_invalid','promo_code_invalid','promo_code_expired','promo_code_exhausted','promo_code_already_used','promo_code_currency_mismatch','promo_code_format_invalid','promo_credit_invalid','promo_currency_invalid','promo_max_invalid','promo_dates_invalid','promo_code_exists','promo_code_locked','promo_code_not_found','promo_status_invalid','report_range_invalid','ads_account_not_found','ads_account_closed','ads_permission_denied']) {
        if (message.contains(key)) throw AppException('p42.errors.$key');
      }
      throw ErrorMapper.fromSupabase(error);
    }
  }
  String? _text(String? value) => value == null || value.trim().isEmpty ? null : value.trim();
  String _dateOnly(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}