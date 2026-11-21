import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/groups/domain/group.dart';
import 'package:hb_social/features/home/data/feed_repository.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupRepository {
  static const pageSize = 20;
  static const studioPageSize = 50;
  final SupabaseClient _client;
  late final FeedRepository _feedRepository = FeedRepository(_client);

  GroupRepository(this._client);

  Future<Page<Group>> fetchMyGroups({required String userId, PageCursor? cursor}) => fetchGroups(filter: GroupFilter.mine, userId: userId, cursor: cursor);
  Future<Group?> getBySlug(String slug, {String? userId}) => fetchBySlug(slug, userId: userId);

  Future<Page<Group>> fetchGroups({required GroupFilter filter, String? userId, String? category, PageCursor? cursor}) async {
    try {
      List<String>? memberGroupIds;
      if (filter == GroupFilter.mine) {
        if (userId == null) return const Page(items: []);
        final memberships = await _client.from('group_members').select('group_id').eq('user_id', userId).eq('status', 'active');
        memberGroupIds = (memberships as List).map((row) => row['group_id'] as String).toList();
        if (memberGroupIds.isEmpty) return const Page(items: []);
      }
      var query = _client.from('groups').select().eq('status', 'active');
      if (memberGroupIds != null) query = query.inFilter('id', memberGroupIds);
      if (category != null) query = query.eq('category', category);
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final jsonRows = (rows as List).map((row) => _withMedia(Map<String, dynamic>.from(row as Map))).toList();
      await _attachMemberships(jsonRows, userId);
      final items = jsonRows.map(Group.fromJson).toList();
      final last = items.length == pageSize ? items.last : null;
      return Page(items: items, nextCursor: last == null ? null : PageCursor(createdAt: last.createdAt, id: last.id));
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<Group?> fetchBySlug(String slug, {String? userId}) async {
    try {
      final row = await _client.from('groups').select().eq('slug', slug).maybeSingle();
      if (row == null) return null;
      final json = _withMedia(Map<String, dynamic>.from(row));
      if (userId != null) {
        final membership = await _client.from('group_members').select('role,status').eq('group_id', row['id']).eq('user_id', userId).maybeSingle();
        json['my_membership'] = membership;
      }
      return Group.fromJson(json);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<GroupMember>> fetchMembers(String groupId) async {
    try {
      final rows = await _client.from('group_members').select('id,role,created_at,profile:user_profiles!group_members_user_id_fkey(id,username,display_name,avatar_url,verification_level,country_code,locale,currency_code,created_at)').eq('group_id', groupId).eq('status', 'active').order('created_at').limit(pageSize);
      return (rows as List).map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        final profile = Map<String, dynamic>.from(json['profile'] as Map);
        profile['avatar_url'] = storagePublicUrl(_client, 'avatars', profile['avatar_url'] as String?);
        json['profile'] = profile;
        return GroupMember.fromJson(json);
      }).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<GroupMember>> fetchStudioMembers(String groupId, {required String status, int offset = 0}) async {
    try {
      final rows = await _client
          .from('group_members')
          .select('id,role,status,created_at,ban_reason,banned_by,banned_at,user:user_profiles!user_id(id,username,display_name,avatar_url,verification_level)')
          .eq('group_id', groupId)
          .eq('status', status)
          .order('created_at')
          .range(offset, offset + studioPageSize - 1);
      final members = (rows as List).map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        final profile = Map<String, dynamic>.from(json.remove('user') as Map);
        profile['avatar_url'] = storagePublicUrl(_client, 'avatars', profile['avatar_url'] as String?);
        json['profile'] = profile;
        return GroupMember.fromJson(json);
      }).toList();
      if (status == 'active') {
        const rank = {'owner': 3, 'admin': 2, 'moderator': 1, 'member': 0};
        members.sort((left, right) {
          final byRole = (rank[right.role] ?? 0).compareTo(rank[left.role] ?? 0);
          return byRole != 0 ? byRole : left.profile.displayName.toLowerCase().compareTo(right.profile.displayName.toLowerCase());
        });
      }
      return members;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<bool> isMember(String groupId, String? userId) async {
    if (userId == null) return false;
    try {
      final row = await _client.from('group_members').select('id').eq('group_id', groupId).eq('user_id', userId).eq('status', 'active').maybeSingle();
      return row != null;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<Page<FeedPost>> fetchGroupPosts(String groupId, {PageCursor? cursor}) async {
    try {
      final rows = await _client.rpc('feed_group', params: {
        'p_group_id': groupId,
        'p_limit': pageSize,
        'p_before_created_at': cursor?.createdAt.toUtc().toIso8601String(),
        'p_before_id': cursor?.id,
      }).isFilter('preview_comments.parent_id', null).eq('preview_comments.status', 'published').select(FeedRepository.postSelect).order('reaction_count', ascending: false, referencedTable: 'preview_comments').order('created_at', ascending: false, referencedTable: 'preview_comments').limit(2, referencedTable: 'preview_comments').order('created_at', ascending: false).order('id', ascending: false);
      final items = await _feedRepository.parsePosts(rows as List);
      final last = items.length == pageSize ? items.last : null;
      return Page(items: items, nextCursor: last == null ? null : PageCursor(createdAt: last.createdAt, id: last.id));
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<List<GroupCategory>> fetchCategories() async {
    try {
      final rows = await _client.from('categories').select('slug,name_key,sort_order').eq('kind', 'group').order('sort_order');
      return (rows as List).map((row) => GroupCategory.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<({String id, String slug})> createGroup({required String name, String? description, required String visibility, required String joinPolicy, String? category, String? regionId, String? avatarUrl, String? coverUrl}) async {
    try {
      final result = await _client.rpc('create_group', params: {'p_name': name.trim(), 'p_description': description?.trim().isEmpty == true ? null : description?.trim(), 'p_visibility': visibility, 'p_join_policy': joinPolicy, 'p_category': category, 'p_region_id': regionId, 'p_avatar_url': avatarUrl, 'p_cover_url': coverUrl});
      final raw = result is List ? result.first : result;
      final row = Map<String, dynamic>.from(raw as Map);
      return (id: row['id'] as String, slug: row['slug'] as String);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<GroupMembership> joinGroup(String groupId) async {
    try {
      final result = await _client.rpc('join_group', params: {'p_group_id': groupId});
      final raw = result is List ? result.first : result;
      return GroupMembership.fromJson(Map<String, dynamic>.from(raw as Map));
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      await _client.rpc('leave_group', params: {'p_group_id': groupId});
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<GroupStudioSummary> studioSummary(String groupId) async {
    try {
      final result = await _client.rpc('group_studio_summary', params: {'p_group_id': groupId});
      final raw = result is List ? result.first : result;
      return GroupStudioSummary.fromJson(Map<String, dynamic>.from(raw as Map));
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<GroupStudioStats> studioStats(String groupId, int days) async {
    try {
      final result = await _client.rpc('group_studio_stats', params: {'p_group_id': groupId, 'p_days': days});
      final json = Map<String, dynamic>.from((result is List ? result.first : result) as Map);
      for (final key in ['latest_members', 'top_contributors']) {
        for (final item in json[key] as List? ?? const []) {
          final row = item as Map;
          row['avatar_url'] = storagePublicUrl(_client, 'avatars', row['avatar_url'] as String?);
        }
      }
      return GroupStudioStats.fromJson(json);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<String> reviewJoinRequest(String memberId, {required bool accept}) async {
    try {
      final result = await _client.rpc('review_join_request', params: {'p_member_id': memberId, 'p_accept': accept});
      final raw = result is List ? result.first : result;
      return Map<String, dynamic>.from(raw as Map)['status'] as String;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<String> setMemberRole(String memberId, String role) async {
    try {
      final result = await _client.rpc('set_group_member_role', params: {'p_member_id': memberId, 'p_role': role});
      final raw = result is List ? result.first : result;
      return Map<String, dynamic>.from(raw as Map)['role'] as String;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> banMember(String memberId, {String? reason}) async {
    try {
      await _client.rpc('ban_group_member', params: {'p_member_id': memberId, 'p_reason': reason?.trim().isEmpty == true ? null : reason?.trim()});
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> unbanMember(String memberId) async {
    try {
      await _client.rpc('unban_group_member', params: {'p_member_id': memberId});
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> removeMember(String memberId) async {
    try {
      await _client.rpc('remove_group_member', params: {'p_member_id': memberId});
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> setGroupStatus(String groupId, String status) async {
    try {
      await _client.rpc('set_group_status', params: {'p_group_id': groupId, 'p_status': status});
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> updateGroup(String groupId, Map<String, dynamic> changes) async {
    if (changes.isEmpty) return;
    try {
      await _client.from('groups').update(changes).eq('id', groupId);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> _attachMemberships(List<Map<String, dynamic>> groups, String? userId) async {
    if (userId == null || groups.isEmpty) return;
    final ids = groups.map((group) => group['id'] as String).toList();
    final rows = await _client.from('group_members').select('group_id,role,status').eq('user_id', userId).inFilter('group_id', ids);
    final memberships = {for (final row in rows as List) row['group_id'] as String: Map<String, dynamic>.from(row as Map)};
    for (final group in groups) {
      group['my_membership'] = memberships[group['id']];
    }
  }

  Map<String, dynamic> _withMedia(Map<String, dynamic> json) {
    json['avatar_url'] = storagePublicUrl(_client, 'group-media', json['avatar_url'] as String?);
    json['cover_url'] = storagePublicUrl(_client, 'group-media', json['cover_url'] as String?);
    return json;
  }
}