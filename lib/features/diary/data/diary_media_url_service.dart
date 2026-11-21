import 'dart:async';

import 'package:hb_social/core/services/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiaryMediaUrlService {
  final SupabaseClient _client;
  final Map<String, ({String url, DateTime expiresAt})> _cache = {};
  DiaryMediaUrlService(this._client);

  Future<Map<String, String>> createSignedUrls(Iterable<String?> values) async {
    final paths = values.whereType<String>().where((path) => path.isNotEmpty).toSet();
    final result = <String, String>{};
    final missing = <String>[];
    final now = DateTime.now();
    for (final path in paths) {
      final cached = _cache[path];
      if (cached != null && cached.expiresAt.isAfter(now)) result[path] = cached.url; else missing.add(path);
    }
    try {
      for (var start = 0; start < missing.length; start += 50) {
        final batch = missing.sublist(start, (start + 50).clamp(0, missing.length));
        final dynamic signed = await _client.storage.from('diary-media').createSignedUrls(batch, 3600);
        for (final dynamic item in signed as List) {
          if (item.signedUrl == null) continue;
          final path = item.path as String;
          final url = item.signedUrl as String;
          result[path] = url;
          _cache[path] = (url: url, expiresAt: DateTime.now().add(const Duration(minutes: 55)));
        }
      }
      return result;
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  void evict(Iterable<String> paths) { for (final path in paths) { _cache.remove(path); } }
}