import 'package:hb_social/features/notifications/domain/app_notification.dart';

/// Read access to notifications. The only implementation until P03/P04 is
/// [EmptyNotificationRepository]; a Supabase-backed implementation replaces
/// it once the `notifications` table exists.
abstract class NotificationRepository {
  Future<List<AppNotification>> all();
  Future<List<AppNotification>> unread();
}
