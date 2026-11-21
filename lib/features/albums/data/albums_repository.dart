import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/albums/domain/album.dart';
import 'package:hb_social/features/albums/domain/album_media.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlbumsRepository {
  static const select = '*,cover:album_media!cover_media_id(id,path,kind,width,height,duration_ms,thumbnail_path,size_bytes,sort_order,created_at),owner:user_profiles!owner_id(id,username,display_name,avatar_url,verification_level)';
  final SupabaseClient _client;
  const AlbumsRepository(this._client);

  Future<List<Album>> fetchByOwner(String ownerId) async {
    try { final rows = await _client.from('albums').select(select).eq('owner_id', ownerId).order('updated_at', ascending: false).limit(50); return (rows as List).map((row) => _album(row as Object)).toList(); }
    catch (error) { throw _map(error); }
  }

  Future<Album?> getById(String id) async {
    try { final row = await _client.from('albums').select(select).eq('id', id).maybeSingle(); return row == null ? null : _album(row); }
    catch (error) { throw _map(error); }
  }

  Future<List<AlbumMedia>> fetchMedia(String albumId, {int offset = 0, int limit = 60}) async {
    try { final rows = await _client.from('album_media').select().eq('album_id', albumId).order('sort_order').order('created_at').range(offset, offset + limit - 1); return (rows as List).map((row) => AlbumMedia.fromJson(Map<String, dynamic>.from(row as Map))).toList(); }
    catch (error) { throw _map(error); }
  }

  Future<String> createAlbum({required String title, String? description, required AlbumVisibility visibility}) async {
    try { return (await _client.rpc('create_album', params: {'p_title': title, 'p_description': description, 'p_visibility': visibility.name})).toString(); }
    catch (error) { throw _map(error); }
  }

  Future<void> updateAlbum(String id, {required String title, String? description, required AlbumVisibility visibility}) async {
    try { await _client.rpc('update_album', params: {'p_album_id': id, 'p_title': title, 'p_description': description, 'p_visibility': visibility.name}); }
    catch (error) { throw _map(error); }
  }

  Future<void> deleteAlbum(String id) async {
    try { final value = await _client.rpc('delete_album', params: {'p_album_id': id}); final paths = _paths(value); if (paths.isNotEmpty) { try { await _client.storage.from('album-media').remove(paths); } catch (_) {} } }
    catch (error) { throw _map(error); }
  }

  Future<List<String>> addMedia(String albumId, List<AlbumMedia> items) async {
    try { final value = await _client.rpc('add_album_media', params: {'p_album_id': albumId, 'p_items': items.map((item) => item.toRpcJson()).toList()}); return value is List ? value.map((id) => id is Map ? id.values.first.toString() : id.toString()).toList() : const []; }
    catch (error) { throw _map(error); }
  }

  Future<void> updateMedia(String mediaId, {String? caption, DateTime? takenAt}) async {
    try { await _client.rpc('update_album_media', params: {'p_media_id': mediaId, 'p_caption': caption, 'p_taken_at': takenAt?.toUtc().toIso8601String()}); }
    catch (error) { throw _map(error); }
  }

  Future<void> removeMedia(String mediaId) async {
    try { final value = await _client.rpc('remove_album_media', params: {'p_media_id': mediaId}); final paths = _paths(value); if (paths.isNotEmpty) { try { await _client.storage.from('album-media').remove(paths); } catch (_) {} } }
    catch (error) { throw _map(error); }
  }

  Future<void> setCover(String albumId, String mediaId, {String? coverPath}) async {
    try {
      final previous = (await _client.rpc('set_album_cover', params: {'p_album_id': albumId, 'p_media_id': mediaId, 'p_cover_path': coverPath}))?.toString();
      if (previous?.isNotEmpty == true && previous != coverPath) { try { await _client.storage.from('album-media').remove([previous!]); } catch (_) {} }
    } catch (error) { throw _map(error); }
  }
  Future<void> reorder(String albumId, List<String> mediaIds) async { try { await _client.rpc('reorder_album_media', params: {'p_album_id': albumId, 'p_media_ids': mediaIds}); } catch (error) { throw _map(error); } }

  Album _album(Object raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    if (json['owner'] is Map) { final owner = Map<String, dynamic>.from(json['owner'] as Map); owner['avatar_url'] = storagePublicUrl(_client, 'avatars', owner['avatar_url'] as String?); json['owner'] = owner; }
    return Album.fromJson(json);
  }

  List<String> _paths(Object? value) => value is List ? value.map((path) => path.toString()).where((path) => path.isNotEmpty).toList() : const [];
  AppException _map(Object error) {
    final message = error.toString().toLowerCase();
    const keys = {'album_title_invalid', 'album_description_too_long', 'album_visibility_invalid', 'album_not_found', 'album_media_not_found', 'album_permission_denied', 'album_full', 'album_media_too_many', 'album_media_kind_invalid', 'album_media_path_invalid', 'album_media_caption_too_long'};
    for (final key in keys) { if (message.contains(key)) return AppException('albums.errors.$key'); }
    if (message.contains('content_blocked')) return const AppException('albums.errors.content_blocked');
    if (message.contains('not_authenticated')) return const AppException('errors.login_required');
    return ErrorMapper.fromSupabase(error);
  }
}