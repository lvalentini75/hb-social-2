/// Aggregated public counters returned by the `hb_community_stats()` RPC.
class CommunityStats {
  final int hunters;
  final int groups;
  final int listings;

  const CommunityStats({required this.hunters, required this.groups, required this.listings});

  factory CommunityStats.fromJson(Map<String, dynamic> json) => CommunityStats(
    hunters: (json['hunters'] as num?)?.toInt() ?? 0,
    groups: (json['groups'] as num?)?.toInt() ?? 0,
    listings: (json['listings'] as num?)?.toInt() ?? 0,
  );

  bool get isEmpty => hunters == 0 && groups == 0 && listings == 0;
}
