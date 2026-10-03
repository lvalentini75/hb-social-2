/// The kind of entity a [SearchResult] points to.
enum SearchCategory { all, people, groups, posts, listings, forum, hashtags }

/// A single search hit across people, groups, pages and posts, mirroring the
/// future cross-table search (see ARCHITECTURE.md). Handwritten
/// `fromJson`/`toJson`/`copyWith` per AGENTS rule 9 (no code generation).
class SearchResult {
  final String id;
  final SearchCategory category;
  final String title;
  final String? subtitle;
  final DateTime createdAt;

  const SearchResult({required this.id, required this.category, required this.title, this.subtitle, required this.createdAt});

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    id: json['id'] as String,
    category: SearchCategory.values.firstWhere((c) => c.name == json['category'], orElse: () => SearchCategory.all),
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String?,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'title': title,
    'subtitle': subtitle,
    'created_at': createdAt.toIso8601String(),
  };

  SearchResult copyWith({String? id, SearchCategory? category, String? title, String? subtitle, DateTime? createdAt}) => SearchResult(
    id: id ?? this.id,
    category: category ?? this.category,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    createdAt: createdAt ?? this.createdAt,
  );
}
