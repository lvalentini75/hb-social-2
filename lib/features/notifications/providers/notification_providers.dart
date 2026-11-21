import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/data/paged_notifier.dart';
import 'package:hb_social/core/services/realtime_service.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/notifications/data/notification_repository.dart';
import 'package:hb_social/features/notifications/data/push_notification_service.dart';
import 'package:hb_social/features/notifications/domain/app_notification.dart';
import 'package:hb_social/features/notifications/domain/notification_preferences.dart';
import 'package:hb_social/features/notifications/presentation/notification_text.dart';
import 'package:hb_social/features/social_graph/providers/social_graph_providers.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:hb_social/features/chat/providers/chat_providers.dart';

/// Swap this override once a Supabase-backed [NotificationRepository] exists (P03/P04).
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => NotificationRepository(ref.watch(supabaseClientProvider)));

/// The three views of the Notifications screen.
enum NotificationsTab { all, mentions, requests }

final notificationsTabProvider = StateProvider<NotificationsTab>((ref) => NotificationsTab.all);

/// The notifications shown for the selected tab. Always empty until
/// P03/P04; the UI already renders loading, error and empty states for
/// this provider.
final notificationsListProvider = AsyncNotifierProvider.autoDispose<NotificationsNotifier, PagedState<AppNotification>>(NotificationsNotifier.new);

class NotificationsNotifier extends PagedNotifier<AppNotification> {
  @override
  Future<Page<AppNotification>> fetchPage(PageCursor? cursor) async {
    final session = await ref.watch(authSessionProvider.future);
    if (session == null) return const Page(items: []);
    final tab = ref.watch(notificationsTabProvider);
    return ref.watch(notificationRepositoryProvider).getNotifications(userId: session.user.id, filter: NotificationFilter.values[tab.index], cursor: cursor);
  }

  Future<void> markRead(String id) async {
    final current = state.value;
    if (current == null || current.items.where((item) => item.id == id).every((item) => item.isRead)) return;
    await ref.read(notificationRepositoryProvider).markRead(id);
    state = AsyncData(current.copyWith(items: [for (final item in current.items) item.id == id ? item.copyWith(isRead: true) : item]));
    ref.read(unreadNotificationCountProvider.notifier).decrement();
  }

  Future<void> markAllRead() async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(items: [for (final item in current.items) item.copyWith(isRead: true)]));
    ref.read(unreadNotificationCountProvider.notifier).setCount(0);
  }

  void insertRealtime(AppNotification notification) {
    final current = state.value;
    if (current == null) return;
    final tab = ref.read(notificationsTabProvider);
    final visible = tab == NotificationsTab.all || (tab == NotificationsTab.mentions && const {'mention', 'forum_mention'}.contains(notification.kind)) || (tab == NotificationsTab.requests && const {'group_request', 'forum_request', 'follow_request', 'event_request', 'friend_request'}.contains(notification.kind));
    if (visible) state = AsyncData(current.copyWith(items: [notification, ...current.items.where((item) => item.id != notification.id)]));
  }
}

final unreadNotificationCountProvider = AsyncNotifierProvider<UnreadNotificationCountNotifier, int>(UnreadNotificationCountNotifier.new);

class UnreadNotificationCountNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final session = await ref.watch(authSessionProvider.future);
    if (session == null) return 0;
    try { return await ref.watch(notificationRepositoryProvider).getUnreadCount(userId: session.user.id); } catch (_) { return 0; }
  }

  void increment() => state = AsyncData((state.value ?? 0) + 1);
  void decrement() => state = AsyncData(((state.value ?? 0) - 1).clamp(0, 1 << 30));
  void setCount(int count) => state = AsyncData(count);
}

final notificationPreferencesProvider = AsyncNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(NotificationPreferencesNotifier.new);

class NotificationPreferencesNotifier extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() async {
    final session = await ref.watch(authSessionProvider.future);
    if (session == null) return const NotificationPreferences();
    return ref.watch(notificationRepositoryProvider).getPreferences();
  }

  Future<void> updatePreference(String kind, NotificationChannelPreference value) async {
    final current = state.value ?? const NotificationPreferences();
    final updated = current.update(kind, value);
    state = AsyncData(updated);
    try {
      await ref.read(notificationRepositoryProvider).updatePreferences(updated);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) => PushNotificationService(ref.watch(supabaseClientProvider)));
final pushNotificationsControllerProvider = AsyncNotifierProvider<PushNotificationsController, void>(PushNotificationsController.new);

class PushNotificationsController extends AsyncNotifier<void> {
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _realtimeSubscription;
  StreamSubscription<RealtimeConnectionStatus>? _connectionSubscription;
  Timer? _fallbackTimer;

