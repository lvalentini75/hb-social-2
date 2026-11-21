import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/core/utils/geo.dart';
import 'package:hb_social/features/events/domain/hunting_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventRepository {
  static const pageSize = 20;
  static const select = '*,organizer_user:user_profiles!events_organizer_user_id_fkey(id,username,display_name,avatar_url,verification_level,country_code,locale,currency_code,created_at),organizer_page:pages!events_organizer_page_id_fkey(id,slug,name,avatar_url),organizer_group:groups!events_organizer_group_id_fkey(id,slug,name,avatar_url)';
  final SupabaseClient _client;
  const EventRepository(this._client);

  Future<List<EventCategory>> fetchCategories() async {
    try {
      final rows = await _client.from('categories').select('slug,name_key,sort_order').eq('kind', 'event').order('sort_order');
      return (rows as List).map((row) => EventCategory.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<Page<HuntingEvent>> fetchEvents({required EventView view, String? category, String? userId, PageCursor? cursor}) async {
    try {
      List<String>? ids;
      if (view == EventView.mine) {
        if (userId == null) return const Page(items: []);
        final participating = await _client.from('event_participants').select('event_id').eq('user_id', userId).neq('status', 'cancelled');
        final organized = await _client.from('events').select('id').or('organizer_user_id.eq.$userId,created_by.eq.$userId');
        ids = {...(participating as List).map((row) => row['event_id'] as String), ...(organized as List).map((row) => row['id'] as String)}.toList();
        if (ids.isEmpty) return const Page(items: []);
      }
      var query = _client.from('events').select(select);
      final now = DateTime.now().toUtc().toIso8601String();
      if (view == EventView.upcoming) query = query.eq('status', 'published').gte('starts_at', now);
      if (view == EventView.past) query = query.eq('status', 'published').lt('starts_at', now);
      if (ids != null) query = query.inFilter('id', ids);
      if (category != null) query = query.eq('category', category);
      query = applyCursor(query, cursor);
      final rows = await query.order('created_at', ascending: false).order('id', ascending: false).limit(pageSize);
      final items = (rows as List).map((raw) => _eventFromRaw(raw)).toList();
      final last = items.length == pageSize ? items.last : null;
      return Page(items: items, nextCursor: last == null ? null : PageCursor(createdAt: last.createdAt, id: last.id));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<HuntingEvent>> fetchNearby({required double latitude, required double longitude, required int radiusKm}) async {
    try {
      final rows = await _client.rpc('events_nearby', params: {'p_lat': latitude, 'p_lng': longitude, 'p_radius_km': radiusKm, 'p_limit': 100}).select(select);
      return (rows as List).map((raw) {
        final event = _eventFromRaw(raw);
        final json = Map<String, dynamic>.from(raw as Map);
        json['distance_km'] = event.latitude == null || event.longitude == null ? null : distanceKm(latitude, longitude, event.latitude!, event.longitude!);
        return HuntingEvent.fromJson(_withMedia(json));
      }).toList()..sort((a, b) => (a.distanceKm ?? double.infinity).compareTo(b.distanceKm ?? double.infinity));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<HuntingEvent?> fetchById(String id) async {
    try {
      final row = await _client.from('events').select(select).eq('id', id).maybeSingle();
      return row == null ? null : _eventFromRaw(row);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<EventParticipation?> myParticipation(String eventId) async {
    if (_client.auth.currentUser == null) return null;
    try {
      final row = await _client.from('event_participants').select('status,payment_status,payment_method,ticket_code,checked_in_at,waitlisted_at').eq('event_id', eventId).maybeSingle();
      return row == null ? null : EventParticipation.fromJson(Map<String, dynamic>.from(row));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<EventGoingPreview>> goingPreview(String eventId) async {
    try {
      final rows = await _client.rpc('event_going_preview', params: {'p_event_id': eventId});
      return (rows as List).map((raw) {
        final json = Map<String, dynamic>.from(raw as Map);
        json['avatar_url'] = storagePublicUrl(_client, 'avatars', json['avatar_url'] as String?);
        return EventGoingPreview.fromJson(json);
      }).toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<EventParticipant>> fetchParticipants(String eventId) async {
    try {
      final rows = await _client.from('event_participants').select('id,status,payment_status,payment_method,ticket_code,created_at,waitlisted_at,checked_in_at,user:user_profiles!user_id(id,username,display_name,avatar_url,verification_level)').eq('event_id', eventId).order('status').order('created_at');
      return (rows as List).map((raw) { final json = Map<String, dynamic>.from(raw as Map); final user = Map<String, dynamic>.from(json['user'] as Map); user['avatar_url'] = storagePublicUrl(_client, 'avatars', user['avatar_url'] as String?); json['user'] = user; return EventParticipant.fromJson(json); }).toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<EventOrganizerSummary?> organizerSummary(String eventId) async {
    try {
      final result = await _client.rpc('event_organizer_summary', params: {'p_event_id': eventId});
      final raw = result is List ? (result.isEmpty ? null : result.first) : result;
      if (raw is! Map || raw.isEmpty) return null;
      return EventOrganizerSummary.fromJson(Map<String, dynamic>.from(raw));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<EventPaymentResult> markEventPaid(String participantId, {required bool paid}) async {
    try {
      final result = await _client.rpc('mark_event_paid', params: {'p_participant_id': participantId, 'p_paid': paid});
      final raw = result is List ? result.first : result;
      return EventPaymentResult.fromJson(Map<String, dynamic>.from(raw as Map));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<EventCheckinResult> checkinTicket(String code) async {
    try {
      final result = await _client.rpc('checkin_ticket', params: {'p_code': code});
      final raw = result is List ? result.first : result;
      final json = Map<String, dynamic>.from(raw as Map);
      json['avatar_url'] = storagePublicUrl(_client, 'avatars', json['avatar_url'] as String?);
      return EventCheckinResult.fromJson(json);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> checkinParticipant(String participantId) async {
    try { await _client.rpc('checkin_participant', params: {'p_participant_id': participantId}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> undoCheckin(String participantId) async {
    try { await _client.rpc('undo_checkin', params: {'p_participant_id': participantId}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<EventParticipation> rsvp(String eventId, String status) async {
    try {
      final result = await _client.rpc('rsvp_event', params: {'p_event_id': eventId, 'p_status': status});
      final raw = result is List ? result.first : result;
      return EventParticipation.fromJson(Map<String, dynamic>.from(raw as Map));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> createEvent(Map<String, dynamic> values) async {
    try { return (await _client.rpc('create_event', params: values)).toString(); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> values) async {
    try { await _client.from('events').update(values).eq('id', eventId); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> setEventStatus(String eventId, String status) async {
    try { await _client.rpc('set_event_status', params: {'p_event_id': eventId, 'p_status': status}); } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<EventOrganizerChoice>> managedGroups() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    try {
      final rows = await _client.from('group_members').select('group:groups!group_id(id,name,avatar_url),role').eq('user_id', userId).eq('status', 'active').inFilter('role', const ['owner', 'admin', 'moderator']);
      return (rows as List).map((raw) { final group = Map<String, dynamic>.from((raw as Map)['group'] as Map); return EventOrganizerChoice(kind: 'group', id: group['id'] as String, name: group['name'] as String, avatarUrl: storagePublicUrl(_client, 'group-media', group['avatar_url'] as String?)); }).toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  HuntingEvent _eventFromRaw(Object raw) => HuntingEvent.fromJson(_withMedia(Map<String, dynamic>.from(raw as Map)));
  Map<String, dynamic> _withMedia(Map<String, dynamic> json) {
    json['cover_url'] = storagePublicUrl(_client, 'event-media', json['cover_url'] as String?);
    for (final key in ['organizer_user', 'organizer_page', 'organizer_group']) {
      if (json[key] is Map) {
        final organizer = Map<String, dynamic>.from(json[key] as Map);
        organizer['avatar_url'] = storagePublicUrl(_client, key == 'organizer_user' ? 'avatars' : key == 'organizer_page' ? 'page-media' : 'group-media', organizer['avatar_url'] as String?);
        json[key] = organizer;
      }
    }
    return json;
  }
}