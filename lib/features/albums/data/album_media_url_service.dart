import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlbumMediaUrlService {
  final SupabaseClient _client;
  final Map<String, ({String url, DateTime expiresAt})> _cache = {};
  final Map<String, Future<String?>> _pending = {};

  AlbumMediaUrlService(this._client);

  Future<Map<String, String>> signedUrls(List<String> paths) async {
    final unique = paths.where((path) => path.isNotEmpty).toSet();
    final result = <String, String>{};
    final missing = <String>[];
    final now = DateTime.now();
    for (final path in unique) {
      final cached = _cache[path];
      if (cached != null && cached.expiresAt.isAfter(now)) result[path] = cached.url; else missing.add(path);
    }
    try {
      final fresh = missing.where((path) => !_pending.containsKey(path)).toList();
      for (var start = 0; start < fresh.length; start += 50) {
        final batch = fresh.sublist(start, (start + 50).clamp(0, fresh.length));
        final completers = {for (final path in batch) path: Completer<String?>()};
        for (final entry in completers.entries) { _pending[entry.key] = entry.value.future; }
        try {
          final dynamic signed = await _client.storage.from('album-media').createSignedUrls(batch, 3600);
          final urls = <String, String>{};
          for (final dynamic item in signed as List) { if (item.signedUrl != null) urls[item.path as String] = item.signedUrl as String; }
          for (final path in batch) {
            final url = urls[path];
            if (url != null) _cache[path] = (url: url, expiresAt: DateTime.now().add(const Duration(minutes: 55)));
            completers[path]!.complete(url);
          }
        } catch (error, stackTrace) {
          for (final completer in completers.values) { completer.completeError(error, stackTrace); }
        }
      }
      await Future.wait(missing.map((path) async { final url = await _pending[path]; if (url != null) result[path] = url; }));
      for (final path in missing) { _pending.remove(path); }
      return result;
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  void evict(Iterable<String> paths) { for (final path in paths) { _cache.remove(path); } }

  Future<Uint8List> download(String path) async {
    final urls = await signedUrls([path]);
    final url = urls[path];
    if (url == null) throw const AppException('errors.file_unreadable');
    try { final response = await Dio().get<List<int>>(url, options: Options(responseType: ResponseType.bytes)); return Uint8List.fromList(response.data ?? const []); }
    catch (_) { throw const AppException('errors.file_unreadable'); }
  }
}