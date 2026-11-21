class LiveUser {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String verificationLevel;
  final bool following;

  const LiveUser({required this.id, required this.username, required this.displayName, this.avatarUrl, this.verificationLevel = 'none', this.following = false});

  factory LiveUser.fromJson(Map<String, dynamic> json) => LiveUser(id: json['id']?.toString() ?? json['user_id']?.toString() ?? '', username: json['username']?.toString() ?? '', displayName: json['display_name']?.toString() ?? json['user_name']?.toString() ?? '', avatarUrl: json['avatar_url']?.toString(), verificationLevel: json['verification_level']?.toString() ?? 'none', following: json['is_following'] == true);
}

class LiveMessage {
  final String id;
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool isHost;
  final String kind;
  final String body;
  final bool pinned;
  final String status;
  final DateTime createdAt;

  const LiveMessage({required this.id, required this.userId, required this.username, required this.displayName, this.avatarUrl, required this.isHost, required this.kind, required this.body, required this.pinned, required this.status, required this.createdAt});

  factory LiveMessage.fromJson(Map<String, dynamic> json) => LiveMessage(id: json['id'].toString(), userId: json['user_id']?.toString() ?? '', username: json['username']?.toString() ?? '', displayName: json['display_name']?.toString() ?? json['user_name']?.toString() ?? '', avatarUrl: json['avatar_url']?.toString(), isHost: json['is_host'] == true, kind: json['kind']?.toString() ?? 'message', body: json['body']?.toString() ?? '', pinned: json['pinned'] == true, status: json['status']?.toString() ?? 'visible', createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc());
}

class LiveStream {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String visibility;
  final String? coverPath;
  final bool chatEnabled;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final int viewerCount;
  final int peakViewers;
  final int totalViewers;
  final int messageCount;
  final bool isHost;
  final LiveUser host;
  final LiveMessage? pinnedMessage;
  final bool present;
  final bool muted;
  final bool removed;
  final int? durationSeconds;

  const LiveStream({required this.id, required this.title, this.description, required this.status, required this.visibility, this.coverPath, required this.chatEnabled, this.scheduledAt, this.startedAt, required this.viewerCount, required this.peakViewers, required this.totalViewers, required this.messageCount, required this.isHost, required this.host, this.pinnedMessage, this.present = false, this.muted = false, this.removed = false, this.durationSeconds});

  factory LiveStream.fromJson(Map<String, dynamic> json) {
    final state = _map(json['my_state']);
    final pinned = _map(json['pinned_message']);
    return LiveStream(id: json['id'].toString(), title: json['title']?.toString() ?? '', description: json['description']?.toString(), status: json['status']?.toString() ?? 'scheduled', visibility: json['visibility']?.toString() ?? 'public', coverPath: json['cover_path']?.toString(), chatEnabled: json['chat_enabled'] != false, scheduledAt: _date(json['scheduled_at']), startedAt: _date(json['started_at']), viewerCount: _int(json['viewer_count']), peakViewers: _int(json['peak_viewers']), totalViewers: _int(json['total_viewers']), messageCount: _int(json['message_count']), isHost: json['is_host'] == true, host: LiveUser.fromJson(_map(json['host'])), pinnedMessage: pinned.isEmpty ? null : LiveMessage.fromJson({...pinned, 'user_id': pinned['user_id'] ?? '', 'username': pinned['username'] ?? '', 'display_name': pinned['user_name'] ?? '', 'created_at': pinned['created_at'] ?? DateTime.now().toUtc().toIso8601String()}), present: state['present'] == true, muted: state['muted'] == true, removed: state['removed'] == true, durationSeconds: json['duration_s'] == null ? null : _int(json['duration_s']));
  }

  LiveStream copyWith({String? status, int? viewerCount, int? peakViewers, int? totalViewers, int? messageCount, bool? chatEnabled, LiveMessage? pinnedMessage}) => LiveStream(id: id, title: title, description: description, status: status ?? this.status, visibility: visibility, coverPath: coverPath, chatEnabled: chatEnabled ?? this.chatEnabled, scheduledAt: scheduledAt, startedAt: startedAt, viewerCount: viewerCount ?? this.viewerCount, peakViewers: peakViewers ?? this.peakViewers, totalViewers: totalViewers ?? this.totalViewers, messageCount: messageCount ?? this.messageCount, isHost: isHost, host: host, pinnedMessage: pinnedMessage ?? this.pinnedMessage, present: present, muted: muted, removed: removed, durationSeconds: durationSeconds);
}

class LiveToken {
  final String token;
  final String url;
  final String room;
  final String role;
  final String identity;
  final bool chatEnabled;
  final bool muted;
  final int maxMinutes;
  final DateTime? startedAt;

  const LiveToken({required this.token, required this.url, required this.room, required this.role, required this.identity, required this.chatEnabled, required this.muted, required this.maxMinutes, this.startedAt});
  factory LiveToken.fromJson(Map<String, dynamic> json) => LiveToken(token: json['token']?.toString() ?? '', url: json['url']?.toString() ?? '', room: json['room']?.toString() ?? '', role: json['role']?.toString() ?? 'viewer', identity: json['identity']?.toString() ?? '', chatEnabled: json['chat_enabled'] != false, muted: json['muted'] == true, maxMinutes: _int(json['max_minutes']), startedAt: _date(json['started_at']));
}

Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse(value.toString())?.toUtc();
int _int(Object? value) => (value as num?)?.toInt() ?? int.tryParse(value?.toString() ?? '') ?? 0;