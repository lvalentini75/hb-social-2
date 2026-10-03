import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/features/messages/data/conversation_repository.dart';
import 'package:hb_social/features/messages/data/empty_conversation_repository.dart';
import 'package:hb_social/features/messages/domain/conversation.dart';

/// Swap this override once a Supabase-backed [ConversationRepository] exists (P03/P04).
final conversationRepositoryProvider = Provider<ConversationRepository>((ref) => const EmptyConversationRepository());

/// Index into the Messages screen's Tutti/Non letti/Gruppi segmented tabs.
/// Purely cosmetic until real data exists: every tab resolves to the same
/// empty list.
final conversationsFilterProvider = StateProvider<int>((ref) => 0);

/// The user's conversations. Always empty until P03/P04; the UI already
/// renders loading, error and empty states for this provider.
final conversationsListProvider = FutureProvider.autoDispose<List<Conversation>>((ref) async {
  ref.watch(conversationsFilterProvider);
  final repository = ref.watch(conversationRepositoryProvider);
  return repository.list();
});

/// A single conversation by id, used by the thread page. Resolves to null
/// until P03/P04 (no conversation is ever found), which the thread page
/// renders as an explicit "conversation not found" state.
final conversationByIdProvider = FutureProvider.autoDispose.family<Conversation?, String>((ref, id) {
  final repository = ref.watch(conversationRepositoryProvider);
  return repository.fetchById(id);
});
