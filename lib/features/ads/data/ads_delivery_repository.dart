import 'package:flutter/widgets.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/ads/domain/ad_delivery.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AdsDeliveryRepository {
  static const _viewerKeyPreference = 'ads_guest_viewer_key';
  final SupabaseClient _client;
  final SharedPreferences _preferences;
  final Map<AdPlacement, Set<String>> _shown = {};
  final Set<String> _impressed = {};
  String? _sessionUserId;
  AdsDeliveryRepository(this._client, this._preferences);

  Future<List<DeliveredAd>> adsForPlacement(AdPlacement placement, int count, Map<String, dynamic> context) async => _guard(() async {
    _resetForUserChange();
    final guest = _client.auth.currentUser == null;
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final enriched = <String, dynamic>{...context, 'locale': locale.languageCode, 'exclude': _shown[placement]?.toList() ?? const []};
    if (guest) enriched['country_code'] = locale.countryCode ?? 'IT';
    final rows = await _client.rpc('ads_for_placement', params: {'p_placement': placement.code, 'p_count': count.clamp(1, 10), 'p_viewer_key': guest ? await _viewerKey() : null, 'p_context': enriched});
    final values = rows is List ? rows : rows is Map && rows['items'] is List ? rows['items'] as List : const [];
    final ads = [for (final row in values.whereType<Map>()) DeliveredAd.fromJson(Map<String, dynamic>.from(row))];
    _shown.putIfAbsent(placement, () => <String>{}).addAll(ads.map((item) => item.adId));
    return ads;
  });

  Future<void> recordImpression(String adId, AdPlacement placement) async {
    if (!_impressed.add(adId)) return;
    try { await _event(adId, 'impression', placement); } catch (_) { _impressed.remove(adId); rethrow; }
  }
  Future<void> recordClick(String adId, AdPlacement placement) => _event(adId, 'click', placement);
  Future<void> _event(String adId, String kind, AdPlacement placement) async => _guard(() async { final guest = _client.auth.currentUser == null; await _client.rpc('record_ad_event', params: {'p_ad_id': adId, 'p_kind': kind, 'p_placement': placement.code, 'p_viewer_key': guest ? await _viewerKey() : null}); });
  Future<String> hideAd(String adId, {required String scope, String? reason}) => _guard(() async => (await _client.rpc('hide_ad', params: {'p_ad_id': adId, 'p_scope': scope, 'p_reason': reason})).toString());
  Future<void> unhideAd(String id) => _guard(() async { await _client.rpc('unhide_ad', params: {'p_id': id}); });
  Future<List<HiddenAd>> myHiddenAds() => _guard(() async => [for (final row in await _client.rpc('my_hidden_ads') as List) HiddenAd.fromJson(Map<String, dynamic>.from(row as Map))]);
  Future<void> setPersonalized(bool enabled) => _guard(() async { await _client.rpc('set_ads_personalized', params: {'p_enabled': enabled}); });
  Future<AdsPreferences> myPreferences() => _guard(() async { final value = await _client.rpc('my_ads_preferences'); final map = value is List ? Map<String, dynamic>.from(value.first as Map) : Map<String, dynamic>.from(value as Map); return AdsPreferences.fromJson(map); });

  Future<String> _viewerKey() async {
    final existing = _preferences.getString(_viewerKeyPreference);
    if (existing != null && existing.isNotEmpty) return existing;
    final value = const Uuid().v4();
    await _preferences.setString(_viewerKeyPreference, value);
    return value;
  }
  void _resetForUserChange() { final next = _client.auth.currentUser?.id; if (_sessionUserId == next) return; _sessionUserId = next; _shown.clear(); _impressed.clear(); }
  Future<T> _guard<T>(Future<T> Function() action) async { try { return await action(); } catch (error) { final text = error.toString().toLowerCase(); for (final key in const ['ads_placement_invalid','ads_hide_scope_invalid','ads_hide_reason_invalid','ads_ad_not_found','ads_hidden_not_found','report_target_type_invalid','report_own_content','not_authenticated']) { if (text.contains(key)) throw AppException('ads.delivery.errors.$key'); } throw ErrorMapper.fromSupabase(error); } }
}