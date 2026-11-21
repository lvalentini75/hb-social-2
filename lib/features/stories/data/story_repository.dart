import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/stories/domain/story.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StoryRepository {
  final SupabaseClient _client;

  const StoryRepository(this._client);

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<StoryTrayItem>> tray() async {
    try {
      final rows = await _client.rpc('stories_tray');
      return (rows as List).map((row) => StoryTrayItem.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<StoryViewerData> storiesForAuthor(String authorId) async {
    try {
      final rows = await _client.from('stories').select('id,author_id,media_path,thumbnail_path,kind,caption,expires_at,view_count,created_at,author:user_profiles!author_id(id,username,display_name,avatar_url,verification_level)').eq('author_id', authorId).eq('status', 'active').gt('expires_at', DateTime.now().toUtc().toIso8601String()).order('created_at', ascending: true);
      final stories = (rows as List).map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        json['media_url'] = storagePublicUrl(_client, 'story-media', json['media_path'] as String?);
        json['thumbnail_url'] = storagePublicUrl(_client, 'story-media', json['thumbnail_path'] as String?);
        return Story.fromJson(json);
      }).toList();
      if (_client.auth.currentUser == null || _client.auth.currentUser?.id == authorId || stories.isEmpty) return StoryViewerData(stories: stories, viewedStoryIds: const {});
      final views = await _client.from('story_views').select('story_id').inFilter('story_id', stories.map((story) => story.id).toList());
      return StoryViewerData(stories: stories, viewedStoryIds: (views as List).map((row) => (row as Map)['story_id'] as String).toSet());
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> publish({required String countryCode, required String kind, required String path, String? thumbnailPath, String? caption}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AppException('errors.login_required');
    try {
      await _client.from('stories').insert({'author_id': user.id, 'media_path': path, 'thumbnail_path': thumbnailPath, 'kind': kind, 'caption': caption?.trim().isEmpty == true ? null : caption?.trim(), 'country_code': countryCode});
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> markViewed(String storyId) async {
    try {
      await _client.rpc('mark_story_viewed', params: {'p_story_id': storyId});
    } catch (_) {}
  }

  Future<List<StoryViewerProfile>> viewers(String storyId) async {
    try {
      final rows = await _client.from('story_views').select('viewed_at,viewer:user_profiles!viewer_id(id,username,display_name,avatar_url,verification_level)').eq('story_id', storyId).order('viewed_at', ascending: false);
      return (rows as List).map((row) => StoryViewerProfile.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> deleteStory(Story story, MediaUploadService media) async {
    try {
      await _client.from('stories').delete().eq('id', story.id);
      try { await media.delete('story-media', story.mediaPath); } catch (_) {}
      try { await media.delete('story-media', story.thumbnailPath); } catch (_) {}
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<StoryHighlight>> highlights(String ownerId) async {
    try {
      final rows = await _client.from('story_highlights').select('id,owner_id,title,cover_path,story_count,sort_order,items:story_highlight_items(sort_order,story:stories(id,media_path,thumbnail_path,kind,caption,created_at,expires_at))').eq('owner_id', ownerId).order('sort_order').order('created_at');
      return (rows as List).map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        final items = (json['items'] as List? ?? const []).map((item) {
          final itemJson = Map<String, dynamic>.from(item as Map);
          final story = Map<String, dynamic>.from(itemJson['story'] as Map);
          return HighlightStory(id: story['id'] as String, mediaPath: story['media_path'] as String, mediaUrl: storagePublicUrl(_client, 'story-media', story['media_path'] as String?), kind: story['kind'] as String, caption: story['caption'] as String?, createdAt: DateTime.parse(story['created_at'] as String).toUtc(), expiresAt: DateTime.parse(story['expires_at'] as String).toUtc(), sortOrder: (itemJson['sort_order'] as num?)?.toInt() ?? 0, thumbnailPath: story['thumbnail_path'] as String?, thumbnailUrl: storagePublicUrl(_client, 'story-media', story['thumbnail_path'] as String?));
        }).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final coverPath = json['cover_path'] as String?;
        return StoryHighlight(id: json['id'] as String, ownerId: json['owner_id'] as String, title: json['title'] as String, coverPath: coverPath, coverUrl: coverPath == null ? null : storagePublicUrl(_client, 'story-media', coverPath), storyCount: (json['story_count'] as num?)?.toInt() ?? items.length, sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0, stories: items);
      }).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<HighlightStory>> myStories() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AppException('errors.login_required');
    try {
      final rows = await _client.from('stories').select('id,media_path,thumbnail_path,kind,caption,created_at,expires_at').eq('author_id', user.id).neq('status', 'removed').order('created_at', ascending: false);
      return (rows as List).map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        return HighlightStory(id: json['id'] as String, mediaPath: json['media_path'] as String, mediaUrl: storagePublicUrl(_client, 'story-media', json['media_path'] as String?), kind: json['kind'] as String, caption: json['caption'] as String?, createdAt: DateTime.parse(json['created_at'] as String).toUtc(), expiresAt: DateTime.parse(json['expires_at'] as String).toUtc(), sortOrder: 0, thumbnailPath: json['thumbnail_path'] as String?, thumbnailUrl: storagePublicUrl(_client, 'story-media', json['thumbnail_path'] as String?));
      }).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<String> createHighlight(String title, List<String> storyIds) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AppException('errors.login_required');
    if (title.trim().isEmpty || title.trim().length > 40) throw const AppException('story_highlights.title_error');
    if (storyIds.isEmpty) throw const AppException('story_highlights.selection_error');
    final id = const Uuid().v4();
    try {
      await _client.from('story_highlights').insert({'id': id, 'owner_id': user.id, 'title': title.trim()});
      await _client.from('story_highlight_items').insert([for (var index = 0; index < storyIds.length; index++) {'highlight_id': id, 'story_id': storyIds[index], 'sort_order': index}]);
      return id;
    } catch (error) {
      try { await _client.from('story_highlights').delete().eq('id', id); } catch (_) {}
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> renameHighlight(String id, String title) async {
    if (title.trim().isEmpty || title.trim().length > 40) throw const AppException('story_highlights.title_error');
    try { await _client.from('story_highlights').update({'title': title.trim()}).eq('id', id); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> updateHighlightStories(String id, List<String> storyIds) async {
    if (storyIds.isEmpty) throw const AppException('story_highlights.selection_error');
    try {
      await _client.from('story_highlight_items').delete().eq('highlight_id', id);
      await _client.from('story_highlight_items').insert([for (var index = 0; index < storyIds.length; index++) {'highlight_id': id, 'story_id': storyIds[index], 'sort_order': index}]);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> addStoryToHighlight(String highlightId, String storyId) async {
    try {
      final rows = await _client.from('story_highlight_items').select('sort_order').eq('highlight_id', highlightId).order('sort_order', ascending: false).limit(1);
      final nextOrder = (rows as List).isEmpty ? 0 : (((rows.first as Map)['sort_order'] as num?)?.toInt() ?? 0) + 1;
      await _client.from('story_highlight_items').insert({'highlight_id': highlightId, 'story_id': storyId, 'sort_order': nextOrder});
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> deleteHighlight(String id) async {
    try { await _client.from('story_highlights').delete().eq('id', id); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }
}