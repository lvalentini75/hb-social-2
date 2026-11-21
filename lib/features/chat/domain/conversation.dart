import 'dart:typed_data';

import 'package:hb_social/features/profile/domain/user_profile.dart';

enum LocalMessageState { sending, sent, failed }

class ConversationParticipant {
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String verificationLevel;
  final String role;
  final DateTime? lastReadAt;
  final DateTime? lastSeenAt;

  const ConversationParticipant({required this.userId, required this.username, required this.displayName, this.avatarUrl, required this.verificationLevel, required this.role, this.lastReadAt, this.lastSeenAt});

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) => ConversationParticipant(
    userId: json['user_id'] as String? ?? '', username: json['username'] as String? ?? '', displayName: json['display_name'] as String? ?? '', avatarUrl: json['avatar_url'] as String?,
    verificationLevel: json['verification_level'] as String? ?? 'none', role: json['role'] as String? ?? 'member', lastReadAt: _date(json['last_read_at']), lastSeenAt: _date(json['last_seen_at']),
  );

  UserProfile get profile => UserProfile(id: userId, username: username, displayName: displayName, avatarUrl: avatarUrl, countryCode: '', locale: 'it', currencyCode: 'EUR', unitSystem: 'metric', status: 'active', verificationLevel: verificationLevel, createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), lastSeenAt: lastSeenAt);

  ConversationParticipant copyWith({DateTime? lastReadAt}) => ConversationParticipant(userId: userId, username: username, displayName: displayName, avatarUrl: avatarUrl, verificationLevel: verificationLevel, role: role, lastReadAt: lastReadAt ?? this.lastReadAt, lastSeenAt: lastSeenAt);
}

class ConversationLastMessage {
  final String id;
  final String senderId;
  final String kind;
  final String body;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic> meta;
  final String senderName;

  const ConversationLastMessage({required this.id, required this.senderId, required this.kind, required this.body, required this.status, required this.createdAt, required this.meta, required this.senderName});
  factory ConversationLastMessage.fromJson(Map<String, dynamic> json) => ConversationLastMessage(id: json['id'] as String? ?? '', senderId: json['sender_id'] as String? ?? '', kind: json['kind'] as String? ?? 'text', body: json['body'] as String? ?? '', status: json['status'] as String? ?? 'sent', createdAt: _date(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), meta: _map(json['meta']), senderName: json['sender_name'] as String? ?? '');
}

class Conversation {
  final String id;
  final String kind;
  final String? title;
  final String createdBy;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final String myRole;
  final DateTime? myLastReadAt;
  final DateTime? mutedUntil;
  final int unreadCount;
  final bool isBlocked;
  final ConversationLastMessage? lastMessage;
  final List<ConversationParticipant> participants;

