import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/forums/domain/forum.dart';
import 'package:hb_social/features/forums/domain/forum_reply.dart';
import 'package:hb_social/features/forums/domain/forum_thread.dart';
import 'package:hb_social/features/forums/domain/forum_studio.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForumsRepository {
  static const pageSize = 20;
  static const repliesPageSize = 50;
  static const studioPageSize = 50;
  static const authorSelect = 'author:user_profiles!author_id(id,username,display_name,avatar_url,verification_level)';
  static const memberUserSelect = 'user:user_profiles!user_id(id,username,display_name,avatar_url,verification_level,last_seen_at)';
  static const attachmentSelect = 'attachments:forum_attachments(id,path,kind,mime_type,size_bytes,file_name,width,height,duration_ms,thumbnail_path,sort_order)';
  static const tagSelect = 'tags:forum_thread_tags(hashtag:hashtags(tag))';
  final SupabaseClient _client;
  final Set<String> _viewedThreads = {};

  ForumsRepository(this._client);

  Future<Page<Forum>> fetchForums({required String countryCode, String? userId, String? category, bool mine = false, PageCursor? cursor}) async {
    try {
      List<String>? forumIds;
      if (mine) {
        if (userId == null) return const Page(items: []);
        final memberships = await _client.from('forum_members').select('forum_id').eq('user_id', userId).eq('status', 'active');
        forumIds = (memberships as List).map((row) => row['forum_id'] as String).toList();
        if (forumIds.isEmpty) return const Page(items: []);
      }
      var query = _client.from('forums').select().eq('status', 'active').eq('country_code', countryCode);
      if (forumIds != null) query = query.inFilter('id', forumIds);
      if (category != null) query = query.eq('category', category);
      if (cursor != null) query = query.or('created_at.lt.${cursor.createdAt.toUtc().toIso8601String()},and(created_at.eq.${cursor.createdAt.toUtc().toIso8601String()},id.lt.${cursor.id})');
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final jsonRows = (rows as List).map((row) => _withForumMedia(Map<String, dynamic>.from(row as Map))).toList();
      await _attachMemberships(jsonRows, userId);
      return _forumPage(jsonRows.map(Forum.fromJson).toList());
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<Forum?> getBySlug(String slug, {String? userId}) async {
    try {
      final row = await _client.from('forums').select().eq('slug', slug).maybeSingle();
      if (row == null) return null;
      final json = _withForumMedia(Map<String, dynamic>.from(row));
      if (userId != null) {
        json['my_membership'] = await _client.from('forum_members').select('role,status').eq('forum_id', json['id']).eq('user_id', userId).maybeSingle();
        try { json['my_role'] = (await studioSummary(json['id'] as String)).myRole; } catch (_) { json['my_role'] = (json['my_membership'] as Map?)?['role']; }
      }
      return Forum.fromJson(json);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<ForumCategory>> fetchCategories() async {
    try {
      final rows = await _client.from('categories').select('slug,name_key,sort_order').eq('kind', 'forum').order('sort_order');
      return (rows as List).map((row) => ForumCategory.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<Page<ForumThread>> fetchThreads({required String forumId, int offset = 0, String filter = 'all', String sort = 'activity', String? tag, String? authorId, DateTime? since}) => _fetchThreadRpc('list_forum_threads', {'p_forum_id': forumId, 'p_limit': pageSize, 'p_offset': offset, 'p_filter': filter, 'p_sort': sort, 'p_tag': tag, 'p_author': authorId, 'p_since': since?.toUtc().toIso8601String()});
  Future<Page<ForumThread>> fetchRecentThreads({required String countryCode, int offset = 0, String? tag, String sort = 'activity'}) => _fetchThreadRpc('list_recent_threads', {'p_country': countryCode, 'p_limit': pageSize, 'p_offset': offset, 'p_tag': tag, 'p_sort': sort}, includeForum: true);

  Future<Page<ForumThread>> _fetchThreadRpc(String function, Map<String, dynamic> params, {bool includeForum = false}) async {
    try {
      final forumSelect = includeForum ? ',forum:forums!forum_id(id,slug,name)' : '';
      final rows = await _client.rpc(function, params: params).select('*,$authorSelect,$attachmentSelect,$tagSelect$forumSelect');
      final items = (rows as List).map((row) => ForumThread.fromJson(_withAuthor(row as Map))).toList();
      final nextOffset = items.length == pageSize ? ((params['p_offset'] as int?) ?? 0) + pageSize : null;
      return Page(items: items, nextCursor: nextOffset == null ? null : PageCursor(createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), id: '$nextOffset'));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<ForumThread?> getThread(String id) async {
    try {
      final row = await _client.from('forum_threads').select('*,$authorSelect,$attachmentSelect,$tagSelect').eq('id', id).maybeSingle();
      return row == null ? null : ForumThread.fromJson(_withAuthor(row));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<Page<ForumReply>> fetchReplies({required String threadId, PageCursor? cursor}) async {
    try {
      var query = _client.from('forum_replies').select('*,$authorSelect,$attachmentSelect').eq('thread_id', threadId).eq('status', 'published');
      if (cursor != null) {
        final stamp = cursor.createdAt.toUtc().toIso8601String();
        query = query.or('created_at.gt.$stamp,and(created_at.eq.$stamp,id.gt.${cursor.id})');
      }
      final rows = await query.order('created_at').order('id').limit(repliesPageSize);
      final raw = (rows as List).map((row) => ForumReply.fromJson(_withAuthor(row as Map))).toList();
      await _attachReplyLikes(raw);
      final last = raw.length == repliesPageSize ? raw.last : null;
      return Page(items: _treeOrder(raw), nextCursor: last == null ? null : PageCursor(createdAt: last.createdAt, id: last.id));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<({String id, String slug})> createForum({required String name, String? description, required String visibility, String? category, String? avatarUrl, String? coverUrl}) async {
    try {
      final result = await _client.rpc('create_forum', params: {'p_name': name.trim(), 'p_description': description?.trim().isEmpty == true ? null : description?.trim(), 'p_visibility': visibility, 'p_category': category, 'p_avatar_url': avatarUrl, 'p_cover_url': coverUrl});
      final row = Map<String, dynamic>.from((result is List ? result.first : result) as Map);
      return (id: row['id'] as String, slug: row['slug'] as String);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<ForumMembership> joinForum(String forumId) async {
    try {
      final result = await _client.rpc('join_forum', params: {'p_forum_id': forumId});
      return ForumMembership.fromJson(Map<String, dynamic>.from((result is List ? result.first : result) as Map));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> leaveForum(String forumId) async {
    try { await _client.rpc('leave_forum', params: {'p_forum_id': forumId}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> createThread({required String forumId, required String title, String? content, List<String> tags = const [], List<Map<String, dynamic>> attachments = const []}) async {
    try { return (await _client.rpc('create_thread', params: {'p_forum_id': forumId, 'p_title': title.trim(), 'p_content': content?.trim().isEmpty == true ? null : content?.trim(), 'p_tags': tags, 'p_attachments': attachments})).toString(); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<ForumReply> createReply({required String threadId, required String content, String? parentId, List<Map<String, dynamic>> attachments = const []}) async {
    try {
      final id = (await _client.rpc('create_reply', params: {'p_thread_id': threadId, 'p_content': content.trim(), 'p_parent_id': parentId, 'p_attachments': attachments})).toString();
      final row = await _client.from('forum_replies').select('*,$authorSelect,$attachmentSelect').eq('id', id).single();
      return ForumReply.fromJson(_withAuthor(row));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<ForumReply> getReply(String id) async {
    try {
      final row = await _client.from('forum_replies').select('*,$authorSelect,$attachmentSelect').eq('id', id).single();
      final reply = ForumReply.fromJson(_withAuthor(row));
      await _attachReplyLikes([reply]);
      return reply;
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<({bool liked, int count})> toggleReplyLike(String id) async {
    try {
      final result = await _client.rpc('toggle_reply_like', params: {'p_reply_id': id});
      final row = Map<String, dynamic>.from((result is List ? result.first : result) as Map);
      return (liked: row['liked'] as bool, count: (row['like_count'] as num).toInt());
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<bool> isThreadSubscribed(String id) async {
    if (_client.auth.currentUser == null) return false;
    try { return await _client.from('forum_thread_subscriptions').select('thread_id').eq('thread_id', id).maybeSingle() != null; } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<bool> subscribeThread(String id, bool on) async {
    try {
      final result = await _client.rpc('subscribe_thread', params: {'p_thread_id': id, 'p_on': on});
      final row = Map<String, dynamic>.from((result is List ? result.first : result) as Map);
      return row['subscribed'] as bool;
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> updateThreadTags(String id, List<String> tags) async {
    try { await _client.rpc('update_thread_tags', params: {'p_thread_id': id, 'p_tags': tags}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<({String tag, int count})>> topTags(String forumId) async {
    try {
      final rows = await _client.rpc('forum_top_tags', params: {'p_forum_id': forumId, 'p_limit': 12});
      return (rows as List).map((raw) { final row = Map<String, dynamic>.from(raw as Map); return (tag: row['tag'] as String, count: (row['thread_count'] as num?)?.toInt() ?? 0); }).toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<String>> searchTags(String term) async {
    if (term.length < 2) return const [];
    try {
      final rows = await _client.rpc('search_hashtags', params: {'p_q': term, 'p_limit': 8});
      return (rows as List).map((row) => (row as Map)['tag'].toString()).toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> markSolution(String threadId, String? replyId) async {
    try { await _client.rpc('mark_thread_solution', params: {'p_thread_id': threadId, 'p_reply_id': replyId}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> touchView(String threadId) async {
    if (!_viewedThreads.add(threadId)) return;
    try { await _client.rpc('touch_thread_view', params: {'p_thread_id': threadId}); } catch (_) { _viewedThreads.remove(threadId); }
  }

  Future<ForumStudioSummary> studioSummary(String forumId) async {
    try {
      final result = await _client.rpc('forum_studio_summary', params: {'p_forum_id': forumId});
      return ForumStudioSummary.fromJson(Map<String, dynamic>.from((result is List ? result.first : result) as Map));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<ForumStudioStats> studioStats(String forumId, int days) async {
    try {
      final result = await _client.rpc('forum_studio_stats', params: {'p_forum_id': forumId, 'p_days': days});
      final json = Map<String, dynamic>.from((result is List ? result.first : result) as Map);
      for (final key in ['latest_members', 'top_contributors']) {
        for (final item in json[key] as List? ?? const []) {
          final row = item as Map;
          row['avatar_url'] = storagePublicUrl(_client, 'avatars', row['avatar_url'] as String?);
        }
      }
      return ForumStudioStats.fromJson(json);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<ForumReport>> forumReports(String forumId, {required bool openOnly}) async {
    try {
      final rows = await _client.rpc('forum_reports', params: {'p_forum_id': forumId, 'p_open': openOnly});
      return (rows as List).map((row) => ForumReport.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> resolveForumReport(String reportId, String action, {String? note}) async {
    try { await _client.rpc('resolve_forum_report', params: {'p_report_id': reportId, 'p_action': action, 'p_note': note?.trim().isEmpty == true ? null : note?.trim()}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<UserProfile>> searchProfiles(String query) async {
    if (query.trim().length < 2) return const [];
    try {
      final rows = await _client.rpc('search_profiles', params: {'p_q': query.trim(), 'p_limit': 8, 'p_offset': 0}).select('id,username,display_name,avatar_url,verification_level');
      return (rows as List).map((row) { final json = Map<String, dynamic>.from(row as Map); json['avatar_url'] = storagePublicUrl(_client, 'avatars', json['avatar_url'] as String?); return UserProfile.fromJson(json); }).toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<ForumMember>> fetchStudioMembers(String forumId, {required String status, int offset = 0}) async {
    try {
      final rows = await _client.from('forum_members').select('id,role,status,created_at,ban_reason,banned_at,$memberUserSelect').eq('forum_id', forumId).eq('status', status).order('created_at').range(offset, offset + studioPageSize - 1);
      final members = (rows as List).map((row) => ForumMember.fromJson(_withMemberUser(row as Map))).toList();
      if (status == 'active') members.sort((a, b) { final rank = _roleRank(b.role).compareTo(_roleRank(a.role)); return rank != 0 ? rank : a.profile.displayName.toLowerCase().compareTo(b.profile.displayName.toLowerCase()); });
      return members;
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<Page<ForumThread>> fetchStudioThreads(String forumId, {int offset = 0}) async {
    try {
      final rows = await _client.from('forum_threads').select('*,$authorSelect').eq('forum_id', forumId).order('is_pinned', ascending: false).order('last_reply_at', ascending: false, nullsFirst: false).order('created_at', ascending: false).range(offset, offset + studioPageSize - 1);
      final items = (rows as List).map((row) => ForumThread.fromJson(_withAuthor(row as Map))).toList();
      final nextOffset = items.length == studioPageSize ? offset + studioPageSize : null;
      return Page(items: items, nextCursor: nextOffset == null ? null : PageCursor(createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), id: '$nextOffset'));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> reviewForumRequest(String memberId, {required bool accept}) async {
    try { final result = await _client.rpc('review_forum_request', params: {'p_member_id': memberId, 'p_accept': accept}); return Map<String, dynamic>.from((result is List ? result.first : result) as Map)['status'] as String; } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> setForumMemberRole(String memberId, String role) async {
    try { final result = await _client.rpc('set_forum_member_role', params: {'p_member_id': memberId, 'p_role': role}); return Map<String, dynamic>.from((result is List ? result.first : result) as Map)['role'] as String; } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> banForumMember(String memberId, {String? reason}) async {
    try { await _client.rpc('ban_forum_member', params: {'p_member_id': memberId, 'p_reason': reason?.trim().isEmpty == true ? null : reason?.trim()}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> unbanForumMember(String memberId) async {
    try { await _client.rpc('unban_forum_member', params: {'p_member_id': memberId}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> removeForumMember(String memberId) async {
    try { await _client.rpc('remove_forum_member', params: {'p_member_id': memberId}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> setForumStatus(String forumId, String status) async {
    try { await _client.rpc('set_forum_status', params: {'p_forum_id': forumId, 'p_status': status}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> updateForum(String forumId, Map<String, dynamic> changes) async {
    if (changes.isEmpty) return;
    try { await _client.from('forums').update(changes).eq('id', forumId); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> setThreadPinned(String threadId, bool value) async {
    try { await _client.rpc('set_thread_pinned', params: {'p_thread_id': threadId, 'p_pinned': value}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> setThreadLocked(String threadId, bool value) async {
    try { await _client.rpc('set_thread_locked', params: {'p_thread_id': threadId, 'p_locked': value}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> setThreadStatus(String threadId, String status) async {
    try { await _client.rpc('set_thread_status', params: {'p_thread_id': threadId, 'p_status': status}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> deleteThread(String threadId) async {
    try { await _client.from('forum_threads').delete().eq('id', threadId); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> updateThread(String id, {required String title, String? content}) async {
    try { await _client.from('forum_threads').update({'title': title.trim(), 'content': content?.trim().isEmpty == true ? null : content?.trim()}).eq('id', id); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> updateReply(String id, String content) async {
    try { await _client.from('forum_replies').update({'content': content.trim()}).eq('id', id); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> _attachReplyLikes(List<ForumReply> replies) async {
    if (replies.isEmpty || _client.auth.currentUser == null) return;
    final rows = await _client.from('forum_reply_likes').select('reply_id').inFilter('reply_id', replies.map((item) => item.id).toList());
    final liked = (rows as List).map((row) => row['reply_id'] as String).toSet();
    for (var index = 0; index < replies.length; index++) { replies[index] = replies[index].copyWith(myLike: liked.contains(replies[index].id)); }
  }

  Future<void> deleteReply(String id) async {
    try { await _client.from('forum_replies').delete().eq('id', id); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  List<ForumReply> _treeOrder(List<ForumReply> replies) {
    final byParent = <String?, List<ForumReply>>{};
    for (final reply in replies) { (byParent[reply.parentId] ??= []).add(reply); }
    final result = <ForumReply>[];
    void append(String? parentId, int depth) {
      for (final reply in byParent[parentId] ?? const <ForumReply>[]) { result.add(reply.copyWith(depth: depth.clamp(0, 2))); append(reply.id, depth + 1); }
    }
    append(null, 0);
    for (final reply in replies) { if (!result.any((item) => item.id == reply.id)) result.add(reply); }
    return result;
  }

  Future<void> _attachMemberships(List<Map<String, dynamic>> forums, String? userId) async {
    if (userId == null || forums.isEmpty) return;
    final ids = forums.map((item) => item['id'] as String).toList();
    final rows = await _client.from('forum_members').select('forum_id,role,status').eq('user_id', userId).inFilter('forum_id', ids);
    final memberships = {for (final row in rows as List) row['forum_id'] as String: row};
    for (final forum in forums) { forum['my_membership'] = memberships[forum['id']]; }
  }

  Map<String, dynamic> _withAuthor(Map row) {
    final json = Map<String, dynamic>.from(row);
    final author = Map<String, dynamic>.from(json['author'] as Map);
    author['avatar_url'] = storagePublicUrl(_client, 'avatars', author['avatar_url'] as String?);
    json['author'] = author;
    return json;
  }

  Map<String, dynamic> _withForumMedia(Map<String, dynamic> json) {
    json['avatar_url'] = storagePublicUrl(_client, 'forum-media', json['avatar_url'] as String?);
    json['cover_url'] = storagePublicUrl(_client, 'forum-media', json['cover_url'] as String?);
    return json;
  }

  Map<String, dynamic> _withMemberUser(Map row) {
    final json = Map<String, dynamic>.from(row);
    final user = Map<String, dynamic>.from(json['user'] as Map);
    user['avatar_url'] = storagePublicUrl(_client, 'avatars', user['avatar_url'] as String?);
    json['user'] = user;
    return json;
  }

  int _roleRank(String role) => const {'owner': 2, 'moderator': 1, 'member': 0}[role] ?? 0;

  Page<Forum> _forumPage(List<Forum> items) {
    final last = items.length == pageSize ? items.last : null;
    return Page(items: items, nextCursor: last == null ? null : PageCursor(createdAt: last.createdAt, id: last.id));
  }
}