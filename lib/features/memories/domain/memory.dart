class MemoryItem {
  final String itemType;
  final String itemId;
  final DateTime happenedAt;
  final int yearsAgo;
  final String kind;
  final String? text;
  final String? locationName;
  final String? mediaPath;
  final String? thumbnailPath;
  final int countA;
  final int countB;

  const MemoryItem({required this.itemType, required this.itemId, required this.happenedAt, required this.yearsAgo, required this.kind, this.text, this.locationName, this.mediaPath, this.thumbnailPath, required this.countA, required this.countB});
  factory MemoryItem.fromJson(Map<String, dynamic> json) => MemoryItem(itemType: json['item_type'].toString(), itemId: json['item_id'].toString(), happenedAt: DateTime.parse(json['happened_at'].toString()).toUtc(), yearsAgo: (json['years_ago'] as num).toInt(), kind: json['kind']?.toString() ?? '', text: json['text'] as String?, locationName: json['location_name'] as String?, mediaPath: json['media_path'] as String?, thumbnailPath: json['thumbnail_path'] as String?, countA: (json['count_a'] as num?)?.toInt() ?? 0, countB: (json['count_b'] as num?)?.toInt() ?? 0);
}