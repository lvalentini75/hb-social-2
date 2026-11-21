import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class FeatureFlagsService {
  static const _anonymousKey = 'hb_feature_flag_anonymous_key';
  static const _unreleased = {'reels', 'live', 'calls', 'auto_translation'};
  final SupabaseClient _client;
  Map<String, bool> _flags = const {};

  FeatureFlagsService(this._client);

  bool isEnabled(String module) => _flags[module] ?? false;
  Map<String, bool> get values => Map.unmodifiable(_flags);

  Future<Map<String, bool>> refresh({String? countryCode}) async {
    try {
      final signedIn = _client.auth.currentUser != null;
      final preferences = await SharedPreferences.getInstance();
      var anonymousKey = preferences.getString(_anonymousKey);
      if (!signedIn && anonymousKey == null) {
        anonymousKey = const Uuid().v4();
        await preferences.setString(_anonymousKey, anonymousKey);
      }
      final deviceCountry = countryCode ?? WidgetsBinding.instance.platformDispatcher.locale.countryCode;
      final raw = await _client.rpc('my_feature_flags', params: {'p_country': deviceCountry?.toUpperCase(), 'p_key': signedIn ? null : anonymousKey});
      final value = raw is List && raw.isNotEmpty ? raw.first : raw;
      final map = Map<String, dynamic>.from(value as Map? ?? const {});
      _flags = {for (final entry in map.entries) entry.key: entry.value == true};
    } catch (_) {
      _flags = {..._flags, for (final module in _unreleased) module: false};
    }
    return values;
  }
}