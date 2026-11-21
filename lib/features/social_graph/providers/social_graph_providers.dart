import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/data/paged_notifier.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/onboarding/domain/suggestion.dart';
import 'package:hb_social/features/social_graph/data/social_graph_repository.dart';
import 'package:hb_social/features/social_graph/domain/social_connection.dart';

final socialGraphRepositoryProvider = Provider<SocialGraphRepository>((ref) => SocialGraphRepository(ref.watch(supabaseClientProvider)));
final relationshipProvider = FutureProvider.autoDispose.family<RelationshipStatus, String>((ref, userId) => ref.watch(socialGraphRepositoryProvider).relationshipWith(userId));
final receivedRequestsProvider = FutureProvider.autoDispose<List<FriendRequest>>((ref) => ref.watch(socialGraphRepositoryProvider).requests(received: true));
final sentRequestsProvider = FutureProvider.autoDispose<List<FriendRequest>>((ref) => ref.watch(socialGraphRepositoryProvider).requests(received: false));
final pendingFriendRequestCountProvider = FutureProvider<int>((ref) => ref.watch(socialGraphRepositoryProvider).pendingReceivedCount());
final peopleSuggestionsProvider = FutureProvider<List<SuggestedProfile>>((ref) => ref.watch(socialGraphRepositoryProvider).suggestions());

typedef ConnectionQuery = ({String userId, bool followers});

final connectionsProvider = AsyncNotifierProvider.autoDispose.family<ConnectionsNotifier, PagedState<SocialConnection>, ConnectionQuery>((query) => ConnectionsNotifier(query));

class ConnectionsNotifier extends PagedNotifier<SocialConnection> {
  final ConnectionQuery query;

  ConnectionsNotifier(this.query);

  @override
  Future<Page<SocialConnection>> fetchPage(PageCursor? cursor) => query.followers
      ? ref.read(socialGraphRepositoryProvider).followers(query.userId, cursor)
      : ref.read(socialGraphRepositoryProvider).following(query.userId, cursor);
}

final friendsProvider = AsyncNotifierProvider.autoDispose.family<FriendsNotifier, PagedState<FriendProfile>, String>((userId) => FriendsNotifier(userId));

class FriendsNotifier extends AsyncNotifier<PagedState<FriendProfile>> {
  final String userId;

  FriendsNotifier(this.userId);

  @override
  Future<PagedState<FriendProfile>> build() async {
    final items = await ref.read(socialGraphRepositoryProvider).friends(userId, 0);
    return PagedState(items: items, nextCursor: items.length == 50 ? PageCursor(createdAt: DateTime.now().toUtc(), id: '50') : null);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final items = await ref.read(socialGraphRepositoryProvider).friends(userId, current.items.length);
      state = AsyncData(PagedState(items: [...current.items, ...items], nextCursor: items.length == 50 ? PageCursor(createdAt: DateTime.now().toUtc(), id: '${current.items.length + items.length}') : null));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}