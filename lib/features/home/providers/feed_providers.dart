import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/data/paged_notifier.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/services/realtime_service.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/feed/data/reaction_repository.dart';
import 'package:hb_social/features/feed/domain/reaction.dart';
import 'package:hb_social/features/home/data/feed_repository.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/stories/providers/story_providers.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';

/// Feed filters shown by the segmented control above the feed.
enum FeedFilter { forYou, following, nearby }

/// The filter currently selected by the user.
final feedFilterProvider = StateProvider<FeedFilter>((ref) => FeedFilter.forYou);

final feedRepositoryProvider = Provider<FeedRepository>((ref) => FeedRepository(ref.watch(supabaseClientProvider)));
final feedPostsProvider = AsyncNotifierProvider<ForYouFeedNotifier, PagedState<FeedPost>>(ForYouFeedNotifier.new);
final followingFeedProvider = AsyncNotifierProvider<FollowingFeedNotifier, PagedState<FeedPost>>(FollowingFeedNotifier.new);
final nearbyFeedProvider = AsyncNotifierProvider<NearbyFeedNotifier, PagedState<FeedPost>>(NearbyFeedNotifier.new);

class PostLiveData {
  final String status;
  final int reactionCount;
  final int commentCount;
  final int shareCount;
  final List<ReactionSummary>? reactionSummary;
  final String? reactionDisplayName;

  const PostLiveData({required this.status, required this.reactionCount, required this.commentCount, required this.shareCount, this.reactionSummary, this.reactionDisplayName});

  PostLiveData copyWith({List<ReactionSummary>? reactionSummary, String? reactionDisplayName}) => PostLiveData(status: status, reactionCount: reactionCount, commentCount: commentCount, shareCount: shareCount, reactionSummary: reactionSummary ?? this.reactionSummary, reactionDisplayName: reactionDisplayName ?? this.reactionDisplayName);
}

final postLiveUpdatesProvider = StateProvider<Map<String, PostLiveData>>((ref) => const {});
final optimisticReactionCountsProvider = StateProvider<Map<String, int>>((ref) => const {});
final realtimeControllerProvider = AsyncNotifierProvider<RealtimeController, void>(RealtimeController.new);

class RealtimeController extends AsyncNotifier<void> {
  StreamSubscription<PostRealtimeEvent>? _posts;
  StreamSubscription<void>? _stories;
  StreamSubscription<RealtimeConnectionStatus>? _connection;
  Timer? _reactionDebounce;
  Timer? _storyDebounce;
  Timer? _disconnectedDelay;
  final Set<String> _reactionQueue = {};

  @override
  Future<void> build() async {
    final session = await ref.watch(authSessionProvider.future);
    final profile = session == null ? null : await ref.watch(currentProfileProvider.future);
    final service = ref.watch(realtimeServiceProvider);
    await service.configure(countryCode: profile?.countryCode ?? 'IT', userId: session?.user.id, username: profile?.username);
    _posts = service.postEvents.listen(_onPost);
    _stories = service.storyEvents.listen((_) {
      _storyDebounce?.cancel();
      _storyDebounce = Timer(const Duration(seconds: 1), () => ref.invalidate(storyTrayProvider));
    });
    _connection = service.connectionStatus.listen(_onConnection);
    ref.onDispose(() {
      _posts?.cancel();
      _stories?.cancel();
      _connection?.cancel();
      _reactionDebounce?.cancel();
      _storyDebounce?.cancel();
      _disconnectedDelay?.cancel();
    });
  }

