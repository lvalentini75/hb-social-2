import 'package:hb_social/features/messages/domain/conversation.dart';

/// Read access to conversations. The only implementation until P03/P04 is
/// [EmptyConversationRepository]; a Supabase-backed implementation replaces
/// it once the `conversations` table exists.
abstract class ConversationRepository {
  Future<List<Conversation>> list();
  Future<Conversation?> fetchById(String id);
}
