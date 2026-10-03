import 'package:hb_social/features/messages/data/conversation_repository.dart';
import 'package:hb_social/features/messages/domain/conversation.dart';

/// No backend yet (see `docs/DECISIONS.md`): every query resolves to an
/// empty list rather than any sample/mock conversation.
class EmptyConversationRepository implements ConversationRepository {
  const EmptyConversationRepository();

  @override
  Future<List<Conversation>> list() async => const [];

  @override
  Future<Conversation?> fetchById(String id) async => null;
}
