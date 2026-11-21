import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/notifications/domain/app_notification.dart';
import 'package:hb_social/features/notifications/domain/notification_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum NotificationFilter { all, mentions, requests }

class NotificationRepository {
  static const pageSize = 20;
  final SupabaseClient _client;

  const NotificationRepository(this._client);

  Future<AppNotification> getById(String id) async {
    try {
      final row = await _client.from('notifications').select('id,kind,data,target_type,target_id,read_at,created_at,actor:user_profiles!notifications_actor_id_fkey(display_name,username,avatar_url)').eq('id', id).single();
      return AppNotification.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<Page<AppNotification>> getNotifications({required String userId, required NotificationFilter filter, PageCursor? cursor}) async {
    try {
      var query = _client.from('notifications').select('*,actor:user_profiles!notifications_actor_id_fkey(display_name,username,avatar_url)').eq('user_id', userId);
      if (filter == NotificationFilter.mentions) query = query.inFilter('kind', const ['mention', 'forum_mention']);
      if (filter == NotificationFilter.requests) query = query.inFilter('kind', const ['group_request', 'forum_request', 'follow_request', 'event_request', 'friend_request']);
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final items = (rows as List).map((row) => AppNotification.fromJson(Map<String, dynamic>.from(row as Map))).toList();
      final last = items.length == pageSize ? items.last : null;
      return Page(items: items, nextCursor: last == null ? null : PageCursor(createdAt: last.createdAt, id: last.id));
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<int> getUnreadCount({required String userId}) async {
    try {
      final response = await _client.rpc('unread_notifications_count');
      return (response as num?)?.toInt() ?? 0;
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _client.rpc('mark_notification_read', params: {'p_id': id});
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _client.rpc('mark_all_notifications_read');
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<NotificationPreferences> getPreferences() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const NotificationPreferences();
      final row = await _client.from('user_settings').select('notification_prefs').eq('user_id', userId).maybeSingle();
      return NotificationPreferences.fromJson(row?['notification_prefs']);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const AuthException('Not authenticated');
      await _client.from('user_settings').update({'notification_prefs': preferences.toJson()}).eq('user_id', userId);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}
