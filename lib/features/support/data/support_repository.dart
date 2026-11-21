import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/support/domain/support_ticket.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportRepository {
  final SupabaseClient _client;
  const SupportRepository(this._client);

  Future<List<SupportTicket>> tickets({int offset = 0}) async {
    try { final rows = await _client.rpc('my_support_tickets', params: {'p_limit': 50, 'p_offset': offset}); return [for (final row in rows as List) SupportTicket.fromJson(Map<String, dynamic>.from(row as Map))]; }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }
  Future<List<SupportMessage>> messages(String id) async {
    try { final rows = await _client.rpc('support_ticket_messages', params: {'p_ticket_id': id}); return [for (final row in rows as List) SupportMessage.fromJson(Map<String, dynamic>.from(row as Map))]; }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }
  Future<String> create({required String id, required String subject, required String category, required String body, required List<Map<String, dynamic>> attachments, required Map<String, dynamic> context}) async {
    try { return (await _client.rpc('create_support_ticket', params: {'p_id': id, 'p_subject': subject.trim(), 'p_category': category, 'p_body': body.trim(), 'p_attachments': attachments, 'p_context': context})).toString(); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }
  Future<void> reply(String id, String body, {List<Map<String, dynamic>> attachments = const []}) async {
    try { await _client.rpc('reply_support_ticket', params: {'p_ticket_id': id, 'p_body': body.trim(), 'p_attachments': attachments}); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }
  Future<void> close(String id) async {
    try { await _client.rpc('close_support_ticket', params: {'p_ticket_id': id}); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }
}