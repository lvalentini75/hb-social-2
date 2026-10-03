import 'package:hb_social/features/notifications/data/notification_repository.dart';
import 'package:hb_social/features/notifications/domain/app_notification.dart';

/// No backend yet (see `docs/DECISIONS.md`): every query resolves to an
/// empty list rather than any sample/mock notification.
class EmptyNotificationRepository implements NotificationRepository {
  const EmptyNotificationRepository();

  @override
  Future<List<AppNotification>> all() async => const [];

  @override
  Future<List<AppNotification>> unread() async => const [];
}
