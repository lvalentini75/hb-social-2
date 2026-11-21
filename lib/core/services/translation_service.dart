import 'dart:async';

import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum TranslationStatus { cached, sameLanguage, denied, error }

class ContentTranslation {
  final TranslationStatus status;
  final String targetLanguage;
  final String sourceLanguage;
  final Map<String, String> fields;
  final String? reason;

  const ContentTranslation({required this.status, required this.targetLanguage, required this.sourceLanguage, this.fields = const {}, this.reason});

  factory ContentTranslation.fromJson(Map<String, dynamic> json) => ContentTranslation(
    status: _status(json['status']?.toString()),
    targetLanguage: json['target_lang']?.toString() ?? '',
    sourceLanguage: json['source_lang']?.toString() ?? '',
    fields: {for (final entry in Map<String, dynamic>.from(json['fields'] as Map? ?? const {}).entries) if (entry.value != null) entry.key: entry.value.toString()},
    reason: json['reason']?.toString(),
  );

  String? field(String name) => fields[name];
}

class TranslationUsage {
  final int todayCharacters;
  final int dailyLimit;
  final bool autoTranslate;
  final bool enabled;

  const TranslationUsage({required this.todayCharacters, required this.dailyLimit, required this.autoTranslate, required this.enabled});
  factory TranslationUsage.fromJson(Map<String, dynamic> json) => TranslationUsage(todayCharacters: (json['today_chars'] as num?)?.toInt() ?? 0, dailyLimit: (json['daily_limit'] as num?)?.toInt() ?? 0, autoTranslate: json['auto_translate'] as bool? ?? true, enabled: json['enabled'] as bool? ?? false);
}

/// Session cache and bounded request queue for shared content translations.
class TranslationService {
  final SupabaseClient _client;
  final String Function() _targetLanguage;
  final Map<String, ContentTranslation> _cache = {};
  final Map<String, Future<ContentTranslation>> _inFlight = {};
  final List<Completer<void>> _waiters = [];
  int _active = 0;

  TranslationService(this._client, this._targetLanguage);

  String _key(String type, String id, [String? target]) => '$type:$id:${target ?? _targetLanguage()}';
  ContentTranslation? cached(String type, String id, {String? target}) => _cache[_key(type, id, target)];

  Future<Map<String, ContentTranslation>> prefetch(String type, Iterable<String> ids, {String? target}) async {
    final language = target ?? _targetLanguage();
    final missing = ids.where((id) => !_cache.containsKey(_key(type, id, language))).toSet().toList();
    if (missing.isNotEmpty) {
      try {
        final rows = await _client.rpc('translations_for', params: {'p_type': type, 'p_ids': missing, 'p_target': language});
        for (final raw in rows as List? ?? const []) {
          final json = Map<String, dynamic>.from(raw as Map);
          final id = json['target_id'].toString();
          _cache[_key(type, id, language)] = ContentTranslation.fromJson({...json, 'target_lang': language});
        }
      } catch (error) {
        throw ErrorMapper.fromSupabase(error);
      }
    }
    return {for (final id in ids) if (cached(type, id, target: language) case final value?) id: value};
  }

  Future<ContentTranslation> translate(String type, String id, {String? target}) {
    final language = target ?? _targetLanguage();
    final key = _key(type, id, language);
    final existing = _cache[key];
    if (existing != null) return Future.value(existing);
    return _inFlight.putIfAbsent(key, () => _queued(() async {
      try {
        final response = await _client.functions.invoke('translate', body: {'action': 'content', 'type': type, 'id': id, 'target': language}, headers: {'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken ?? ''}'});
        final result = ContentTranslation.fromJson(Map<String, dynamic>.from(response.data as Map? ?? const {}));
        _cache[key] = result;
        return result;
      } catch (error) {
        throw ErrorMapper.fromSupabase(error);
      } finally {
        _inFlight.remove(key);
      }
    }));
  }

  Future<TranslationUsage> usage() async {
    try {
      final raw = await _client.rpc('my_translation_usage');
      final value = raw is List && raw.isNotEmpty ? raw.first : raw;
      return TranslationUsage.fromJson(Map<String, dynamic>.from(value as Map? ?? const {}));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  void invalidate(String type, String id) => _cache.removeWhere((key, _) => key.startsWith('$type:$id:'));

  Future<T> _queued<T>(Future<T> Function() action) async {
    if (_active >= 2) { final waiter = Completer<void>(); _waiters.add(waiter); await waiter.future; }
    _active++;
    try { return await action(); }
    finally { _active--; if (_waiters.isNotEmpty) _waiters.removeAt(0).complete(); }
  }
}

TranslationStatus _status(String? value) => switch (value) {
  'cached' => TranslationStatus.cached,
  'same_language' => TranslationStatus.sameLanguage,
  'denied' => TranslationStatus.denied,
  _ => TranslationStatus.error,
};

String translationReasonKey(String? reason) => switch (reason) {
  'translation_quota_month' || 'translation_quota_user' => 'translate.reason.quota',
  'translation_too_long' => 'translate.reason.too_long',
  'translation_disabled' || 'feature_disabled' || 'translation_type_disabled' || 'translation_not_configured' => 'translate.reason.unavailable',
  _ => 'translate.error',
};