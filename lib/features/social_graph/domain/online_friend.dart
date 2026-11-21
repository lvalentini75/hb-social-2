/// A friend currently online, returned by the `online_friends(limit)` RPC.
class OnlineFriend {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final DateTime? lastSeenAt;

  const OnlineFriend({required this.id, required this.username, required this.displayName, this.avatarUrl, this.lastSeenAt});

  factory OnlineFriend.fromJson(Map<String, dynamic> json) => OnlineFriend(
    id: (json['user_id'] ?? json['id']).toString(),
    username: json['username'] as String? ?? '',
    displayName: (json['display_name'] as String?)?.trim().isNotEmpty == true ? json['display_name'] as String : (json['username'] as String? ?? ''),
    avatarUrl: json['avatar_url'] as String?,
    lastSeenAt: json['last_seen_at'] == null ? null : DateTime.parse(json['last_seen_at'].toString()).toUtc(),
  );
}
