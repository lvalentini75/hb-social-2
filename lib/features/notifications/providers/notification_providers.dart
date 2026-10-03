import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/features/notifications/data/empty_notification_repository.dart';
import 'package:hb_social/features/notifications/data/notification_repository.dart';
import 'package:hb_social/features/notifications/domain/app_notification.dart';

/// Swap this override once a Supabase-backed [NotificationRepository] exists (P03/P04).
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => const EmptyNotificationRepository());

/// The three views of the Notifications screen.
enum NotificationsTab { all, mentions, requests }

final notificationsTabProvider = StateProvider<NotificationsTab>((ref) => NotificationsTab.all);

/// The notifications shown for the selected tab. Always empty until
/// P03/P04; the UI already renders loading, error and empty states for
/// this provider.
final notificationsListProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  ref.watch(notificationsTabProvider);
  final repository = ref.watch(notificationRepositoryProvider);
  // Dedicated backend queries arrive in P04. All views are explicitly empty
  // in the visual phase, so they share the read-only source for now.
  return repository.all();
});
