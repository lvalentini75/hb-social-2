import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Feed filters shown by the segmented control above the feed.
enum FeedFilter { forYou, following, nearby }

/// The filter currently selected by the user.
final feedFilterProvider = StateProvider<FeedFilter>((ref) => FeedFilter.forYou);

/// The feed items for the selected filter.
///
/// There is no posts backend yet (it arrives with P03/P04), so this resolves
/// to an empty list instead of any sample content. The UI already renders the
/// three states of this provider: loading (skeletons), error and empty.
final feedPostsProvider = FutureProvider.autoDispose<List<Object>>((ref) async {
  ref.watch(feedFilterProvider);
  return const [];
});
