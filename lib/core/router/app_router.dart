import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/config/env.dart';
import 'package:hb_social/core/widgets/hb_coming_soon_page.dart';
import 'package:hb_social/features/auth/presentation/login_page.dart';
import 'package:hb_social/features/auth/presentation/signup_page.dart';
import 'package:hb_social/features/auth/presentation/welcome_page.dart';
import 'package:hb_social/features/admin/domain/admin_module.dart';
import 'package:hb_social/features/admin/presentation/admin_dashboard_page.dart';
import 'package:hb_social/features/admin/presentation/admin_badges_page.dart';
import 'package:hb_social/features/admin/presentation/admin_login_page.dart';
import 'package:hb_social/features/admin/presentation/admin_module_page.dart';
import 'package:hb_social/features/admin/presentation/admin_reports_page.dart';
import 'package:hb_social/features/admin/presentation/admin_users_page.dart';
import 'package:hb_social/features/admin/presentation/admin_approvals_page.dart';
import 'package:hb_social/features/admin/presentation/admin_calendars_page.dart';
import 'package:hb_social/features/admin/presentation/admin_roles_page.dart';
import 'package:hb_social/features/admin/providers/admin_preview_provider.dart';
import 'package:hb_social/features/admin/providers/admin_session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/features/dev/presentation/design_system_page.dart';
import 'package:hb_social/features/events/presentation/event_detail_page.dart';
import 'package:hb_social/features/events/presentation/events_page.dart';
import 'package:hb_social/features/forum/presentation/forum_page.dart';
import 'package:hb_social/features/groups/presentation/group_detail_page.dart';
import 'package:hb_social/features/groups/presentation/groups_page.dart';
import 'package:hb_social/features/home/presentation/home_feed_page.dart';
import 'package:hb_social/features/hunting/presentation/hunting_calendar_page.dart';
import 'package:hb_social/features/hunting/presentation/hunting_diary_detail_page.dart';
import 'package:hb_social/features/hunting/presentation/hunting_diary_page.dart';
import 'package:hb_social/features/hunting/presentation/hunting_dog_detail_page.dart';
import 'package:hb_social/features/hunting/presentation/hunting_dogs_page.dart';
import 'package:hb_social/features/hunting/presentation/hunting_hub_page.dart';
import 'package:hb_social/features/hunting/presentation/hunting_map_page.dart';
import 'package:hb_social/features/hunting/presentation/hunting_zone_page.dart';
import 'package:hb_social/features/marketplace/presentation/marketplace_detail_page.dart';
import 'package:hb_social/features/marketplace/presentation/marketplace_page.dart';
import 'package:hb_social/features/messages/presentation/conversation_detail_page.dart';
import 'package:hb_social/features/messages/presentation/messages_page.dart';
import 'package:hb_social/features/notifications/presentation/notifications_page.dart';
import 'package:hb_social/features/onboarding/presentation/onboarding_page.dart';
import 'package:hb_social/features/pages/presentation/pages_list_page.dart';
import 'package:hb_social/features/profile/presentation/profile_page.dart';
import 'package:hb_social/features/profile/presentation/public_profile_page.dart';
import 'package:hb_social/features/search/presentation/search_page.dart';
import 'package:hb_social/features/settings/presentation/settings_page.dart';
import 'package:hb_social/shell/app_shell.dart';
import 'package:hb_social/shell/admin_shell.dart';

/// Route path constants. Use these instead of hard-coding route strings.
class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';

  static const String home = '/';
  static const String search = '/search';
  static const String notifications = '/notifications';
  static const String groups = '/groups';
  static const String forum = '/forum';
  static const String pages = '/pages';
  static const String marketplace = '/marketplace';
  static const String events = '/events';
  static const String hunting = '/hunting';
  static const String huntingZone = '/hunting/zone';
  static const String huntingCalendar = '/hunting/calendar';
  static const String huntingDiary = '/hunting/diary';
  static const String huntingMap = '/hunting/map';
  static const String huntingDogs = '/hunting/dogs';
  static const String huntingSightings = '/hunting/sightings';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static const String designSystem = '/dev/design-system';
  static const String admin = '/admin';
  static const String adminLogin = '/admin/login';
  static const String adminUsers = '/admin/users';
  static const String adminReports = '/admin/reports';
  static const String adminBadges = '/admin/badges';
  static const String adminApprovals = '/admin/approvals';
  static const String adminCalendars = '/admin/calendars';
  static const String adminRoles = '/admin/roles';

  /// Public profile route. Lives inside the shell as part of the Profile
  /// branch (see [AppRouter]) so it never owns its own Scaffold. Build a
  /// concrete path with [publicProfilePath].
  static const String publicProfile = '/u/:username';

  static String publicProfilePath(String username) => '/u/$username';

  /// Group detail route, nested under [groups] so it stays inside the shell.
  static String groupDetailPath(String id) => '/groups/$id';

  /// Conversation thread route, nested under [messages] so it stays inside the shell.
  static String conversationDetailPath(String id) => '/messages/$id';

  static String marketplaceDetailPath(String id) => '/marketplace/$id';

  static String eventDetailPath(String id) => '/events/$id';

  static String huntingDiaryDetailPath(String id) => '$huntingDiary/$id';

  static String huntingDogDetailPath(String id) => '$huntingDogs/$id';

  /// Every destination that lives inside the navigation shell, in branch order.
  static const List<String> shellBranches = [
    home,
    search,
    notifications,
    groups,
    forum,
    pages,
    marketplace,
    events,
    hunting,
    messages,
    profile,
  ];

  /// Branch index for a shell location, or null when the location is outside
  /// the shell (welcome, login, ...).
  static int? branchIndexOf(String location) {
    if (location == settings) return shellBranches.indexOf(profile);
    if (location.startsWith('$hunting/')) return shellBranches.indexOf(hunting);
    final index = shellBranches.indexOf(location);
    return index == -1 ? null : index;
  }
}