  const Conversation({required this.id, required this.kind, this.title, required this.createdBy, this.lastMessageAt, required this.createdAt, required this.myRole, this.myLastReadAt, this.mutedUntil, required this.unreadCount, required this.isBlocked, required this.lastMessage, required this.participants});

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final last = _mapOrNull(json['last_message']);
    return Conversation(
      id: json['id'] as String, kind: json['kind'] as String? ?? 'direct', title: json['title'] as String?, createdBy: json['created_by'] as String? ?? '', lastMessageAt: _date(json['last_message_at']),
      createdAt: _date(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), myRole: json['my_role'] as String? ?? 'member', myLastReadAt: _date(json['my_last_read_at']), mutedUntil: _date(json['muted_until']),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0, isBlocked: json['is_blocked'] as bool? ?? false, lastMessage: last == null || last.isEmpty ? null : ConversationLastMessage.fromJson(last),
      participants: _list(json['participants']).map(ConversationParticipant.fromJson).toList(),
    );
  }

  bool get isGroup => kind == 'group';
  bool get isMuted => mutedUntil?.isAfter(DateTime.now().toUtc()) ?? false;
  ConversationParticipant? other(String? myId) => participants.where((participant) => participant.userId != myId).firstOrNull;
  String displayName(String? myId) => isGroup ? ((title?.trim().isNotEmpty ?? false) ? title!.trim() : participants.where((item) => item.userId != myId).map((item) => item.displayName).join(', ')) : (other(myId)?.displayName ?? '');
  String? avatarUrl(String? myId) => isGroup ? null : other(myId)?.avatarUrl;

  Conversation copyWith({int? unreadCount, List<ConversationParticipant>? participants, ConversationLastMessage? lastMessage, DateTime? lastMessageAt, DateTime? myLastReadAt}) => Conversation(id: id, kind: kind, title: title, createdBy: createdBy, lastMessageAt: lastMessageAt ?? this.lastMessageAt, createdAt: createdAt, myRole: myRole, myLastReadAt: myLastReadAt ?? this.myLastReadAt, mutedUntil: mutedUntil, unreadCount: unreadCount ?? this.unreadCount, isBlocked: isBlocked, lastMessage: lastMessage ?? this.lastMessage, participants: participants ?? this.participants);
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String kind;
  final String body;
  final String? mediaPath;
  final String? mediaUrl;
  final int? durationMs;
  final String? replyToId;
  final String? clientId;
  final Map<String, dynamic> meta;
  final int? mediaWidth;
  final int? mediaHeight;
  final String? mediaMime;
  final int? mediaSize;
  final String status;
  final DateTime createdAt;
  final UserProfile sender;
  final LocalMessageState localState;
  final Uint8List? localBytes;
  final PreparedChatMedia? localMedia;
  final double uploadProgress;

  const ChatMessage({required this.id, required this.conversationId, required this.senderId, required this.kind, required this.body, this.mediaPath, this.mediaUrl, this.durationMs, this.replyToId, this.clientId, this.meta = const {}, this.mediaWidth, this.mediaHeight, this.mediaMime, this.mediaSize, required this.status, required this.createdAt, required this.sender, this.localState = LocalMessageState.sent, this.localBytes, this.localMedia, this.uploadProgress = 0});

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String, conversationId: json['conversation_id'] as String, senderId: json['sender_id'] as String? ?? '', kind: json['kind'] as String? ?? 'text', body: json['body'] as String? ?? '', mediaPath: json['media_path'] as String?, mediaUrl: json['media_url'] as String?, durationMs: (json['duration_ms'] as num?)?.toInt(), replyToId: json['reply_to_id'] as String?, clientId: json['client_id'] as String?, meta: _map(json['meta']), mediaWidth: (json['media_width'] as num?)?.toInt(), mediaHeight: (json['media_height'] as num?)?.toInt(), mediaMime: json['media_mime'] as String?, mediaSize: (json['media_size'] as num?)?.toInt(), status: json['status'] as String? ?? 'sent', createdAt: _date(json['created_at'])!, sender: UserProfile.fromJson(_map(json['sender'])),
  );

  ChatMessage copyWith({String? id, String? body, String? status, LocalMessageState? localState, UserProfile? sender, String? mediaPath, String? mediaUrl, double? uploadProgress}) => ChatMessage(id: id ?? this.id, conversationId: conversationId, senderId: senderId, kind: kind, body: body ?? this.body, mediaPath: mediaPath ?? this.mediaPath, mediaUrl: mediaUrl ?? this.mediaUrl, durationMs: durationMs, replyToId: replyToId, clientId: clientId, meta: meta, mediaWidth: mediaWidth, mediaHeight: mediaHeight, mediaMime: mediaMime, mediaSize: mediaSize, status: status ?? this.status, createdAt: createdAt, sender: sender ?? this.sender, localState: localState ?? this.localState, localBytes: localBytes, localMedia: localMedia, uploadProgress: uploadProgress ?? this.uploadProgress);
}

class PreparedChatMedia {
  final Uint8List bytes;
  final String extension;
  final String mime;
  final int? width;
  final int? height;
  final int? durationMs;
  final List<double> waveform;

  const PreparedChatMedia({required this.bytes, required this.extension, required this.mime, this.width, this.height, this.durationMs, this.waveform = const []});
}

DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse(value.toString())?.toUtc();
Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
Map<String, dynamic>? _mapOrNull(Object? value) => value is Map ? Map<String, dynamic>.from(value) : null;
List<Map<String, dynamic>> _list(Object? value) => value is List ? value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList() : const [];