  void _onPost(PostRealtimeEvent event) {
    final current = ref.read(postLiveUpdatesProvider);
    final previous = current[event.id];
    final optimistic = ref.read(optimisticReactionCountsProvider)[event.id];
    final acceptedReactionCount = optimistic != null && optimistic != event.reactionCount ? optimistic : event.reactionCount;
    if (optimistic == event.reactionCount) {
      final pending = {...ref.read(optimisticReactionCountsProvider)}..remove(event.id);
      ref.read(optimisticReactionCountsProvider.notifier).state = pending;
    }
    ref.read(postLiveUpdatesProvider.notifier).state = {...current, event.id: PostLiveData(status: event.status, reactionCount: acceptedReactionCount, commentCount: event.commentCount, shareCount: event.shareCount, reactionSummary: previous?.reactionSummary, reactionDisplayName: previous?.reactionDisplayName)};
    if (event.status != 'published') {
      ref.read(feedPostsProvider.notifier).removePost(event.id);
      ref.read(followingFeedProvider.notifier).removePost(event.id);
      ref.read(nearbyFeedProvider.notifier).removePost(event.id);
      return;
    }
    if ((optimistic == null || optimistic == event.reactionCount) && previous?.reactionCount != event.reactionCount) {
      _reactionQueue.add(event.id);
      _reactionDebounce?.cancel();
      _reactionDebounce = Timer(const Duration(milliseconds: 500), _refreshReactions);
    }
  }

  Future<void> _refreshReactions() async {
    final ids = _reactionQueue.toList();
    _reactionQueue.clear();
    if (ids.isEmpty) return;
    try {
      final repository = ReactionRepository(ref.read(supabaseClientProvider));
      final results = await Future.wait([repository.summaryBatch(ids), repository.namesBatch(ids)]);
      final summaries = results[0] as Map<String, PostReactionsInfo>;
      final names = results[1] as Map<String, String>;
      final current = ref.read(postLiveUpdatesProvider);
      final updated = {...current};
      for (final id in ids) {
        final live = updated[id];
        if (live != null) updated[id] = PostLiveData(status: live.status, reactionCount: live.reactionCount, commentCount: live.commentCount, shareCount: live.shareCount, reactionSummary: summaries[id]?.summary ?? const [], reactionDisplayName: names[id]);
      }
      ref.read(postLiveUpdatesProvider.notifier).state = updated;
    } catch (_) {}
  }

  void _onConnection(RealtimeConnectionStatus status) {
    _disconnectedDelay?.cancel();
    if (status == RealtimeConnectionStatus.connected) {
      ref.read(realtimeReconnectingProvider.notifier).state = false;
      return;
    }
    _disconnectedDelay = Timer(const Duration(seconds: 10), () => ref.read(realtimeReconnectingProvider.notifier).state = true);
  }
}

final realtimeReconnectingProvider = StateProvider<bool>((ref) => false);

void applyOptimisticReaction(WidgetRef ref, String postId, int count) {
  ref.read(optimisticReactionCountsProvider.notifier).state = {...ref.read(optimisticReactionCountsProvider), postId: count};
}

abstract class FeedPostsNotifier extends PagedNotifier<FeedPost> {
  FeedQueryFilter get filter;

  @override
  Future<Page<FeedPost>> fetchPage(PageCursor? cursor) => ref.watch(feedRepositoryProvider).getPosts(filter: filter, countryCode: ref.watch(userSettingsProvider).countryCode ?? 'IT', cursor: cursor);

  void insertFirst(FeedPost post) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(items: [post, ...current.items.where((item) => item.id != post.id)]));
  }

  void replacePost(FeedPost post) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(items: current.items.map((item) => item.id == post.id ? post : item).toList()));
  }

  void removePost(String id) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(items: current.items.where((item) => item.id != id).toList()));
  }

  int? indexOf(String id) {
    final index = state.value?.items.indexWhere((item) => item.id == id);
    return index == null || index < 0 ? null : index;
  }

  void restorePost(FeedPost post, int index) {
    final current = state.value;
    if (current == null || current.items.any((item) => item.id == post.id)) return;
    final items = [...current.items];
    items.insert(index.clamp(0, items.length), post);
    state = AsyncData(current.copyWith(items: items));
  }

  void removeAuthor(String authorId) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(items: current.items.where((item) => item.author.id != authorId).toList()));
  }

}

class ForYouFeedNotifier extends FeedPostsNotifier {
  @override
  FeedQueryFilter get filter => FeedQueryFilter.forYou;
}

class FollowingFeedNotifier extends FeedPostsNotifier {
  @override
  FeedQueryFilter get filter => FeedQueryFilter.following;
}

