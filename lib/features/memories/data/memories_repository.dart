import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/memories/domain/memory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemoriesRepository {
  final SupabaseClient _client;
  const MemoriesRepository(this._client);
  Future<List<MemoryItem>> today() async {
    try {
      final rows = await _client.rpc('memories_today', params: {'p_date': null});
      final items = <MemoryItem>[];
      for (final raw in rows as List) {
        final row = Map<String, dynamic>.from(raw as Map);
        final bucket = row['item_type'] == 'post' ? 'post-media' : 'diary-media';
        if (row['media_path'] is String) row['media_path'] = bucket == 'post-media' ? storagePublicUrl(_client, bucket, row['media_path'] as String?) : await _client.storage.from(bucket).createSignedUrl(row['media_path'] as String, 3600);
        if (row['thumbnail_path'] is String) row['thumbnail_path'] = bucket == 'post-media' ? storagePublicUrl(_client, bucket, row['thumbnail_path'] as String?) : await _client.storage.from(bucket).createSignedUrl(row['thumbnail_path'] as String, 3600);
        items.add(MemoryItem.fromJson(row));
      }
      return items;
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }
  Future<void> dismiss(MemoryItem item) async {
    try { await _client.rpc('memory_dismiss', params: {'p_item_type': item.itemType, 'p_item_id': item.itemId}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }
}