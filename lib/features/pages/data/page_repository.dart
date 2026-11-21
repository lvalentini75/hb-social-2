import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/home/data/feed_repository.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:hb_social/features/pages/domain/community_page.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PageRepository {
  static const pageSize = 20;
  final SupabaseClient _client;
  final FeedRepository _feedRepository;

  PageRepository(this._client) : _feedRepository = FeedRepository(_client);

  Future<List<PageCategory>> fetchCategories() async {
    try {
      final rows = await _client.from('categories').select('slug,name_key,sort_order').eq('kind', 'page').order('sort_order');
      return (rows as List).map((row) => PageCategory.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<Page<CommunityPage>> fetchPages({String? category, PageCursor? cursor}) async {
    try {
      var query = _client.from('pages').select('*,region:regions(name)').eq('status', 'active');
      if (category != null) query = query.eq('category', category);
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      return _pageFromRows(rows as List);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<CommunityPage>> fetchMyPages() async {
    try {
      final rows = await _client.rpc('my_pages').select('*,region:regions(name)');
      final pages = <CommunityPage>[];
      for (final row in rows as List) {
        final json = _withMedia(Map<String, dynamic>.from(row as Map));
        json['my_role'] = (await studioSummary(json['id'] as String))?.myRole;
        pages.add(CommunityPage.fromJson(json));
      }
      return pages;
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<CommunityPage>> searchPagesByCategory(String term, String category) async {
    if (term.trim().length < 2) return const [];
    try {
      final rows = await _client.from('pages').select('*,region:regions(name)').eq('status', 'active').eq('category', category).ilike('name', '%${term.trim()}%').order('name').limit(8);
      return [for (final row in rows as List) CommunityPage.fromJson(_withMedia(Map<String, dynamic>.from(row as Map)))];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<CommunityPage?> fetchBySlug(String slug, {String? userId}) async {
    try {
      final row = await _client.from('pages').select('*,region:regions(name)').eq('slug', slug).maybeSingle();
      if (row == null) return null;
      final json = _withMedia(Map<String, dynamic>.from(row));
      if (userId != null) {
        final following = await _client.from('page_followers').select('id').eq('page_id', row['id']).eq('user_id', userId).maybeSingle();
        final summary = await studioSummary(row['id'] as String);
        json['is_followed_by_me'] = following != null;
        json['my_role'] = summary?.myRole;
      }
      return CommunityPage.fromJson(json);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<CreatedPage> createPage({required String name, required String category, String? description, String? website, String? phone, String? email, String? address, String? regionId, String? avatarUrl, String? coverUrl}) async {
    try {
      final result = await _client.rpc('create_page', params: {'p_name': name, 'p_category': category, 'p_description': description, 'p_website': website, 'p_phone': phone, 'p_email': email, 'p_address': address, 'p_region_id': regionId, 'p_avatar_url': avatarUrl, 'p_cover_url': coverUrl});
      final row = Map<String, dynamic>.from((result as List).first as Map);
      return CreatedPage(id: row['id'] as String, slug: row['slug'].toString());
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> followPage(String pageId, String userId) async {
    try { await _client.from('page_followers').insert({'page_id': pageId, 'user_id': userId}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> unfollowPage(String pageId, String userId) async {
    try { await _client.from('page_followers').delete().eq('page_id', pageId).eq('user_id', userId); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<PageStudioSummary?> studioSummary(String pageId) async {
    try {
      final result = await _client.rpc('page_studio_summary', params: {'p_page_id': pageId});
      if (result is! List || result.isEmpty) return null;
      return PageStudioSummary.fromJson(Map<String, dynamic>.from(result.first as Map));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<PageStudioStats> studioStats(String pageId, int days) async {
    try {
      final result = await _client.rpc('page_studio_stats', params: {'p_page_id': pageId, 'p_days': days});
      final json = Map<String, dynamic>.from((result is List ? result.first : result) as Map);
      for (final item in json['latest_followers'] as List? ?? const []) {
        final row = item as Map;
        row['avatar_url'] = storagePublicUrl(_client, 'avatars', row['avatar_url'] as String?);
      }
      return PageStudioStats.fromJson(json);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<PageTeamMember>> fetchTeam(String pageId) async {
    try {
      final rows = await _client.from('page_roles').select('id,role,created_at,user:user_profiles!user_id(id,username,display_name,avatar_url,verification_level)').eq('page_id', pageId).order('created_at');
      return (rows as List).map((raw) {
        final json = Map<String, dynamic>.from(raw as Map);
        final user = Map<String, dynamic>.from(json['user'] as Map);
        user['avatar_url'] = storagePublicUrl(_client, 'avatars', user['avatar_url'] as String?);
        json['user'] = user;
        return PageTeamMember.fromJson(json);
      }).toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<UserProfile>> searchProfiles(String term) async {
    if (term.trim().length < 2) return const [];
    try {
      final rows = await _client.rpc('search_profiles', params: {'p_q': term.trim(), 'p_limit': 8, 'p_offset': 0}).select('id,username,display_name,avatar_url,verification_level');
      return (rows as List).map((raw) {
        final json = Map<String, dynamic>.from(raw as Map);
        json['avatar_url'] = storagePublicUrl(_client, 'avatars', json['avatar_url'] as String?);
        return UserProfile.fromJson(json);
      }).toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<PageTeamMember> addMember(String pageId, String username, String role) async {
    try {
      final result = await _client.rpc('add_page_member', params: {'p_page_id': pageId, 'p_username': username, 'p_role': role});
      final raw = result is List ? result.first : result;
      final row = Map<String, dynamic>.from(raw as Map);
      final profile = (await searchProfiles(username)).where((item) => item.id == row['user_id']).first;
      return PageTeamMember(id: row['member_id'] as String, role: row['role'] as String, createdAt: DateTime.now().toUtc(), profile: profile);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> setMemberRole(String memberId, String role) async {
    try { await _client.rpc('set_page_member_role', params: {'p_member_id': memberId, 'p_role': role}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> removeMember(String memberId) async {
    try { await _client.rpc('remove_page_member', params: {'p_member_id': memberId}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> updatePage(String pageId, Map<String, dynamic> changes) async {
    if (changes.isEmpty) return;
    try { await _client.from('pages').update(changes).eq('id', pageId); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> setStatus(String pageId, String status) async {
    try { await _client.rpc('set_page_status', params: {'p_page_id': pageId, 'p_status': status}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<Page<FeedPost>> fetchPagePosts(String pageId, {PageCursor? cursor}) async {
    try {
      final rows = await _client.rpc('feed_page', params: {'p_page_id': pageId, 'p_limit': pageSize, 'p_before_created_at': cursor?.createdAt.toUtc().toIso8601String(), 'p_before_id': cursor?.id}).isFilter('preview_comments.parent_id', null).eq('preview_comments.status', 'published').select(FeedRepository.postSelect).order('reaction_count', ascending: false, referencedTable: 'preview_comments').order('created_at', ascending: false, referencedTable: 'preview_comments').limit(2, referencedTable: 'preview_comments').order('created_at', ascending: false).order('id', ascending: false);
      final items = await _feedRepository.parsePosts(rows as List);
      final last = items.length == pageSize ? items.last : null;
      return Page(items: items, nextCursor: last == null ? null : PageCursor(createdAt: last.createdAt, id: last.id));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Page<CommunityPage> _pageFromRows(List rows) {
    final items = rows.map((row) => CommunityPage.fromJson(_withMedia(Map<String, dynamic>.from(row as Map)))).toList();
    final last = items.length == pageSize ? items.last : null;
    return Page(items: items, nextCursor: last == null ? null : PageCursor(createdAt: last.createdAt, id: last.id));
  }

  Map<String, dynamic> _withMedia(Map<String, dynamic> json) {
    json['avatar_url'] = storagePublicUrl(_client, 'page-media', json['avatar_url'] as String?);
    json['cover_url'] = storagePublicUrl(_client, 'page-media', json['cover_url'] as String?);
    return json;
  }
}