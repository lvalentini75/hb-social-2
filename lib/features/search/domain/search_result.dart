import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:hb_social/features/polls/domain/poll.dart';

enum SearchCategory { all, people, posts, hashtags, groups, pages, listings, events, forum }

extension SearchCategoryApi on SearchCategory {
  String get value => name;

  static SearchCategory parse(String? value) => SearchCategory.values.firstWhere((item) => item.name == value, orElse: () => SearchCategory.all);
}

class SearchPreview {
  final SearchCategory category;
  final int total;
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? slug;
  final Map<String, dynamic> extra;

  const SearchPreview({required this.category, required this.total, required this.id, required this.title, this.subtitle, this.imageUrl, this.slug, this.extra = const {}});

  factory SearchPreview.fromJson(Map<String, dynamic> json) => SearchPreview(
    category: _categoryFromKind(json['kind'] as String?),
    total: (json['total'] as num?)?.toInt() ?? 0,
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String?,
    imageUrl: json['image_url'] as String?,
    slug: json['slug'] as String?,
    extra: json['extra'] is Map ? Map<String, dynamic>.from(json['extra'] as Map) : const {},
  );
}

class SearchOverview {
  final Map<SearchCategory, List<SearchPreview>> sections;

  const SearchOverview(this.sections);

  bool get isEmpty => sections.values.every((items) => items.isEmpty);
  int total(SearchCategory category) => sections[category]?.firstOrNull?.total ?? 0;
}

class SearchPostResult {
  final FeedPost post;
  final Poll? poll;

  const SearchPostResult({required this.post, this.poll});
}

class SearchHashtag {
  final String id;
  final String tag;
  final int postCount;

  const SearchHashtag({required this.id, required this.tag, required this.postCount});

  factory SearchHashtag.fromJson(Map<String, dynamic> json) => SearchHashtag(id: json['id'] as String? ?? json['tag'] as String, tag: json['tag'] as String, postCount: (json['post_count'] as num?)?.toInt() ?? 0);
}

class SearchCommunityResult {
  final SearchCategory category;
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? slug;
  final int? count;
  final int? priceMinor;
  final String? currencyCode;
  final DateTime? date;
  final String? forumSlug;
  final bool isMediated;

  const SearchCommunityResult({required this.category, required this.id, required this.title, this.subtitle, this.imageUrl, this.slug, this.count, this.priceMinor, this.currencyCode, this.date, this.forumSlug, this.isMediated = false});
}

class SearchPageResult {
  final List<Object> items;
  final bool hasMore;

  const SearchPageResult({required this.items, required this.hasMore});
}

class SearchRequest {
  final String query;
  final SearchCategory category;
  final int offset;

  const SearchRequest(this.query, this.category, this.offset);

  @override
  bool operator ==(Object other) => other is SearchRequest && other.query == query && other.category == category && other.offset == offset;

  @override
  int get hashCode => Object.hash(query, category, offset);
}

SearchCategory _categoryFromKind(String? kind) => switch (kind) {
  'profile' => SearchCategory.people,
  'post' => SearchCategory.posts,
  'hashtag' => SearchCategory.hashtags,
  'group' => SearchCategory.groups,
  'page' => SearchCategory.pages,
  'listing' => SearchCategory.listings,
  'event' => SearchCategory.events,
  'thread' => SearchCategory.forum,
  _ => SearchCategory.all,
};