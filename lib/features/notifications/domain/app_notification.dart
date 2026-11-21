/// A single notification (named `AppNotification` to avoid clashing with
/// Flutter's own `Notification` class), mirroring the future `notifications`
/// table (see ARCHITECTURE.md). Handwritten `fromJson`/`toJson`/`copyWith`
/// per AGENTS rule 9 (no code generation).
class AppNotification {
  final String id;
  final String kind;
  final String? body;
  final String? actorName;
  final String? actorAvatarUrl;
  final String? actorUsername;
  final String? targetType;
  final String? targetId;
  final String? postId;
  final String? requestId;
  final String? status;
  final String? reason;
  final String? groupSlug;
  final String? groupName;
  final String? pageSlug;
  final String? pageName;
  final String? forumSlug;
  final String? forumName;
  final String? threadId;
  final String? threadTitle;
  final String? eventTitle;
  final String? conversationId;
  final String? messageId;
  final String? messageKind;
  final String? preview;
  final String? conversationKind;
  final String? conversationTitle;
  final bool toReply;
  final String? role;
  final int? activeCount;
  final DateTime? expiresAt;
  final String? alertName;
  final String? alertSpeciesName;
  final String? alertMunicipalityName;
  final int? alertAnimalsCount;
  final double? alertDistanceKm;
  final String? verificationBadgeType;
  final int? verificationDaysLeft;
  final String? verificationPageId;
  final String? orderCarrier;
  final String? orderTracking;
  final String? route;
  final String? ticketId;
  final String? streamId;
  final String? callId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.kind,
    this.body,
    this.actorName,
    this.actorAvatarUrl,
    this.actorUsername,
    this.targetType,
    this.targetId,
    this.postId,
    this.requestId,
    this.status,
    this.reason,
    this.groupSlug,
    this.groupName,
    this.pageSlug,
    this.pageName,
    this.forumSlug,
    this.forumName,
    this.threadId,
    this.threadTitle,
    this.eventTitle,
    this.conversationId,
    this.messageId,
    this.messageKind,
    this.preview,
    this.conversationKind,
    this.conversationTitle,
    this.toReply = false,
    this.role,
    this.activeCount,
    this.expiresAt,
    this.alertName,
    this.alertSpeciesName,
    this.alertMunicipalityName,
    this.alertAnimalsCount,
    this.alertDistanceKm,
    this.verificationBadgeType,
    this.verificationDaysLeft,
    this.verificationPageId,
    this.orderCarrier,
    this.orderTracking,
    this.route,
    this.ticketId,
    this.streamId,
    this.callId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    kind: json['kind'] as String,
    body: (json['data'] as Map?)?['body'] as String?,
    actorName: (json['actor'] as Map?)?['display_name'] as String?,
    actorAvatarUrl: (json['actor'] as Map?)?['avatar_url'] as String?,
    actorUsername: (json['actor'] as Map?)?['username'] as String?,
    targetType: json['target_type'] as String?,
    targetId: json['target_id'] as String?,
    postId: (json['data'] as Map?)?['post_id'] as String?,
    requestId: (json['data'] as Map?)?['request_id'] as String?,
    status: (json['data'] as Map?)?['status'] as String?,
    reason: ((json['data'] as Map?)?['reason'] ?? (json['data'] as Map?)?['note'])?.toString(),
    groupSlug: (json['data'] as Map?)?['group_slug'] as String?,
    groupName: (json['data'] as Map?)?['group_name'] as String?,
    pageSlug: (json['data'] as Map?)?['page_slug']?.toString(),
    pageName: (json['data'] as Map?)?['page_name'] as String?,
    forumSlug: (json['data'] as Map?)?['forum_slug'] as String?,
    forumName: (json['data'] as Map?)?['forum_name'] as String?,
    threadId: (json['data'] as Map?)?['thread_id']?.toString(),
    threadTitle: ((json['data'] as Map?)?['thread_title'] ?? (json['data'] as Map?)?['subject'])?.toString(),
    eventTitle: (json['data'] as Map?)?['event_title'] as String?,
    conversationId: (json['data'] as Map?)?['conversation_id']?.toString(),
    messageId: (json['data'] as Map?)?['message_id']?.toString(),
    messageKind: (json['data'] as Map?)?['kind']?.toString(),
    preview: (json['data'] as Map?)?['preview']?.toString(),
    conversationKind: (json['data'] as Map?)?['conversation_kind']?.toString(),
    conversationTitle: (json['data'] as Map?)?['title']?.toString(),
    toReply: (json['data'] as Map?)?['to_reply'] as bool? ?? false,
    role: (json['data'] as Map?)?['role'] as String?,
    activeCount: ((json['data'] as Map?)?['active_count'] as num?)?.toInt(),
    expiresAt: (json['data'] as Map?)?['expires_at'] == null ? null : DateTime.tryParse((json['data'] as Map)['expires_at'].toString())?.toUtc(),
    alertName: (json['data'] as Map?)?['alert_name']?.toString(),
    alertSpeciesName: (json['data'] as Map?)?['species_name']?.toString(),
    alertMunicipalityName: (json['data'] as Map?)?['municipality_name']?.toString(),
    alertAnimalsCount: ((json['data'] as Map?)?['animals_count'] as num?)?.toInt(),
    alertDistanceKm: ((json['data'] as Map?)?['distance_km'] as num?)?.toDouble(),
    verificationBadgeType: (json['data'] as Map?)?['badge_type']?.toString(),
    verificationDaysLeft: ((json['data'] as Map?)?['days_left'] as num?)?.toInt(),
    verificationPageId: (json['data'] as Map?)?['page_id']?.toString(),
    orderCarrier: (json['data'] as Map?)?['carrier']?.toString(),
    orderTracking: (json['data'] as Map?)?['tracking_code']?.toString(),
    route: (json['data'] as Map?)?['route']?.toString(),
    ticketId: (json['data'] as Map?)?['ticket_id']?.toString(),
    streamId: (json['data'] as Map?)?['stream_id']?.toString(),
    callId: (json['data'] as Map?)?['call_id']?.toString(),
    isRead: json['read_at'] != null,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'data': {'body': body, 'post_id': postId, 'request_id': requestId, 'status': status, 'reason': reason, 'group_slug': groupSlug, 'group_name': groupName, 'page_slug': pageSlug, 'page_name': pageName, 'forum_slug': forumSlug, 'forum_name': forumName, 'thread_id': threadId, 'thread_title': threadTitle, 'event_title': eventTitle, 'conversation_id': conversationId, 'message_id': messageId, 'kind': messageKind, 'preview': preview, 'conversation_kind': conversationKind, 'title': conversationTitle, 'to_reply': toReply, 'role': role, 'active_count': activeCount, 'expires_at': expiresAt?.toIso8601String(), 'alert_name': alertName, 'species_name': alertSpeciesName, 'municipality_name': alertMunicipalityName, 'animals_count': alertAnimalsCount, 'distance_km': alertDistanceKm, 'badge_type': verificationBadgeType, 'days_left': verificationDaysLeft, 'page_id': verificationPageId, 'carrier': orderCarrier, 'tracking_code': orderTracking, 'route': route, 'ticket_id': ticketId, 'stream_id': streamId, 'call_id': callId},
    'actor_name': actorName,
    'target_type': targetType,
    'target_id': targetId,
    'read_at': isRead ? createdAt.toIso8601String() : null,
    'created_at': createdAt.toIso8601String(),
  };

  AppNotification copyWith({String? id, String? kind, String? body, String? actorName, String? actorAvatarUrl, String? actorUsername, String? targetType, String? targetId, String? postId, String? requestId, String? status, String? reason, String? groupSlug, String? groupName, String? pageSlug, String? pageName, String? forumSlug, String? forumName, String? threadId, String? threadTitle, String? eventTitle, String? conversationId, String? messageId, String? messageKind, String? preview, String? conversationKind, String? conversationTitle, bool? toReply, String? role, int? activeCount, DateTime? expiresAt, String? alertName, String? alertSpeciesName, String? alertMunicipalityName, int? alertAnimalsCount, double? alertDistanceKm, String? verificationBadgeType, int? verificationDaysLeft, String? verificationPageId, String? orderCarrier, String? orderTracking, String? route, String? ticketId, String? streamId, String? callId, bool? isRead, DateTime? createdAt}) =>
      AppNotification(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        body: body ?? this.body,
        actorName: actorName ?? this.actorName,
        actorAvatarUrl: actorAvatarUrl ?? this.actorAvatarUrl,
        actorUsername: actorUsername ?? this.actorUsername,
        targetType: targetType ?? this.targetType,
        targetId: targetId ?? this.targetId,
        postId: postId ?? this.postId,
        requestId: requestId ?? this.requestId,
        status: status ?? this.status,
        reason: reason ?? this.reason,
        groupSlug: groupSlug ?? this.groupSlug,
        groupName: groupName ?? this.groupName,
        pageSlug: pageSlug ?? this.pageSlug,
        pageName: pageName ?? this.pageName,
        forumSlug: forumSlug ?? this.forumSlug,
        forumName: forumName ?? this.forumName,
        threadId: threadId ?? this.threadId,
        threadTitle: threadTitle ?? this.threadTitle,
        eventTitle: eventTitle ?? this.eventTitle,
        conversationId: conversationId ?? this.conversationId,
        messageId: messageId ?? this.messageId,
        messageKind: messageKind ?? this.messageKind,
        preview: preview ?? this.preview,
        conversationKind: conversationKind ?? this.conversationKind,
        conversationTitle: conversationTitle ?? this.conversationTitle,
        toReply: toReply ?? this.toReply,
        role: role ?? this.role,
        activeCount: activeCount ?? this.activeCount,
        expiresAt: expiresAt ?? this.expiresAt,
        alertName: alertName ?? this.alertName,
        alertSpeciesName: alertSpeciesName ?? this.alertSpeciesName,
        alertMunicipalityName: alertMunicipalityName ?? this.alertMunicipalityName,
        alertAnimalsCount: alertAnimalsCount ?? this.alertAnimalsCount,
        alertDistanceKm: alertDistanceKm ?? this.alertDistanceKm,
        verificationBadgeType: verificationBadgeType ?? this.verificationBadgeType,
        verificationDaysLeft: verificationDaysLeft ?? this.verificationDaysLeft,
        verificationPageId: verificationPageId ?? this.verificationPageId,
        orderCarrier: orderCarrier ?? this.orderCarrier,
        orderTracking: orderTracking ?? this.orderTracking,
        route: route ?? this.route,
        ticketId: ticketId ?? this.ticketId,
        streamId: streamId ?? this.streamId,
        callId: callId ?? this.callId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
      );
}
