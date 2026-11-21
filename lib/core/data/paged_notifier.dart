import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/data/page_cursor.dart';

/// Data retained by a cursor-paginated provider.
class PagedState<T> {
  final List<T> items;
  final PageCursor? nextCursor;
  final bool isLoadingMore;

  const PagedState({this.items = const [], this.nextCursor, this.isLoadingMore = false});

  bool get hasMore => nextCursor != null;

  PagedState<T> copyWith({List<T>? items, PageCursor? nextCursor, bool clearCursor = false, bool? isLoadingMore}) => PagedState<T>(
    items: items ?? this.items,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

/// Shared Riverpod controller for `(created_at, id)` cursor pagination.
abstract class PagedNotifier<T> extends AsyncNotifier<PagedState<T>> {
  Future<Page<T>> fetchPage(PageCursor? cursor);

  @override
  Future<PagedState<T>> build() async {
    final page = await fetchPage(null);
    return PagedState<T>(items: page.items, nextCursor: page.nextCursor);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await fetchPage(current.nextCursor);
      state = AsyncData(PagedState<T>(items: [...current.items, ...page.items], nextCursor: page.nextCursor));
    } catch (error, stackTrace) {
      state = AsyncValue<PagedState<T>>.error(error, stackTrace).copyWithPrevious(AsyncData(current.copyWith(isLoadingMore: false)));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}