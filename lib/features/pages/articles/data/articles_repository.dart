import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/pages/articles/domain/article.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArticlesRepository {
  final SupabaseClient _client;
  const ArticlesRepository(this._client);

  Future<List<PageArticle>> byPage(String pageId, {String status = 'published', int limit = 20, int offset = 0}) async {
    try {
      final rows = await _client.rpc('articles_by_page', params: {'p_page_id': pageId, 'p_status': status, 'p_limit': limit, 'p_offset': offset});
      return [for (final row in rows as List) _article(Map<String, dynamic>.from(row as Map))];
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<Map<String, PageArticle>> byIds(List<String> ids) async {
    if (ids.isEmpty) return const {};
    try {
      final rows = await _client.from('articles').select('id,page_id,slug,title,subtitle,cover_path,status,scheduled_at,published_at,post_id,reading_time_min,view_count,created_at,updated_at,page:pages!page_id(id,slug,name,avatar_url,verification_status),author:user_profiles!author_id(id,username,display_name),post:posts!post_id(reaction_count,comment_count,share_count)').inFilter('id', ids);
      return {for (final row in rows as List) (row as Map)['id'].toString(): _article(Map<String, dynamic>.from(row))};
    } catch (_) {
      return const {};
    }
  }

  Future<PageArticle?> detail({String? id, String? pageSlug, String? slug}) async {
    try {
      final params = <String, dynamic>{'p_id': id, 'p_page_slug': pageSlug, 'p_slug': slug};
      final result = await _client.rpc('article_detail', params: params);
      if (result == null || result is List && result.isEmpty) return null;
      final row = result is List ? result.first : result;
      return _article(Map<String, dynamic>.from(row as Map));
    } catch (error) {
      final mapped = ErrorMapper.fromSupabase(error);
      if (mapped.messageKey == 'articles.errors.article_not_found') return null;
      throw mapped;
    }
  }

  Future<String> upsert({String? id, required String pageId, required String title, String? subtitle, String? coverPath, required String body, String? slug}) async {
    try {
      final result = await _client.rpc('article_upsert', params: {'p_id': id, 'p_page_id': pageId, 'p_title': title.trim(), 'p_subtitle': subtitle?.trim().isEmpty == true ? null : subtitle?.trim(), 'p_cover_path': coverPath, 'p_body': body, 'p_slug': slug?.trim().isEmpty == true ? null : slug?.trim()});
      return result.toString();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> publish(String id, {DateTime? scheduledAt}) => _rpc('article_publish', {'p_id': id, 'p_scheduled_at': scheduledAt?.toUtc().toIso8601String()});
  Future<void> unpublish(String id, {required bool archive}) => _rpc('article_unpublish', {'p_id': id, 'p_archive': archive});
  Future<void> delete(String id) => _rpc('article_delete', {'p_id': id});
  Future<void> recordView(String id) => _rpc('record_article_view', {'p_id': id});

  Future<void> _rpc(String name, Map<String, dynamic> params) async {
    try { await _client.rpc(name, params: params); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  PageArticle _article(Map<String, dynamic> json) {
    json['cover_url'] = storagePublicUrl(_client, 'page-media', json['cover_path'] as String?);
    if (json['page'] is Map) {
      final page = Map<String, dynamic>.from(json['page'] as Map);
      page['avatar_url'] = storagePublicUrl(_client, 'page-media', page['avatar_url'] as String?);
      json['page'] = page;
    }
    return PageArticle.fromJson(json);
  }
}