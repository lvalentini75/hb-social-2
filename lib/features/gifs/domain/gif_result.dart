class GifResult {
  final String id;
  final String title;
  final String url;
  final String preview;
  final int width;
  final int height;
  final String onsent;

  const GifResult({required this.id, required this.title, required this.url, required this.preview, required this.width, required this.height, required this.onsent});
  factory GifResult.fromJson(Map<String, dynamic> json) => GifResult(id: json['id'].toString(), title: json['title']?.toString() ?? '', url: json['url'].toString(), preview: json['preview'].toString(), width: (json['width'] as num?)?.toInt() ?? 1, height: (json['height'] as num?)?.toInt() ?? 1, onsent: json['onsent'].toString());
}

class GifPage {
  final List<GifResult> results;
  final int? next;
  const GifPage({required this.results, this.next});
  factory GifPage.fromJson(Map<String, dynamic> json) => GifPage(results: [for (final item in json['results'] as List? ?? const []) GifResult.fromJson(Map<String, dynamic>.from(item as Map))], next: (json['next'] as num?)?.toInt());
}