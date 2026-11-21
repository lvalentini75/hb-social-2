import 'package:supabase_flutter/supabase_flutter.dart';

/// Stable cursor for lists ordered by `(created_at, id)` descending.
class PageCursor {
  final DateTime createdAt;
  final String id;

  const PageCursor({required this.createdAt, required this.id});
}

/// One cursor-paginated result page.
class Page<T> {
  final List<T> items;
  final PageCursor? nextCursor;

  const Page({required this.items, this.nextCursor});

  bool get hasMore => nextCursor != null;
}

/// Applies the shared descending cursor predicate to a Supabase query.
PostgrestFilterBuilder<PostgrestList> applyCursor(PostgrestFilterBuilder<PostgrestList> query, PageCursor? cursor, {String column = 'created_at'}) {
  if (cursor == null) return query;
  final timestamp = cursor.createdAt.toUtc().toIso8601String();
  return query.or('$column.lt.$timestamp,and($column.eq.$timestamp,id.lt.${cursor.id})');
}