  @override
  Future<void> build() async {
    final session = await ref.watch(authSessionProvider.future);
    ref.onDispose(() {
      _tokenSubscription?.cancel();
      _foregroundSubscription?.cancel();
      _openedSubscription?.cancel();
      _realtimeSubscription?.cancel();
      _connectionSubscription?.cancel();
      _fallbackTimer?.cancel();
    });
    if (session == null) return;
    final realtime = ref.watch(realtimeServiceProvider);
    _realtimeSubscription = realtime.notificationEvents.listen(_onRealtimeNotification);
    _connectionSubscription = realtime.connectionStatus.listen((status) {
      _fallbackTimer?.cancel();
      _fallbackTimer = null;
      if (status == RealtimeConnectionStatus.reconnecting) {
        _fallbackTimer = Timer.periodic(const Duration(minutes: 5), (_) {
          ref.invalidate(notificationsListProvider);
          ref.invalidate(unreadNotificationCountProvider);
          ref.invalidate(pendingFriendRequestCountProvider);
        });
      }
    });
    final service = ref.watch(pushNotificationServiceProvider);
    if (!service.isSupported) return;
    try {
      await service.registerCurrentDevice();
    } catch (_) {
      // Push setup is non-blocking; the in-app notification center still works.
    }
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      try {
        await service.registerToken(token);
      } catch (_) {}
    });
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      ref.invalidate(unreadNotificationCountProvider);
      if (message.data['kind']?.toString() == 'call_incoming') _refreshAndOpen(message, open: true);
    });
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) => _refreshAndOpen(message, open: true));
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _refreshAndOpen(initialMessage, open: true);
  }

  Future<void> _onRealtimeNotification(String id) async {
    try {
      final notification = await ref.read(notificationRepositoryProvider).getById(id);
      if (notification.kind == 'message') {
        ref.invalidate(conversationsProvider);
        ref.invalidate(unreadConversationsCountProvider);
        ref.invalidate(unreadNotificationCountProvider);
      } else {
        ref.read(unreadNotificationCountProvider.notifier).increment();
      }
      ref.read(notificationsListProvider.notifier).insertRealtime(notification);
      if (notification.kind == 'friend_request') ref.invalidate(pendingFriendRequestCountProvider);
      final preferences = ref.read(notificationPreferencesProvider).value;
      final openPath = AppRouter.router.routeInformationProvider.value.uri.path;
      final alreadyOpen = notification.kind == 'message' && notification.conversationId != null && openPath == AppRoutes.conversationDetailPath(notification.conversationId!);
      if (!alreadyOpen && preferences?.forKind(notification.kind).app != false) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(localizedNotificationTitle(notification))));
      }
    } catch (_) {
      ref.invalidate(unreadNotificationCountProvider);
    }
  }

  void _refreshAndOpen(RemoteMessage message, {required bool open}) {
    ref.invalidate(notificationsListProvider);
    ref.invalidate(unreadNotificationCountProvider);
    if (!open) return;
    final route = _routeFor(message.data);
    if (route != null) AppRouter.router.go(route);
  }

  String? _routeFor(Map<String, dynamic> data) {
    final explicit = data['route']?.toString();
    if (explicit != null && explicit.startsWith('/')) return explicit;
    if (data['ticket_id'] != null && const {'support_reply','support_status'}.contains(data['kind']?.toString())) return AppRoutes.supportTicketPath(data['ticket_id'].toString());
    if (data['kind']?.toString() == 'live_started' && data['stream_id'] != null) return AppRoutes.livePath(data['stream_id'].toString());
    if (data['kind']?.toString() == 'call_incoming' && data['call_id'] != null) return AppRoutes.callPath(data['call_id'].toString(), incoming: true);
    if (data['kind']?.toString() == 'call_missed') return AppRoutes.calls;
    final targetType = data['target_type']?.toString();
    final targetId = data['target_id']?.toString();
    final postId = data['post_id']?.toString();
    if (targetType == 'comment' && postId != null) return '${AppRoutes.postPath(postId)}?comment=$targetId';
    if (targetType == 'post' && targetId != null) return AppRoutes.postPath(targetId);
    if (data['kind']?.toString() == 'message' && data['conversation_id'] != null) return AppRoutes.conversationDetailPath(data['conversation_id'].toString());
    final kind = data['kind']?.toString();
    final groupSlug = data['group_slug']?.toString();
    if (kind == 'group_request' && groupSlug != null) return AppRoutes.groupStudioPath(groupSlug);
    if (kind == 'group_accepted' && groupSlug != null) return AppRoutes.groupDetailPath(groupSlug);
    final pageSlug = data['page_slug']?.toString();
    if (kind == 'page_role' && pageSlug != null) return AppRoutes.pageDetailPath(pageSlug);
    if (kind == 'strike') return AppRoutes.privacySecurity;
    if (kind == 'account_suspended') return AppRoutes.suspended;
    final username = data['actor_username']?.toString();
    if (username != null && username.isNotEmpty) return AppRoutes.publicProfilePath(username);
    return AppRoutes.notifications;
  }
}

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
