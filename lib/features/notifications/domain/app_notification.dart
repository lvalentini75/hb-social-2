/// A single notification (named `AppNotification` to avoid clashing with
/// Flutter's own `Notification` class), mirroring the future `notifications`
/// table (see ARCHITECTURE.md). Handwritten `fromJson`/`toJson`/`copyWith`
/// per AGENTS rule 9 (no code generation).
class AppNotification {
  final String id;
  final String title;
  final String? body;
  final String? actorName;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    this.body,
    this.actorName,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    body: json['body'] as String?,
    actorName: json['actor_name'] as String?,
    isRead: json['is_read'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'actor_name': actorName,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
  };

  AppNotification copyWith({String? id, String? title, String? body, String? actorName, bool? isRead, DateTime? createdAt}) =>
      AppNotification(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        actorName: actorName ?? this.actorName,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
      );
}
