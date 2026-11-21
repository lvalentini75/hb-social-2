import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/marketplace/domain/listing.dart';
import 'package:hb_social/features/marketplace/domain/marketplace_category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketplaceRepository {
  static const pageSize = 20;
  final SupabaseClient _client;
  const MarketplaceRepository(this._client);

  Future<List<MarketplaceCategory>> fetchCategories({required String country}) async { try { final rows = await _client.rpc('marketplace_categories', params: {'p_country': country}); return (rows as List).map((row) => MarketplaceCategory.fromJson(Map<String, dynamic>.from(row as Map))).where((item) => item.available).toList(); } catch (error) { throw ErrorMapper.fromSupabase(error); } }

  Future<List<Listing>> browse({required String country, String? categoryId, String? regionId, String? municipalityId, double? lat, double? lng, int? radiusKm, int? priceMinMinor, int? priceMaxMinor, String? currency, List<ListingCondition> conditions = const [], bool? shipping, String? query, String? sellerId, String sort = 'recent', int offset = 0}) async {
    try {
      final rows = await _client.rpc('browse_listings', params: {'p_country': country, 'p_category_id': categoryId, 'p_region_id': regionId, 'p_municipality_id': municipalityId, 'p_lat': lat, 'p_lng': lng, 'p_radius_km': radiusKm, 'p_price_min_minor': priceMinMinor, 'p_price_max_minor': priceMaxMinor, 'p_currency': currency, 'p_conditions': conditions.isEmpty ? null : conditions.map((item) => item.code).toList(), 'p_shipping': shipping, 'p_q': query?.trim().isEmpty == true ? null : query?.trim(), 'p_seller_id': sellerId, 'p_sort': sort, 'p_limit': pageSize, 'p_offset': offset});
      return (rows as List).map((row) => _listing(Map<String, dynamic>.from(row as Map))).toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<ListingDetailResponse> detailResponse(String id, {String? currency, required String country}) async { try { final value = await _client.rpc('listing_detail', params: {'p_id': id, 'p_currency': currency, 'p_country': country}); if (value == null) throw const AppException('marketplace.errors.not_found'); final json = Map<String, dynamic>.from(value as Map); return json['unavailable_reason'] == 'firearms_country_disabled' ? ListingDetailResponse.unavailable(FirearmsUnavailable.fromJson(json)) : ListingDetailResponse.detail(_detail(json)); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<ListingDetail> detail(String id, {String? currency, required String country}) async { final response = await detailResponse(id, currency: currency, country: country); if (response.detail == null) throw const AppException('marketplace.errors.category_disabled'); return response.detail!; }
  Future<bool> toggleFavorite(String id) async { try { return await _client.rpc('toggle_listing_favorite', params: {'p_id': id}) as bool; } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<void> recordView(String id) async { try { await _client.rpc('record_listing_view', params: {'p_id': id}); } catch (_) {} }
  Future<String> contactSeller(String id, {String? message}) async { try { return (await _client.rpc('contact_seller', params: {'p_listing_id': id, 'p_message': message})).toString(); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<SellerSummary> sellerProfile(String userId) async { try { final value = await _client.rpc('seller_profile', params: {'p_user': userId}); if (value == null) throw const AppException('marketplace.errors.seller_not_found'); return _seller(Map<String, dynamic>.from(value as Map)); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<List<SellerReview>> sellerReviews(String userId, {int offset = 0}) async { try { final rows = await _client.rpc('seller_reviews_of', params: {'p_user': userId, 'p_limit': pageSize, 'p_offset': offset}); return (rows as List).map((row) => _review(Map<String, dynamic>.from(row as Map))).toList(); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<List<Listing>> myFavorites({int offset = 0}) async { try { final rows = await _client.rpc('my_favorite_listings', params: {'p_limit': pageSize, 'p_offset': offset}); return (rows as List).map((row) => _listing(Map<String, dynamic>.from(row as Map))).toList(); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<String> upsertReview({required String listingId, required int rating, String? comment}) async { try { return (await _client.rpc('upsert_seller_review', params: {'p_listing_id': listingId, 'p_rating': rating, 'p_comment': comment?.trim().isEmpty == true ? null : comment?.trim()})).toString(); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<void> replyReview(String id, String reply) async { try { await _client.rpc('reply_seller_review', params: {'p_id': id, 'p_reply': reply.trim()}); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<void> deleteReview(String id) async { try { await _client.rpc('delete_seller_review', params: {'p_id': id}); } catch (error) { throw ErrorMapper.fromSupabase(error); } }

  Future<String> upsertListing({String? id, required String categoryId, required String title, String? description, required int priceMinor, String? currencyCode, required ListingCondition condition, String? regionId, String? municipalityId, double? lat, double? lng, required bool negotiable, required bool shippingAvailable, required Map<String, dynamic> attributes, required ListingStatus status}) async {
    try {
      return (await _client.rpc('upsert_listing', params: {'p_id': id, 'p_category_id': categoryId, 'p_title': title.trim(), 'p_description': description?.trim().isEmpty == true ? null : description?.trim(), 'p_price_minor': priceMinor, 'p_currency_code': currencyCode, 'p_condition': condition.code, 'p_region_id': regionId, 'p_municipality_id': municipalityId, 'p_lat': lat, 'p_lng': lng, 'p_negotiable': negotiable, 'p_shipping_available': shippingAvailable, 'p_attributes': attributes, 'p_status': status == ListingStatus.draft ? 'draft' : 'active'})).toString();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<String>> setListingMedia(String listingId, List<String> paths) async { try { final value = await _client.rpc('set_listing_media', params: {'p_listing_id': listingId, 'p_items': paths.map((path) => {'path': path}).toList()}); return (value as List? ?? const []).map((item) => item.toString()).toList(); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<void> setStatus(String id, ListingStatus status) async { try { await _client.rpc('set_listing_status', params: {'p_id': id, 'p_status': status.name}); } catch (error) { throw ErrorMapper.fromSupabase(error); } }
  Future<DateTime?> renew(String id) async { try { final value = await _client.rpc('renew_listing', params: {'p_id': id}); return DateTime.tryParse(value?.toString() ?? '')?.toUtc(); } catch (error) { throw ErrorMapper.fromSupabase(error); } }

  Future<List<MyListing>> myListings(ListingStatus status, {int offset = 0}) async {
    try { final rows = await _client.rpc('my_listings', params: {'p_status': status.code, 'p_limit': pageSize, 'p_offset': offset}); return (rows as List).map((row) { final value = Map<String, dynamic>.from(row as Map); if (value['media_path'] != null) value['media_path'] = storagePublicUrl(_client, 'listing-media', value['media_path'] as String?); return MyListing.fromJson(value); }).toList(); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<ListingContact>> contacts(String listingId) async {
    try {
      final rows = await _client.from('listing_contacts').select('user_id,conversation_id,created_at').eq('listing_id', listingId).order('created_at', ascending: false);
      final values = (rows as List).map((row) => Map<String, dynamic>.from(row as Map)).toList();
      final ids = values.map((row) => row['user_id'] as String).toSet().toList();
      final profiles = ids.isEmpty ? const <dynamic>[] : await _client.from('user_profiles').select('id,username,display_name,avatar_url,verification_level').inFilter('id', ids);
      final byId = {for (final row in profiles as List) row['id'] as String: Map<String, dynamic>.from(row as Map)};
      return values.map((row) { final user = byId[row['user_id']] ?? <String, dynamic>{'id': row['user_id']}; if (user['avatar_url'] != null) user['avatar_url'] = storagePublicUrl(_client, 'avatars', user['avatar_url'] as String?); return ListingContact.fromJson({...row, 'user': user}); }).toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Listing _listing(Map<String, dynamic> json) { final value = Map<String, dynamic>.from(json); if (value['media_path'] != null) value['media_path'] = storagePublicUrl(_client, 'listing-media', value['media_path'] as String?); _avatar(value); return Listing.fromJson(value); }
  ListingDetail _detail(Map<String, dynamic> json) { final value = Map<String, dynamic>.from(json); value['media'] = ((value['media'] as List?) ?? const []).map((item) { final media = Map<String, dynamic>.from(item as Map); media['storage_path'] = media['path']; media['path'] = storagePublicUrl(_client, 'listing-media', media['path'] as String?) ?? ''; return media; }).toList(); _avatar(value); value['similar'] = ((value['similar'] as List?) ?? const []).map((item) { final listing = Map<String, dynamic>.from(item as Map); if (listing['media_path'] != null) listing['media_path'] = storagePublicUrl(_client, 'listing-media', listing['media_path'] as String?); _avatar(listing); return listing; }).toList(); return ListingDetail.fromJson(value); }
  SellerSummary _seller(Map<String, dynamic> json) { final value = Map<String, dynamic>.from(json); if (value['avatar_url'] != null) value['avatar_url'] = storagePublicUrl(_client, 'avatars', value['avatar_url'] as String?); return SellerSummary.fromJson(value); }
  SellerReview _review(Map<String, dynamic> json) { final value = Map<String, dynamic>.from(json); final reviewer = Map<String, dynamic>.from((value['reviewer'] as Map?) ?? const {}); if (reviewer['avatar_url'] != null) reviewer['avatar_url'] = storagePublicUrl(_client, 'avatars', reviewer['avatar_url'] as String?); value['reviewer'] = reviewer; return SellerReview.fromJson(value); }
  void _avatar(Map<String, dynamic> json) { final seller = Map<String, dynamic>.from((json['seller'] as Map?) ?? const {}); if (seller['avatar_url'] != null) seller['avatar_url'] = storagePublicUrl(_client, 'avatars', seller['avatar_url'] as String?); json['seller'] = seller; }
}