/// GoRouter configuration for HB Social.
///
/// The social surface remains reachable without authentication during the
/// visual phase. The admin surface has its own [ShellRoute], shell and login;
/// debug builds can enter it through the explicit preview link.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.welcome,
    routes: [
      GoRoute(path: AppRoutes.welcome, name: 'welcome', pageBuilder: (context, state) => const NoTransitionPage(child: WelcomePage())),
      GoRoute(path: AppRoutes.login, name: 'login', pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage())),
      GoRoute(path: AppRoutes.signup, name: 'signup', pageBuilder: (context, state) => const NoTransitionPage(child: SignupPage())),
      GoRoute(path: AppRoutes.onboarding, name: 'onboarding', pageBuilder: (context, state) => const NoTransitionPage(child: OnboardingPage())),
      GoRoute(path: AppRoutes.adminLogin, name: 'adminLogin', pageBuilder: (context, state) => const NoTransitionPage(child: AdminLoginPage())),
      ShellRoute(
        redirect: (context, state) {
          final container = ProviderScope.containerOf(context);
          if (Env.previewEnabled && state.uri.queryParameters['debugPreview'] == 'true') {
            container.read(adminPreviewProvider.notifier).state = true;
          }
          final authenticated = container.read(adminSessionProvider).isAuthenticated;
          final previewEnabled = Env.previewEnabled && container.read(adminPreviewProvider);
          return authenticated || previewEnabled ? null : AppRoutes.adminLogin;
        },
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.admin, name: 'adminDashboard', pageBuilder: (context, state) => const NoTransitionPage(child: AdminDashboardPage())),
          GoRoute(path: AppRoutes.adminUsers, name: 'adminUsers', pageBuilder: (context, state) => const NoTransitionPage(child: AdminUsersPage())),
          GoRoute(path: AppRoutes.adminReports, name: 'adminReports', pageBuilder: (context, state) => const NoTransitionPage(child: AdminReportsPage())),
          GoRoute(path: AppRoutes.adminBadges, name: 'adminBadges', pageBuilder: (context, state) => const NoTransitionPage(child: AdminBadgesPage())),
          GoRoute(path: AppRoutes.adminApprovals, name: 'adminApprovals', pageBuilder: (context, state) => const NoTransitionPage(child: AdminApprovalsPage())),
          GoRoute(path: AppRoutes.adminCalendars, name: 'adminCalendars', pageBuilder: (context, state) => const NoTransitionPage(child: AdminCalendarsPage())),
          GoRoute(path: AppRoutes.adminRoles, name: 'adminRoles', pageBuilder: (context, state) => const NoTransitionPage(child: AdminRolesPage())),
          GoRoute(
            path: '${AppRoutes.admin}/:slug',
            name: 'adminModule',
            pageBuilder: (context, state) {
              final module = adminModuleForSlug(state.pathParameters['slug']!) ?? adminModuleForSlug('')!;
              return NoTransitionPage(child: AdminModulePage(module: module));
            },
          ),
        ],
      ),
      if (Env.previewEnabled)
        GoRoute(
          path: AppRoutes.designSystem,
          name: 'designSystem',
          pageBuilder: (context, state) => const NoTransitionPage(child: DesignSystemPage()),
        ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          _branch(AppRoutes.home, 'home', const HomeFeedPage()),
          _branch(AppRoutes.search, 'search', const SearchPage()),
          _branch(AppRoutes.notifications, 'notifications', const NotificationsPage()),
          _branch(
            AppRoutes.groups,
            'groups',
            const GroupsPage(),
            childRoutes: [
              GoRoute(
                path: ':id',
                name: 'groupDetail',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: GroupDetailPage(groupId: state.pathParameters['id']!, debugPreview: Env.previewEnabled && state.uri.queryParameters['debugPreview'] == 'true'),
                ),
              ),
            ],
          ),
          _branch(AppRoutes.forum, 'forum', const ForumPage()),
          _branch(AppRoutes.pages, 'pages', const PagesListPage()),
          _branch(
            AppRoutes.marketplace,
            'marketplace',
            const MarketplacePage(),
            childRoutes: [
              GoRoute(
                path: ':id',
                name: 'marketplaceDetail',
                pageBuilder: (context, state) => NoTransitionPage(child: MarketplaceDetailPage(listingId: state.pathParameters['id']!, debugPreview: Env.previewEnabled && state.uri.queryParameters['debugPreview'] == 'true')),
              ),
            ],
          ),
          _branch(
            AppRoutes.events,
            'events',
            const EventsPage(),
            childRoutes: [
              GoRoute(
                path: ':id',
                name: 'eventDetail',
                pageBuilder: (context, state) => NoTransitionPage(child: EventDetailPage(eventId: state.pathParameters['id']!, debugPreview: Env.previewEnabled && state.uri.queryParameters['debugPreview'] == 'true')),
              ),
            ],
          ),
           _branch(
             AppRoutes.hunting,
             'hunting',
             const HuntingHubPage(),
             childRoutes: [
               GoRoute(path: 'zone', name: 'huntingZone', pageBuilder: (context, state) => const NoTransitionPage(child: HuntingZonePage())),
               GoRoute(path: 'calendar', name: 'huntingCalendar', pageBuilder: (context, state) => const NoTransitionPage(child: HuntingCalendarPage())),
               GoRoute(path: 'diary', name: 'huntingDiary', pageBuilder: (context, state) => const NoTransitionPage(child: HuntingDiaryPage()), routes: [
                 GoRoute(path: ':id', name: 'huntingDiaryDetail', pageBuilder: (context, state) => NoTransitionPage(child: HuntingDiaryDetailPage(outingId: state.pathParameters['id']!, debugPreview: Env.previewEnabled && state.uri.queryParameters['debugPreview'] == 'true'))),
               ]),
               GoRoute(path: 'map', name: 'huntingMap', pageBuilder: (context, state) => const NoTransitionPage(child: HuntingMapPage())),
               GoRoute(path: 'dogs', name: 'huntingDogs', pageBuilder: (context, state) => const NoTransitionPage(child: HuntingDogsPage()), routes: [
                 GoRoute(path: ':id', name: 'huntingDogDetail', pageBuilder: (context, state) => NoTransitionPage(child: HuntingDogDetailPage(dogId: state.pathParameters['id']!, debugPreview: Env.previewEnabled && state.uri.queryParameters['debugPreview'] == 'true'))),
               ]),
               GoRoute(path: 'sightings', name: 'huntingSightings', pageBuilder: (context, state) => const NoTransitionPage(child: HBComingSoonPage(icon: Icons.visibility_outlined, titleKey: 'hunting.sightings_title'))),
             ],
           ),
          _branch(
            AppRoutes.messages,
            'messages',
            const MessagesPage(),
            childRoutes: [
              GoRoute(
                path: ':id',
                name: 'conversationDetail',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: ConversationDetailPage(
                    conversationId: state.pathParameters['id']!,
                    debugPreview: Env.previewEnabled && state.uri.queryParameters['debugPreview'] == 'true',
                  ),
                ),
              ),
            ],
          ),
          _branch(
            AppRoutes.profile,
            'profile',
            const ProfilePage(),
            extraRoutes: [
               GoRoute(path: AppRoutes.settings, name: 'settings', pageBuilder: (context, state) => const NoTransitionPage(child: SettingsPage())),
              GoRoute(
                path: AppRoutes.publicProfile,
                name: 'publicProfile',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: PublicProfilePage(
                    username: state.pathParameters['username']!,
                    debugPreview: Env.previewEnabled && state.uri.queryParameters['debugPreview'] == 'true',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  static StatefulShellBranch _branch(
    String path,
    String name,
    Widget child, {
    List<RouteBase> childRoutes = const [],
    List<RouteBase> extraRoutes = const [],
  }) => StatefulShellBranch(
    routes: [
      GoRoute(path: path, name: name, pageBuilder: (context, state) => NoTransitionPage(child: child), routes: childRoutes),
      ...extraRoutes,
    ],
  );
}
