class CallPeer {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  const CallPeer({required this.id, required this.username, required this.displayName, this.avatarUrl});
  factory CallPeer.fromJson(Map<String, dynamic> json) => CallPeer(id: json['id']?.toString() ?? json['user_id']?.toString() ?? '', username: json['username']?.toString() ?? '', displayName: json['display_name']?.toString() ?? '', avatarUrl: json['avatar_url']?.toString());
}

class AppCall {
  final String id;
  final String kind;
  final String status;
  final String direction;
  final String? roomName;
  final CallPeer peer;
  final DateTime createdAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final String? endReason;

  const AppCall({required this.id, required this.kind, required this.status, required this.direction, this.roomName, required this.peer, required this.createdAt, this.answeredAt, this.endedAt, this.durationSeconds = 0, this.endReason});
  factory AppCall.fromJson(Map<String, dynamic> json) => AppCall(id: json['id'].toString(), kind: json['kind']?.toString() ?? 'audio', status: json['status']?.toString() ?? 'ringing', direction: json['direction']?.toString() ?? '', roomName: json['room_name']?.toString(), peer: CallPeer.fromJson(_map(json['peer'])), createdAt: _date(json['created_at']) ?? DateTime.now().toUtc(), answeredAt: _date(json['answered_at']), endedAt: _date(json['ended_at']), durationSeconds: (json['duration_s'] as num?)?.toInt() ?? 0, endReason: json['end_reason']?.toString());
  bool get terminal => const {'declined','missed','cancelled','ended','failed'}.contains(status);
  AppCall copyWith({String? status, DateTime? answeredAt, DateTime? endedAt, int? durationSeconds, String? endReason}) => AppCall(id: id, kind: kind, status: status ?? this.status, direction: direction, roomName: roomName, peer: peer, createdAt: createdAt, answeredAt: answeredAt ?? this.answeredAt, endedAt: endedAt ?? this.endedAt, durationSeconds: durationSeconds ?? this.durationSeconds, endReason: endReason ?? this.endReason);
}

class CallToken {
  final String token;
  final String url;
  final String room;
  final String identity;
  final String peerIdentity;
  final String kind;
  final String status;

  const CallToken({required this.token, required this.url, required this.room, required this.identity, required this.peerIdentity, required this.kind, required this.status});
  factory CallToken.fromJson(Map<String, dynamic> json) => CallToken(token: json['token']?.toString() ?? '', url: json['url']?.toString() ?? '', room: json['room']?.toString() ?? '', identity: json['identity']?.toString() ?? '', peerIdentity: json['peer_identity']?.toString() ?? '', kind: json['kind']?.toString() ?? 'audio', status: json['status']?.toString() ?? 'ringing');
}

Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse(value.toString())?.toUtc();