class NearbyFeedNotifier extends FeedPostsNotifier {
  @override
  FeedQueryFilter get filter => FeedQueryFilter.nearby;
}

void insertPublishedPost(WidgetRef ref, FeedPost post, {required bool hasHomeRegion}) {
  ref.read(feedPostsProvider.notifier).insertFirst(post);
  ref.read(followingFeedProvider.notifier).insertFirst(post);
  if (hasHomeRegion) ref.read(nearbyFeedProvider.notifier).insertFirst(post);
}

void replacePostInFeeds(WidgetRef ref, FeedPost post) {
  ref.read(feedPostsProvider.notifier).replacePost(post);
  ref.read(followingFeedProvider.notifier).replacePost(post);
  ref.read(nearbyFeedProvider.notifier).replacePost(post);
}

void removePostFromFeeds(WidgetRef ref, String id) {
  ref.read(feedPostsProvider.notifier).removePost(id);
  ref.read(followingFeedProvider.notifier).removePost(id);
  ref.read(nearbyFeedProvider.notifier).removePost(id);
}

Map<FeedFilter, int> postIndexesInFeeds(WidgetRef ref, String id) {
  final indexes = <FeedFilter, int>{};
  final forYou = ref.read(feedPostsProvider.notifier).indexOf(id);
  final following = ref.read(followingFeedProvider.notifier).indexOf(id);
  final nearby = ref.read(nearbyFeedProvider.notifier).indexOf(id);
  if (forYou != null) indexes[FeedFilter.forYou] = forYou;
  if (following != null) indexes[FeedFilter.following] = following;
  if (nearby != null) indexes[FeedFilter.nearby] = nearby;
  return indexes;
}

void restorePostInFeeds(WidgetRef ref, FeedPost post, Map<FeedFilter, int> indexes) {
  final forYou = indexes[FeedFilter.forYou];
  final following = indexes[FeedFilter.following];
  final nearby = indexes[FeedFilter.nearby];
  if (forYou != null) ref.read(feedPostsProvider.notifier).restorePost(post, forYou);
  if (following != null) ref.read(followingFeedProvider.notifier).restorePost(post, following);
  if (nearby != null) ref.read(nearbyFeedProvider.notifier).restorePost(post, nearby);
}

void removeAuthorFromFeeds(WidgetRef ref, String authorId) {
  ref.read(feedPostsProvider.notifier).removeAuthor(authorId);
  ref.read(followingFeedProvider.notifier).removeAuthor(authorId);
  ref.read(nearbyFeedProvider.notifier).removeAuthor(authorId);
}

final authorPostsProvider = AsyncNotifierProvider.autoDispose.family<AuthorPostsNotifier, PagedState<FeedPost>, String>((authorId) => AuthorPostsNotifier(authorId));
final postDetailProvider = FutureProvider.autoDispose.family<FeedPost?, String>((ref, id) => ref.watch(feedRepositoryProvider).getById(id));
final hashtagCountProvider = FutureProvider.autoDispose.family<int, String>((ref, tag) => ref.watch(feedRepositoryProvider).hashtagPostCount(tag));
final hashtagPostsProvider = AsyncNotifierProvider.autoDispose.family<HashtagPostsNotifier, PagedState<FeedPost>, String>((tag) => HashtagPostsNotifier(tag));

class AuthorPostsNotifier extends PagedNotifier<FeedPost> {
  final String authorId;

  AuthorPostsNotifier(this.authorId);

  @override
  Future<Page<FeedPost>> fetchPage(PageCursor? cursor) => ref.watch(feedRepositoryProvider).fetchByAuthor(authorId: authorId, cursor: cursor);
}

class HashtagPostsNotifier extends PagedNotifier<FeedPost> {
  final String tag;

  HashtagPostsNotifier(this.tag);

  @override
  Future<Page<FeedPost>> fetchPage(PageCursor? cursor) => ref.watch(feedRepositoryProvider).fetchByHashtag(tag: tag, cursor: cursor);
}
