class DiarySeason {
  final String seasonLabel;
  final int outings;
  final int harvests;
  final DateTime? firstOuting;
  final DateTime? lastOuting;
  const DiarySeason({required this.seasonLabel, required this.outings, required this.harvests, this.firstOuting, this.lastOuting});
  factory DiarySeason.fromJson(Map<String, dynamic> json) => DiarySeason(seasonLabel: json['season_label'] as String, outings: (json['outings'] as num?)?.toInt() ?? 0, harvests: (json['harvests'] as num?)?.toInt() ?? 0, firstOuting: DateTime.tryParse(json['first_outing'] as String? ?? ''), lastOuting: DateTime.tryParse(json['last_outing'] as String? ?? ''));
}