import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/domain/ad_models.dart';
import 'package:hb_social/features/ads/domain/ad_reports.dart';
import 'package:hb_social/features/ads/domain/boost_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdsRepository {
  static const pageSize = 20;
  static const creativeBucket = 'ads-media';
  final SupabaseClient _client;
  final MediaUploadService _uploads;
  const AdsRepository(this._client, this._uploads);

  Future<List<AdAccount>> accounts() async => _guard(() async {
    final rows = await _client.rpc('my_ad_accounts');
    return _models(rows, AdAccount.fromJson);
  });

  Future<BoostQuote> boostQuote({required String targetType, required String targetId, required int budgetMinor, required int days, required String audience}) => _guard(() async => BoostQuote.fromJson(_json(await _client.rpc('boost_quote', params: {'p_target_type': targetType, 'p_target_id': targetId, 'p_budget_minor': budgetMinor, 'p_days': days, 'p_audience': audience}))));
  Future<BoostResult> createBoost({required String targetType, required String targetId, required int budgetMinor, required int days, required String audience}) => _guard(() async => BoostResult.fromJson(_json(await _client.rpc('create_boost', params: {'p_target_type': targetType, 'p_target_id': targetId, 'p_budget_minor': budgetMinor, 'p_days': days, 'p_audience': audience}))));
  Future<BoostStatus?> boostStatusOf({required String targetType, required String targetId}) => _guard(() async { final value = await _client.rpc('boost_status_of', params: {'p_target_type': targetType, 'p_target_id': targetId}); return value is Map && value.isNotEmpty ? BoostStatus.fromJson(Map<String, dynamic>.from(value)) : null; });
  Future<List<Boost>> myBoosts({int limit = pageSize, int offset = 0}) => _guard(() async => _models(await _client.rpc('my_boosts', params: {'p_limit': limit, 'p_offset': offset}), Boost.fromJson));
  Future<void> stopBoost(String campaignId) => _rpc('stop_boost', {'p_campaign_id': campaignId});

  Future<AdAccount> account(String id) async => _guard(() async {
    final accounts = _models(await _client.rpc('my_ad_accounts'), AdAccount.fromJson);
    return accounts.firstWhere((item) => item.id == id, orElse: () => throw const AppException('ads.errors.permission_denied'));
  });

  Future<List<AdAccountMember>> members(String accountId) async => _guard(() async {
    final rows = await _client.from('ad_account_members').select('*,user:user_profiles!ad_account_members_user_id_fkey(display_name,username,avatar_url)').eq('account_id', accountId).order('created_at');
    return _models(rows, AdAccountMember.fromJson);
  });

  Future<Page<AdCampaign>> campaigns(String accountId, {PageCursor? cursor}) => _page(table: 'ad_campaigns', parentColumn: 'account_id', parentId: accountId, cursor: cursor, parser: AdCampaign.fromJson);
  Future<Page<AdAudience>> audiences(String accountId, {PageCursor? cursor}) => _page(table: 'ad_audiences', parentColumn: 'account_id', parentId: accountId, cursor: cursor, parser: AdAudience.fromJson);
  Future<Page<AdCreative>> creatives(String accountId, {PageCursor? cursor}) => _page(table: 'ad_creatives', parentColumn: 'account_id', parentId: accountId, cursor: cursor, parser: AdCreative.fromJson);
  Future<Page<AdSet>> adSets(String campaignId, {PageCursor? cursor}) => _page(table: 'ad_sets', parentColumn: 'campaign_id', parentId: campaignId, cursor: cursor, parser: AdSet.fromJson);
  Future<Page<AdItem>> ads(String adSetId, {PageCursor? cursor}) => _page(table: 'ads', parentColumn: 'ad_set_id', parentId: adSetId, cursor: cursor, parser: AdItem.fromJson);
  Future<Page<AdBillingCharge>> charges(String accountId, {PageCursor? cursor}) => _page(table: 'ad_charges', parentColumn: 'account_id', parentId: accountId, cursor: cursor, parser: AdBillingCharge.fromJson);

  Future<String> createAccount({required String name, String? pageId}) async => _rpcId('create_ad_account', {'p_name': name, 'p_page_id': pageId});
  Future<void> updateAccount({required String accountId, String? name, String? pageId, AdAccountStatus? status}) async => _rpc('update_ad_account', {'p_id': accountId, 'p_name': name, 'p_page_id': pageId, 'p_status': status?.code});
  Future<void> addMember({required String accountId, required String userId, required AdAccountRole role}) async => _rpc('add_ad_account_member', {'p_account_id': accountId, 'p_user_id': userId, 'p_role': role.code});
  Future<void> setMemberRole({required String accountId, required String userId, required AdAccountRole role}) async => _rpc('set_ad_account_member_role', {'p_account_id': accountId, 'p_user_id': userId, 'p_role': role.code});
  Future<void> removeMember({required String accountId, required String userId}) async => _rpc('remove_ad_account_member', {'p_account_id': accountId, 'p_user_id': userId});

  Future<String> upsertCampaign({required String accountId, String? id, required String name, required AdCampaignObjective objective, required DateTime startsAt, DateTime? endsAt, required int budgetMinor, int? dailyBudgetMinor}) async => _rpcId('upsert_ad_campaign', {'p_account_id': accountId, 'p_id': id, 'p_name': name, 'p_objective': objective.code, 'p_start_at': startsAt.toUtc().toIso8601String(), 'p_end_at': endsAt?.toUtc().toIso8601String(), 'p_total_budget_minor': budgetMinor, 'p_daily_budget_minor': dailyBudgetMinor});
  Future<String> setCampaignStatus(String campaignId, AdCampaignStatus status) async => _guard(() async => (await _client.rpc('set_ad_campaign_status', params: {'p_id': campaignId, 'p_status': status.code})).toString());
  Future<String> upsertAudience({required String accountId, String? id, required String name, required List<String> countryCodes, required List<String> regionIds, required List<String> interests, List<String> speciesIds = const [], List<String> verificationLevels = const [], List<String> locales = const []}) async => _rpcId('upsert_ad_audience', {'p_account_id': accountId, 'p_id': id, 'p_name': name, 'p_country_codes': countryCodes, 'p_region_ids': regionIds, 'p_interests': interests, 'p_species_ids': speciesIds, 'p_verification_levels': verificationLevels, 'p_locales': locales});
  Future<void> deleteAudience(String id) => _rpc('delete_ad_audience', {'p_id': id});
  Future<int> estimateAudience({required List<String> countryCodes, required List<String> regionIds, required List<String> interests, required List<String> speciesIds, required List<String> verificationLevels, required List<String> locales}) => _guard(() async { final value = await _client.rpc('estimate_ad_audience', params: {'p_country_codes': countryCodes, 'p_region_ids': regionIds, 'p_interests': interests, 'p_species_ids': speciesIds, 'p_verification_levels': verificationLevels, 'p_locales': locales}); return (value as num?)?.toInt() ?? 0; });
  Future<String> upsertAdSet({required String campaignId, String? id, required String name, String? audienceId, required List<AdPlacement> placements, required String optimization, required int bidMinor, int? dailyBudgetMinor, required int frequencyCap, required String pacing, DateTime? startsAt, DateTime? endsAt}) async => _rpcId('upsert_ad_set', {'p_campaign_id': campaignId, 'p_id': id, 'p_name': name, 'p_audience_id': audienceId, 'p_placements': placements.map((item) => item.code).toList(), 'p_bid_type': optimization, 'p_bid_minor': bidMinor, 'p_daily_budget_minor': dailyBudgetMinor, 'p_frequency_cap_per_day': frequencyCap, 'p_pacing': pacing, 'p_start_at': startsAt?.toUtc().toIso8601String(), 'p_end_at': endsAt?.toUtc().toIso8601String()});
  Future<String> upsertCreative({required String accountId, String? id, required AdCreativeKind kind, required String headline, required String body, required String callToAction, required String destinationType, String? destinationId, String? destinationUrl, required List<AdCreativeMedia> media}) async => _rpcId('upsert_ad_creative', {'p_account_id': accountId, 'p_id': id, 'p_kind': kind.code, 'p_headline': headline.isEmpty ? null : headline, 'p_body': body.isEmpty ? null : body, 'p_cta': callToAction, 'p_destination_type': destinationType, 'p_destination_id': destinationId, 'p_destination_url': destinationUrl, 'p_media': media.map((item) => item.toJson()).toList()});
  Future<String> upsertAd({required String adSetId, String? id, required String creativeId, required String name, required String status}) async => _rpcId('upsert_ad', {'p_ad_set_id': adSetId, 'p_id': id, 'p_creative_id': creativeId, 'p_name': name, 'p_status': status});

  Future<String> duplicateCampaign(AdCampaign source, String copySuffix) async {
    final campaignId = await upsertCampaign(accountId: source.accountId, name: '${source.name} $copySuffix', objective: source.objective, startsAt: source.startsAt, endsAt: source.endsAt, budgetMinor: source.budgetMinor, dailyBudgetMinor: source.dailyBudgetMinor);
    final sourceSets = (await adSets(source.id)).items;
    for (final sourceSet in sourceSets) {
      final setId = await upsertAdSet(campaignId: campaignId, name: sourceSet.name, audienceId: sourceSet.audienceId, placements: sourceSet.placements, optimization: sourceSet.optimization, bidMinor: sourceSet.bidMinor, dailyBudgetMinor: sourceSet.dailyBudgetMinor, frequencyCap: sourceSet.frequencyCap, pacing: sourceSet.pacing, startsAt: sourceSet.startsAt, endsAt: sourceSet.endsAt);
      for (final sourceAd in (await ads(sourceSet.id)).items) {
        if (sourceAd.status != 'archived') await upsertAd(adSetId: setId, creativeId: sourceAd.creativeId, name: sourceAd.name, status: 'draft');
      }
    }
    return campaignId;
  }

   Future<List<AdCharge>> myAdCharges({int limit = 20, int offset = 0}) async => _guard(() async {
     final rows = await _client.rpc('my_ad_charges', params: {'p_limit': limit, 'p_offset': offset});
     return _models(rows, AdCharge.fromJson);
   });

   Future<void> setAdAccountPaymentMethod(String accountId, String paymentMethodId) async => _rpc('set_ad_account_payment_method', {'p_account_id': accountId, 'p_payment_method_id': paymentMethodId});
   Future<void> setAdAccountSpendCap(String accountId, int? spendCapMinor) async => _rpc('set_ad_account_spend_cap', {'p_account_id': accountId, 'p_spend_cap_minor': spendCapMinor});
   Future<void> retryAdCharge(String chargeId) async => _rpc('retry_ad_charge', {'p_charge_id': chargeId});
   Future<void> grantAdCredit(String accountId, int amountMinor, String note) async => _rpc('grant_ad_credit', {'p_account_id': accountId, 'p_amount_minor': amountMinor, 'p_note': note});
   Future<Map<String, dynamic>> redeemPromoCode(String accountId, String code) => _guard(() async => _json(await _client.rpc('redeem_ad_promo_code', params: {'p_account_id': accountId, 'p_code': code.trim().toUpperCase()})));

   Future<AdCampaignReport?> campaignReport(String campaignId) async => _guard(() async { final value = await _client.rpc('ad_campaign_report', params: {'p_campaign_id': campaignId}); return value is Map ? AdCampaignReport.fromJson(Map<String, dynamic>.from(value)) : null; });
  Future<Map<String, dynamic>> recordEvent({required String adId, required String kind, required AdPlacement placement, String? requestId}) async => _guard(() async => Map<String, dynamic>.from(await _client.rpc('record_ad_event', params: {'p_ad_id': adId, 'p_kind': kind, 'p_placement': placement.code, 'p_request_id': requestId}) as Map));
  Future<Map<String, dynamic>?> creativeDestination(String creativeId) => _guard(() async { final value = await _client.rpc('ad_creative_destination', params: {'p_creative_id': creativeId}); return value is Map ? Map<String, dynamic>.from(value) : null; });
  Future<AdsDashboard> dashboard(int days) => _guard(() async => AdsDashboard.fromJson(_json(await _client.rpc('ads_dashboard', params: {'p_days': days}))));
  Future<AdCampaignAggregateReport?> aggregateCampaignReport(String campaignId, {DateTime? from, DateTime? to}) => _guard(() async { final value = await _client.rpc('ad_campaign_report', params: {'p_campaign_id': campaignId, 'p_from': from?.toUtc().toIso8601String(), 'p_to': to?.toUtc().toIso8601String()}); return value is Map ? AdCampaignAggregateReport.fromJson(Map<String, dynamic>.from(value)) : null; });
  Future<AdAccountReport?> accountReport(String accountId, {DateTime? from, DateTime? to}) => _guard(() async { final value = await _client.rpc('ad_account_report', params: {'p_account_id': accountId, 'p_from': from?.toUtc().toIso8601String(), 'p_to': to?.toUtc().toIso8601String()}); return value is Map ? AdAccountReport.fromJson(Map<String, dynamic>.from(value)) : null; });
  Future<AdAccountBilling?> accountBilling(String accountId, {DateTime? from, DateTime? to}) => _guard(() async { final value = await _client.rpc('ad_account_billing', params: {'p_account_id': accountId, 'p_from': from?.toUtc().toIso8601String(), 'p_to': to?.toUtc().toIso8601String()}); return value is Map ? AdAccountBilling.fromJson(Map<String, dynamic>.from(value)) : null; });
  Future<void> setAdSetStatus(String id, String status) => _rpc('set_ad_set_status', {'p_id': id, 'p_status': status});
  Future<List<AdReviewItem>> reviewQueue(String status, {int limit = 50, int offset = 0}) => _guard(() async => _models(await _client.rpc('ads_review_queue', params: {'p_status': status, 'p_limit': limit, 'p_offset': offset}), AdReviewItem.fromJson));
  Future<void> reviewCreative(String id, String decision, {String? note}) => _rpc('review_ad_creative', {'p_id': id, 'p_decision': decision, 'p_note': note});
  Future<List<Map<String, dynamic>>> destinationOptions(String accountId, String type, {String query = ''}) => _guard(() async {
    final table = switch (type) { 'post' => 'posts', 'listing' => 'listings', 'event' => 'events', 'page' => 'pages', _ => 'user_profiles' };
    final columns = switch (type) { 'post' => 'id,content,created_at', 'listing' => 'id,title,created_at', 'event' => 'id,title,created_at', 'page' => 'id,name,created_at', _ => 'id,display_name,created_at' };
    var request = _client.from(table).select(columns);
    if (query.trim().isNotEmpty) request = request.ilike(type == 'post' ? 'content' : type == 'profile' ? 'display_name' : type == 'page' ? 'name' : 'title', '%${query.trim()}%');
    final rows = await request.order('created_at', ascending: false).limit(20);
    return [for (final row in rows as List) Map<String, dynamic>.from(row as Map)];
  });

  Future<AdCreativeMedia> uploadCreative(PreparedUpload upload, {UploadProgress? progress}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AppException('errors.login_required');
    try {
      final media = await _uploads.uploadToBucket(bucket: creativeBucket, userId: userId, upload: upload, isPublic: true, progress: progress);
      return AdCreativeMedia(path: media.path, kind: upload.mediaKind ?? 'image', width: upload.width, height: upload.height);
    } catch (error) { throw _map(error); }
  }

  Future<Page<T>> _page<T>({required String table, required String parentColumn, required String parentId, PageCursor? cursor, required T Function(Map<String, dynamic>) parser}) => _guard(() async {
    var query = _client.from(table).select().eq(parentColumn, parentId);
    query = applyCursor(query, cursor);
    final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
    final items = _models(rows, parser);
    final last = items.length == pageSize ? Map<String, dynamic>.from((rows as List).last as Map) : null;
    return Page(items: items, nextCursor: last == null ? null : PageCursor(createdAt: DateTime.parse(last['created_at'].toString()).toUtc(), id: last['id'].toString()));
  });

  Future<String> _rpcId(String name, Map<String, dynamic> params) async => _guard(() async => (await _client.rpc(name, params: params)).toString());
  Future<void> _rpc(String name, Map<String, dynamic> params) async => _guard(() async { await _client.rpc(name, params: params); });
  Future<T> _guard<T>(Future<T> Function() action) async { try { return await action(); } catch (error) { throw _map(error); } }
  AppException _map(Object error) {
    if (error is AppException) return error;
    final message = error.toString().toLowerCase();
     for (final key in const ['promo_code_invalid', 'promo_code_expired', 'promo_code_exhausted', 'promo_code_already_used', 'promo_code_currency_mismatch', 'boost_target_not_owned', 'boost_target_not_public', 'boost_target_not_active', 'boost_target_restricted', 'boost_target_invalid', 'boost_active_exists', 'boost_limit_reached', 'boost_budget_invalid', 'boost_duration_invalid', 'boost_audience_invalid', 'ads_campaign_not_found', 'ads_account_limit', 'ads_name_invalid', 'account_suspended', 'ads_member_exists', 'ads_member_limit', 'ads_member_owner_protected', 'ads_member_role_invalid', 'ads_permission_denied', 'user_not_found', 'ads_audience_invalid', 'ads_creative_invalid', 'ads_destination_invalid', 'ads_media_invalid', 'content_blocked', 'ads_bid_invalid', 'ads_budget_invalid', 'ads_dates_invalid', 'ads_placement_invalid', 'ads_frequency_invalid', 'ads_campaign_empty', 'ads_payment_method_required', 'ads_billing_blocked', 'ads_spend_cap_reached', 'ads_spend_cap_invalid', 'ads_transition_invalid', 'ads_review_decision_invalid', 'ads_review_note_required', 'payment_method_not_found', 'payment_method_permission_denied', 'ads_charge_not_found', 'ads_credit_invalid', 'ads_set_not_found', 'ads_ad_not_found']) {
       if (message.contains(key)) return AppException(key.startsWith('promo_') ? 'p42.ads_promo.errors.$key' : key.startsWith('boost_') ? 'boost.errors.$key' : 'ads.errors.$key');
    }
    final mapped = ErrorMapper.fromSupabase(error);
    return mapped.messageKey == 'errors.not_authorized' ? const AppException('ads.errors.ads_permission_denied') : mapped;
  }
  List<T> _models<T>(Object? rows, T Function(Map<String, dynamic>) parser) => [for (final row in rows as List) parser(Map<String, dynamic>.from(row as Map))];
  Map<String, dynamic> _json(Object? value) => value is Map ? Map<String, dynamic>.from(value) : const {};
}