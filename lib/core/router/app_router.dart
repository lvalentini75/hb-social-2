import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/config/env.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/admin/presentation/admin_platform_config_page.dart';
import 'package:hb_social/features/auth/presentation/login_page.dart';
import 'package:hb_social/features/auth/presentation/signup_page.dart';
import 'package:hb_social/features/auth/presentation/welcome_page.dart';
import 'package:hb_social/features/auth/presentation/mfa_challenge_page.dart';
import 'package:hb_social/features/auth/presentation/mfa_enroll_page.dart';
import 'package:hb_social/features/auth/presentation/reset_password_page.dart';
import 'package:hb_social/features/auth/presentation/suspended_page.dart';
import 'package:hb_social/features/auth/presentation/auth_callback_page.dart';
import 'package:hb_social/features/auth/presentation/complete_profile_page.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/admin/domain/admin_module.dart';
import 'package:hb_social/features/admin/presentation/admin_dashboard_page.dart';
import 'package:hb_social/features/admin/presentation/admin_access_gate.dart';
import 'package:hb_social/features/admin/presentation/admin_forbidden_page.dart';
import 'package:hb_social/features/admin/presentation/admin_badges_page.dart';
import 'package:hb_social/features/admin/presentation/admin_login_page.dart';
import 'package:hb_social/features/admin/presentation/admin_listings_page.dart';
import 'package:hb_social/features/admin/presentation/admin_module_page.dart';
import 'package:hb_social/features/admin/presentation/admin_reports_page.dart';
import 'package:hb_social/features/admin/presentation/admin_users_page.dart';
import 'package:hb_social/features/admin/presentation/admin_approvals_page.dart';
import 'package:hb_social/features/admin/presentation/admin_calendar_editor_page.dart';
import 'package:hb_social/features/admin/presentation/admin_hunting_page.dart';
import 'package:hb_social/features/admin/presentation/admin_hunting_overview_page.dart';
import 'package:hb_social/features/admin/presentation/admin_hunting_calendars_page.dart';
import 'package:hb_social/features/admin/presentation/admin_hunting_species_page.dart';
import 'package:hb_social/features/admin/presentation/admin_map_layers_page.dart';
import 'package:hb_social/features/admin/presentation/admin_roles_page.dart';
import 'package:hb_social/features/admin/presentation/admin_platform_config_page.dart' show AdminPluginsPage;
import 'package:hb_social/features/admin/presentation/admin_audit_log_page.dart';
import 'package:hb_social/features/admin/presentation/admin_security_page.dart';
import 'package:hb_social/features/admin/presentation/admin_content_page.dart';
import 'package:hb_social/features/admin/presentation/admin_communities_page.dart';
import 'package:hb_social/features/admin/presentation/admin_finance_page.dart';
import 'package:hb_social/features/admin/presentation/admin_ads_review_page.dart';
import 'package:hb_social/features/admin/presentation/admin_advertisers_page.dart';
import 'package:hb_social/features/admin/presentation/admin_system_page.dart';
import 'package:hb_social/features/admin/presentation/admin_localization_page.dart';
import 'package:hb_social/features/admin/presentation/admin_broadcasts_page.dart';
import 'package:hb_social/features/admin/presentation/admin_support_page.dart';
import 'package:hb_social/features/admin/presentation/admin_orders_page.dart';
import 'package:hb_social/features/admin/presentation/admin_revenue_page.dart';
import 'package:hb_social/features/admin/presentation/admin_legal_editor_page.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/features/dev/presentation/design_system_page.dart';
import 'package:hb_social/features/events/presentation/event_detail_page.dart';
import 'package:hb_social/features/events/presentation/event_form_page.dart';
import 'package:hb_social/features/events/presentation/events_page.dart';
import 'package:hb_social/features/events/presentation/event_manage_page.dart';
import 'package:hb_social/features/events/presentation/event_scan_page.dart';
import 'package:hb_social/features/forums/presentation/forum_detail_page.dart';
import 'package:hb_social/features/forums/presentation/forum_create_page.dart';
import 'package:hb_social/features/forums/presentation/forum_studio_page.dart';
import 'package:hb_social/features/forums/presentation/forums_page.dart';
import 'package:hb_social/features/forums/presentation/thread_page.dart';
import 'package:hb_social/features/forums/presentation/forum_tag_page.dart';
import 'package:hb_social/features/groups/presentation/group_detail_page.dart';
import 'package:hb_social/features/groups/presentation/groups_page.dart';
import 'package:hb_social/features/groups/presentation/group_create_page.dart';
import 'package:hb_social/features/groups/presentation/group_studio_page.dart';
import 'package:hb_social/features/home/presentation/home_feed_page.dart';
import 'package:hb_social/features/feed/presentation/hashtag_page.dart';
import 'package:hb_social/features/feed/presentation/post_detail_page.dart';
import 'package:hb_social/features/feed/presentation/media_viewer.dart';
import 'package:hb_social/features/feed/presentation/widgets/post_media_grid.dart';
import 'package:hb_social/features/hunting/presentation/hunting_calendar_page.dart';
import 'package:hb_social/features/diary/presentation/diary_page.dart';
import 'package:hb_social/features/diary/presentation/outing_detail_page.dart';
import 'package:hb_social/features/diary/presentation/outing_form_page.dart';
import 'package:hb_social/features/dogs/presentation/dog_form_page.dart';
import 'package:hb_social/features/dogs/presentation/dog_profile_page.dart';
import 'package:hb_social/features/dogs/presentation/dogs_page.dart';
import 'package:hb_social/features/dogs/presentation/dog_search_page.dart';
import 'package:hb_social/features/sightings/presentation/sighting_detail_page.dart';
import 'package:hb_social/features/sightings/presentation/sighting_form_page.dart';
import 'package:hb_social/features/sightings/presentation/sightings_page.dart';
import 'package:hb_social/features/sightings/presentation/sighting_alerts_page.dart';
import 'package:hb_social/features/hunting/presentation/hunting_hub_page.dart';
import 'package:hb_social/features/map/presentation/map_page.dart';
import 'package:hb_social/features/hunting/presentation/hunting_zone_page.dart';
import 'package:hb_social/features/hunting/presentation/hunting_species_page.dart';
import 'package:hb_social/features/marketplace/presentation/listing_detail_page.dart';
import 'package:hb_social/features/marketplace/presentation/marketplace_page.dart';
import 'package:hb_social/features/marketplace/presentation/listing_form_page.dart';
import 'package:hb_social/features/marketplace/presentation/my_listings_page.dart';
import 'package:hb_social/features/marketplace/presentation/seller_profile_page.dart';
import 'package:hb_social/features/chat/presentation/conversation_page.dart';
import 'package:hb_social/features/chat/presentation/messages_page.dart';
import 'package:hb_social/features/notifications/presentation/notifications_page.dart';
import 'package:hb_social/features/notifications/presentation/notification_preferences_page.dart';
import 'package:hb_social/features/orders/presentation/order_detail_page.dart';
import 'package:hb_social/features/orders/presentation/orders_page.dart';
import 'package:hb_social/features/orders/presentation/payment_settings_page.dart';
import 'package:hb_social/features/billing/presentation/billing_page.dart';
import 'package:hb_social/features/onboarding/presentation/onboarding_page.dart';
import 'package:hb_social/features/pages/presentation/pages_list_page.dart';
import 'package:hb_social/features/pages/presentation/page_detail_page.dart';
import 'package:hb_social/features/pages/presentation/page_create_page.dart';
import 'package:hb_social/features/pages/presentation/page_studio_page.dart';
import 'package:hb_social/features/profile/presentation/profile_page.dart';
import 'package:hb_social/features/profile/presentation/public_profile_page.dart';
import 'package:hb_social/features/profile/presentation/profile_edit_page.dart';
import 'package:hb_social/features/verification/presentation/verification_page.dart';
import 'package:hb_social/features/search/presentation/search_page.dart';
import 'package:hb_social/features/search/domain/search_result.dart';
import 'package:hb_social/features/settings/presentation/settings_page.dart';
import 'package:hb_social/features/settings/presentation/privacy_security_page.dart';
import 'package:hb_social/features/settings/presentation/login_methods_page.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/settings/providers/settings_providers.dart';
import 'package:hb_social/features/stories/presentation/story_viewer.dart';
import 'package:hb_social/features/social_graph/presentation/connections_page.dart';
import 'package:hb_social/features/social_graph/presentation/friend_requests_page.dart';
import 'package:hb_social/features/social_graph/presentation/people_suggestions_page.dart';
import 'package:hb_social/features/albums/presentation/album_detail_page.dart';
import 'package:hb_social/features/albums/presentation/album_form_page.dart';
import 'package:hb_social/features/albums/presentation/album_viewer_page.dart';
import 'package:hb_social/features/ads/presentation/ad_account_page.dart';
import 'package:hb_social/features/ads/presentation/ad_campaign_detail_page.dart';
import 'package:hb_social/features/ads/presentation/ad_campaign_wizard.dart';
import 'package:hb_social/features/ads/presentation/ads_center_page.dart';
import 'package:hb_social/features/ads/presentation/ads_preferences_page.dart';
import 'package:hb_social/features/ads/presentation/my_boosts_page.dart';
import 'package:hb_social/shell/app_shell.dart';
import 'package:hb_social/shell/admin_shell.dart';
import 'package:hb_social/shell/ads_manager_shell.dart';
import 'package:hb_social/features/support/presentation/support_page.dart';
import 'package:hb_social/features/support/presentation/support_ticket_page.dart';
import 'package:hb_social/features/platform/presentation/rollout_placeholder_page.dart';
import 'package:hb_social/features/reels/presentation/reels_page.dart' deferred as deferred_reels;
import 'package:hb_social/features/reels/presentation/reel_create_page.dart' deferred as deferred_reel_create;
import 'package:hb_social/features/reels/presentation/my_reels_page.dart' deferred as deferred_my_reels;
import 'package:hb_social/features/live/presentation/live_page.dart' deferred as deferred_live;
import 'package:hb_social/features/live/presentation/live_create_page.dart' deferred as deferred_live_create;
import 'package:hb_social/features/live/presentation/my_live_streams_page.dart' deferred as deferred_my_live;
import 'package:hb_social/features/calls/presentation/call_page.dart' deferred as deferred_call;
import 'package:hb_social/features/calls/presentation/calls_page.dart' deferred as deferred_calls;
import 'package:hb_social/core/router/deferred_page.dart';
import 'package:hb_social/features/admin/presentation/admin_live_page.dart';
import 'package:hb_social/features/posts/presentation/scheduled_posts_page.dart';
import 'package:hb_social/features/pages/articles/presentation/article_detail_page.dart';
import 'package:hb_social/features/pages/articles/presentation/article_editor_page.dart';
import 'package:hb_social/features/legal/presentation/legal_document_page.dart';
import 'package:hb_social/features/platform/presentation/download_page.dart';

/// Route path constants. Use these instead of hard-coding route strings.
class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  static const String mfaChallenge = '/mfa-challenge';
  static const String mfaEnroll = '/settings/mfa';
  static const String resetPassword = '/reset-password';
  static const String suspended = '/suspended';
  static const String authCallback = '/auth/callback';
  static const String completeProfile = '/onboarding/complete-profile';
  static const String legalInformation = '/legal';
  static const String download = '/download';

  static const String home = '/';
  static const String search = '/search';
  static const String notifications = '/notifications';
  static const String groups = '/groups';
  static const String groupCreate = '/groups/new';
  static const String forum = '/forum';
  static const String forumCreate = '/forum/new';
  static const String forumTag = '/forum/tag/:tag';
  static const String pages = '/pages';
  static const String pageCreate = '/pages/new';
  static const String marketplace = '/marketplace';
  static const String marketplaceNew = '/marketplace/new';
  static const String marketplaceMine = '/marketplace/mine';
  static const String orders = '/orders';
  static const String paymentSettings = '/settings/payments';
  static const String billing = '/settings/billing';
  static const String ads = '/ads';
  static const String boosts = '/ads/boosts';
  static const String events = '/events';
  static const String eventCreate = '/events/new';
  static const String hunting = '/hunting';
  static const String huntingZone = '/hunting/zone';
  static const String huntingCalendar = '/hunting/calendar';
  static const String diary = '/diary';
  static const String huntingDiary = diary;
  static const String diaryNew = '/diary/new';
  static const String map = '/map';
  static const String huntingMap = map;
  static const String dogs = '/dogs';
  static const String huntingDogs = dogs;
  static const String dogsNew = '/dogs/new';
  static const String dogsSearch = '/dogs/search';
  static const String sightings = '/sightings';
  static const String huntingSightings = sightings;
  static const String sightingsNew = '/sightings/new';
  static const String sightingAlerts = '/sightings/alerts';
  static const String huntingSpecies = '/hunting/species/:speciesId';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String verification = '/settings/verification';
  static const String profileBadge = verification;
  static const String post = '/post/:id';
  static const String tag = '/tag/:tag';
  static const String media = '/media';
  static const String story = '/stories/:username';
  static const String settings = '/settings';
  static const String notificationSettings = '/settings/notifications';
  static const String privacySecurity = '/settings/privacy';
  static const String loginMethods = '/settings/login-methods';
  static const String support = '/support';
  static const String scheduledPosts = '/posts/scheduled';
  static const String reels = '/reels';
  static const String reelsNew = '/reels/new';
  static const String reelsMine = '/reels/mine';
  static const String live = '/live';
  static const String liveNew = '/live/new';
  static const String liveMine = '/live/mine';
  static const String calls = '/calls';
  static const String adsSettings = '/settings/ads';
  static const String friendRequests = '/friends/requests';
  static const String people = '/people';
  static const String albumCreate = '/albums/new';

  static const String designSystem = '/dev/design-system';
  static const String admin = '/admin';
  static const String adminLogin = '/admin/login';
  static const String adminForbidden = '/admin/forbidden';
  static const String adminMfaEnroll = '/admin/mfa-enroll';
  static const String adminUsers = '/admin/users';
  static const String adminReports = '/admin/reports';
  static const String adminBadges = '/admin/badges';
  static const String adminApprovals = '/admin/approvals';
  static const String adminCalendars = '/admin/calendars';
  static const String adminHunting = '/admin/hunting';
  static const String adminRoles = '/admin/roles';
  static const String adminListings = '/admin/listings';
  static const String adminPlatformConfig = '/admin/localization';
  static const String adminAuditLog = '/admin/audit';
  static const String adminSecurity = '/admin/security';
  static const String adminContent = '/admin/content';
  static const String adminLive = '/admin/live';
  static const String adminCommunities = '/admin/communities';
  static const String adminFinance = '/admin/finance';
  static const String adminAds = '/admin/ads';
  static const String adminOrders = '/admin/orders';
  static const String adminAdvertisers = '/admin/advertisers';
  static const String adminRevenue = '/admin/revenue';
  static const String adminSystem = '/admin/system';
  static const String adminNotifications = '/admin/system-notifications';
  static const String adminSupport = '/admin/support';

  /// Public profile route. Lives inside the shell as part of the Profile
  /// branch (see [AppRouter]) so it never owns its own Scaffold. Build a
  /// concrete path with [publicProfilePath].
  static const String publicProfile = '/u/:username';

  static String publicProfilePath(String username) => '/u/$username';
  static String supportTicketPath(String id) => '$support/$id';
  static String adminUserPath(String id) => '$adminUsers/$id';
  static String postPath(String id) => '/post/$id';
  static String tagPath(String tag) => '/tag/$tag';
  static String storyPath(String username) => '/stories/$username';
  static String reelPath(String postId) => '/reels/$postId';
  static String livePath(String id) => '/live/$id';
  static String callPath(String id, {bool incoming = false}) => '/calls/$id${incoming ? '?incoming=1' : ''}';
  static String albumDetailPath(String id) => '/albums/$id';
  static String albumEditPath(String id) => '/albums/$id/edit';
  static String albumMediaPath(String albumId, String mediaId) => '/albums/$albumId/m/$mediaId';

  /// Group detail route, nested under [groups] so it stays inside the shell.
  static String groupDetailPath(String id) => '/groups/$id';
  static String groupStudioPath(String slug) => '/groups/$slug/studio';

  static String pageDetailPath(String slug) => '/pages/$slug';
  static String pageStudioPath(String slug) => '/pages/$slug/studio';
  static String scheduledPostsPath({String? pageId}) => pageId == null ? scheduledPosts : '$scheduledPosts?page_id=$pageId';
  static String articlePath(String pageSlug, String slug) => '/p/$pageSlug/articoli/$slug';
  static String articleNewPath(String pageSlug) => '/p/$pageSlug/articles/new';
  static String articleEditPath(String pageSlug, String id) => '/p/$pageSlug/articles/edit/$id';

  /// Conversation thread route, nested under [messages] so it stays inside the shell.
  static String conversationDetailPath(String id) => '/messages/$id';

  static String marketplaceDetailPath(String id) => '/marketplace/$id';
  static String marketplaceEditPath(String id) => '/marketplace/$id/edit';
  static String marketplaceSellerPath(String userId) => '/marketplace/seller/$userId';
  static String orderPath(String id) => '/orders/$id';
  static String adAccountPath(String id) => adAccountCampaignsPath(id);
  static String adAccountCampaignsPath(String id) => '/ads/$id/campaigns';
  static String adAccountSectionPath(String id, String section) => '/ads/$id/$section';
  static String adCampaignPath(String id) => '/ads/campaigns/$id';
  static String adCampaignNewPath(String accountId) => '/ads/$accountId/campaigns/new';
  static String adCampaignEditPath(String accountId, String id) => '/ads/$accountId/campaigns/$id/edit';

  static String forumDetailPath(String slug) => '/forum/$slug';
  static String forumTagPath(String tag) => '/forum/tag/$tag';

  static String threadPath(String slug, String threadId) => '/forum/$slug/t/$threadId';
  static String forumStudioPath(String slug) => '/forum/$slug/studio';

  static String eventDetailPath(String id) => '/events/$id';
  static String eventEditPath(String id) => '/events/$id/edit';
  static String eventManagePath(String id) => '/events/$id/manage';
  static String eventTicketPath(String id) => '/events/$id/ticket';
  static String eventScanPath(String id) => '/events/$id/manage/scan';

  static String diaryDetailPath(String id) => '$diary/$id';
  static String diaryEditPath(String id) => '$diary/$id/edit';
  static String huntingDiaryDetailPath(String id) => diaryDetailPath(id);

  static String dogDetailPath(String id) => '$dogs/$id';
  static String dogEditPath(String id) => '$dogs/$id/edit';
  static String huntingDogDetailPath(String id) => dogDetailPath(id);
  static String huntingSpeciesPath(String id) => '$hunting/species/$id';
  static String sightingDetailPath(String id) => '$sightings/$id';
  static String sightingEditPath(String id) => '$sightings/$id/edit';

  /// Every destination that lives inside the navigation shell, in branch order.
  static final List<String> shellBranches = [
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
    if (location.startsWith('$hunting/') || location == map || location == diary || location.startsWith('$diary/') || location == dogs || location.startsWith('$dogs/') || location == sightings || location.startsWith('$sightings/')) return shellBranches.indexOf(hunting);
    final index = shellBranches.indexOf(location);
    return index == -1 ? null : index;
  }
}

/// GoRouter configuration for HB Social.
///
  /// The social surface remains reachable without authentication. The admin
  /// surface has its own role-protected shell and login.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.welcome,
    redirect: (context, state) {
      final container = ProviderScope.containerOf(context);
      final session = container.read(supabaseClientProvider).auth.currentSession;
      final isAuthRoute = state.uri.path == AppRoutes.welcome || state.uri.path == AppRoutes.login || state.uri.path == AppRoutes.signup || state.uri.path == AppRoutes.authCallback;
      final isPublicReleaseRoute = state.uri.path == AppRoutes.download || state.uri.path == AppRoutes.legalInformation || state.uri.path.startsWith('${AppRoutes.legalInformation}/');
      final bypassOnboarding = state.uri.path.startsWith('/admin') || state.uri.path == AppRoutes.mfaChallenge || state.uri.path == AppRoutes.resetPassword;
      if (session != null && !bypassOnboarding) {
        final authState = container.read(authProfileStateProvider);
        if (authState.isLoading || authState.hasError || !authState.hasValue) return null;
        if (authState.value?.needsProfileSetup == true && state.uri.path != AppRoutes.completeProfile) return AppRoutes.completeProfile;
        if (authState.value?.needsProfileSetup == false && state.uri.path == AppRoutes.completeProfile) return AppRoutes.home;
        final profile = container.read(currentProfileProvider);
        final settings = container.read(privateUserSettingsProvider);
        // Never block routing on I/O. The app-level bootstrap gate owns loading
        // and error states while these providers resolve.
        if (profile.isLoading || profile.hasError || !profile.hasValue) return null;
        final status = profile.value?.status;
        if (status == 'suspended' || status == 'banned') return state.uri.path == AppRoutes.suspended ? null : AppRoutes.suspended;
        if (state.uri.path == AppRoutes.suspended) return AppRoutes.home;
        if (settings.isLoading || settings.hasError || !settings.hasValue) return null;
        final complete = settings.value?.onboardingCompletedAt != null;
        final editingInterests = state.uri.path == AppRoutes.onboarding && state.uri.queryParameters['edit'] == 'interests';
        if (state.uri.path == AppRoutes.onboarding && !complete) return null;
        if (!complete && state.uri.path != AppRoutes.onboarding) return AppRoutes.onboarding;
        if (complete && state.uri.path == AppRoutes.onboarding && !editingInterests) return AppRoutes.home;
      }
      if (session == null && state.uri.path == AppRoutes.suspended) return AppRoutes.login;
      if (session == null && (state.uri.path == AppRoutes.scheduledPosts || state.uri.path.startsWith('/p/') && (state.uri.path.contains('/articles/edit/') || state.uri.path.endsWith('/articles/new')) || state.uri.path == AppRoutes.liveNew || state.uri.path == AppRoutes.liveMine || state.uri.path == AppRoutes.calls || state.uri.path.startsWith('${AppRoutes.calls}/') || state.uri.path == AppRoutes.reelsNew || state.uri.path == AppRoutes.reelsMine || state.uri.path == AppRoutes.ads || state.uri.path.startsWith('${AppRoutes.ads}/') || state.uri.path == AppRoutes.orders || state.uri.path.startsWith('${AppRoutes.orders}/') || state.uri.path == AppRoutes.paymentSettings || state.uri.path == AppRoutes.billing || state.uri.path == AppRoutes.albumCreate || state.uri.path.startsWith('/albums/') && state.uri.path.endsWith('/edit') || state.uri.path == AppRoutes.diary || state.uri.path == AppRoutes.diaryNew || state.uri.path.startsWith('${AppRoutes.diary}/') && state.uri.path.endsWith('/edit') || state.uri.path == AppRoutes.dogs || state.uri.path == AppRoutes.dogsNew || state.uri.path.startsWith('${AppRoutes.dogs}/') && state.uri.path.endsWith('/edit') || state.uri.path == AppRoutes.sightingsNew || state.uri.path.startsWith('${AppRoutes.sightings}/') && state.uri.path.endsWith('/edit') || state.uri.path == AppRoutes.marketplaceNew || state.uri.path == AppRoutes.marketplaceMine || state.uri.path.startsWith('${AppRoutes.marketplace}/') && state.uri.path.endsWith('/edit'))) return AppRoutes.login;
      return session != null && isAuthRoute && !isPublicReleaseRoute ? AppRoutes.home : null;
    },
    routes: [
      GoRoute(path: AppRoutes.welcome, name: 'welcome', pageBuilder: (context, state) => const NoTransitionPage(child: WelcomePage())),
      GoRoute(path: AppRoutes.login, name: 'login', pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage())),
      GoRoute(path: AppRoutes.signup, name: 'signup', pageBuilder: (context, state) => const NoTransitionPage(child: SignupPage())),
      GoRoute(path: AppRoutes.authCallback, name: 'authCallback', pageBuilder: (context, state) => const NoTransitionPage(child: AuthCallbackPage())),
      GoRoute(path: AppRoutes.completeProfile, name: 'completeProfile', pageBuilder: (context, state) => const NoTransitionPage(child: CompleteProfilePage())),
      GoRoute(path: AppRoutes.onboarding, name: 'onboarding', pageBuilder: (context, state) => NoTransitionPage(child: OnboardingPage(interestsOnly: state.uri.queryParameters['edit'] == 'interests'))),
      GoRoute(path: AppRoutes.mfaChallenge, name: 'mfaChallenge', pageBuilder: (context, state) => NoTransitionPage(child: MfaChallengePage(destination: state.uri.queryParameters['destination'] ?? AppRoutes.home))),
      GoRoute(path: AppRoutes.resetPassword, name: 'resetPassword', pageBuilder: (context, state) => const NoTransitionPage(child: ResetPasswordPage())),
      GoRoute(path: AppRoutes.suspended, name: 'suspended', pageBuilder: (context, state) => const NoTransitionPage(child: SuspendedPage())),
      GoRoute(path: AppRoutes.legalInformation, name: 'legalInformation', pageBuilder: (context, state) => const NoTransitionPage(child: LegalInformationPage()), routes: [GoRoute(path: ':kind', name: 'legalDocument', pageBuilder: (context, state) => NoTransitionPage(child: LegalDocumentPage(kind: state.pathParameters['kind']!)))]),
      GoRoute(path: AppRoutes.download, name: 'download', pageBuilder: (context, state) => const NoTransitionPage(child: DownloadPage())),
      GoRoute(path: AppRoutes.media, name: 'mediaViewer', pageBuilder: (context, state) => NoTransitionPage(child: MediaViewer(args: state.extra! as MediaViewerArgs))),
      GoRoute(path: AppRoutes.story, name: 'storyViewer', pageBuilder: (context, state) => NoTransitionPage(child: StoryViewerPage(username: state.pathParameters['username']!))),
      GoRoute(path: AppRoutes.reels, name: 'reels', pageBuilder: (context, state) => NoTransitionPage(child: DeferredPage(loader: deferred_reels.loadLibrary, builder: () => deferred_reels.ReelsGate(child: deferred_reels.ReelsPage()))), routes: [
        GoRoute(path: 'new', name: 'reelsNew', pageBuilder: (context, state) => NoTransitionPage(child: DeferredPage(loader: deferred_reel_create.loadLibrary, builder: () => deferred_reel_create.ReelCreatePage()))),
        GoRoute(path: 'mine', name: 'reelsMine', pageBuilder: (context, state) => NoTransitionPage(child: DeferredPage(loader: deferred_my_reels.loadLibrary, builder: () => deferred_my_reels.MyReelsPage()))),
        GoRoute(path: ':postId', name: 'reelDetail', pageBuilder: (context, state) => NoTransitionPage(child: DeferredPage(loader: deferred_reels.loadLibrary, builder: () => deferred_reels.ReelsGate(child: deferred_reels.ReelsPage(initialPostId: state.pathParameters['postId']))))),
      ]),
      GoRoute(path: AppRoutes.live, name: 'liveIndex', redirect: (_, __) => AppRoutes.liveMine, routes: [
        GoRoute(path: 'new', name: 'liveNew', pageBuilder: (context, state) => NoTransitionPage(child: DeferredPage(loader: deferred_live_create.loadLibrary, builder: () => deferred_live_create.LiveCreatePage()))),
        GoRoute(path: 'mine', name: 'liveMine', pageBuilder: (context, state) => NoTransitionPage(child: DeferredPage(loader: deferred_my_live.loadLibrary, builder: () => deferred_my_live.MyLiveStreamsPage()))),
        GoRoute(path: ':id', name: 'liveDetail', pageBuilder: (context, state) => NoTransitionPage(child: DeferredPage(loader: deferred_live.loadLibrary, builder: () => deferred_live.LivePage(streamId: state.pathParameters['id']!)))),
      ]),
      GoRoute(path: AppRoutes.calls, name: 'calls', pageBuilder: (context, state) => NoTransitionPage(child: DeferredPage(loader: deferred_calls.loadLibrary, builder: () => deferred_calls.CallsPage())), routes: [GoRoute(path: ':id', name: 'callDetail', pageBuilder: (context, state) => NoTransitionPage(child: DeferredPage(loader: deferred_call.loadLibrary, builder: () => deferred_call.CallPage(callId: state.pathParameters['id']!, incoming: state.uri.queryParameters['incoming'] == '1'))))]),
      GoRoute(path: '/albums/:id/m/:mediaId', name: 'albumViewer', pageBuilder: (context, state) => NoTransitionPage(child: AlbumViewerPage(albumId: state.pathParameters['id']!, mediaId: state.pathParameters['mediaId']!))),
      GoRoute(path: AppRoutes.adminLogin, name: 'adminLogin', pageBuilder: (context, state) => const NoTransitionPage(child: AdminLoginPage())),
      GoRoute(path: AppRoutes.adminForbidden, name: 'adminForbidden', pageBuilder: (context, state) => const NoTransitionPage(child: AdminForbiddenPage())),
      GoRoute(path: AppRoutes.adminMfaEnroll, name: 'adminMfaEnroll', pageBuilder: (context, state) => NoTransitionPage(child: Scaffold(backgroundColor: LightModeColors.lightBackground, body: const SafeArea(child: MfaEnrollPage(destination: AppRoutes.admin))))),
      ShellRoute(
        builder: (context, state, child) => AdminAccessGate(path: state.uri.path, child: child),
        routes: [
          GoRoute(path: AppRoutes.admin, name: 'adminDashboard', pageBuilder: (context, state) => const NoTransitionPage(child: AdminDashboardPage())),
          GoRoute(path: AppRoutes.adminUsers, name: 'adminUsers', pageBuilder: (context, state) => NoTransitionPage(child: AdminUsersPage(initialId: state.uri.queryParameters['id'])), routes: [GoRoute(path: ':id', name: 'adminUserDetail', pageBuilder: (context, state) => NoTransitionPage(child: AdminUserDetailPage(userId: state.pathParameters['id']!)))]),
          GoRoute(path: AppRoutes.adminReports, name: 'adminReports', pageBuilder: (context, state) => NoTransitionPage(child: AdminReportsPage(initialId: state.uri.queryParameters['id']))),
          GoRoute(path: AppRoutes.adminBadges, name: 'adminBadges', pageBuilder: (context, state) => const NoTransitionPage(child: AdminBadgesPage())),
          GoRoute(path: AppRoutes.adminApprovals, name: 'adminApprovals', pageBuilder: (context, state) => NoTransitionPage(child: AdminApprovalsPage(initialId: state.uri.queryParameters['id']))),
          GoRoute(path: AppRoutes.adminListings, name: 'adminListings', pageBuilder: (context, state) => NoTransitionPage(child: AdminListingsPage(initialId: state.uri.queryParameters['id']))),
          GoRoute(path: AppRoutes.adminCalendars, redirect: (_, __) => '/admin/hunting/calendars'),
          GoRoute(path: AppRoutes.adminHunting, name: 'adminHunting', pageBuilder: (context, state) => const NoTransitionPage(child: AdminHuntingOverviewPage()), routes: [
            GoRoute(path: 'calendars', name: 'adminHuntingCalendars', pageBuilder: (context, state) => const NoTransitionPage(child: AdminHuntingCalendarsPage()), routes: [GoRoute(path: 'new', name: 'adminHuntingCalendarNew', pageBuilder: (context, state) => const NoTransitionPage(child: AdminCalendarEditorPage())), GoRoute(path: ':id', name: 'adminHuntingCalendarEdit', pageBuilder: (context, state) => NoTransitionPage(child: AdminCalendarEditorPage(calendarId: state.pathParameters['id']!)))]),
            GoRoute(path: 'species', name: 'adminHuntingSpecies', pageBuilder: (context, state) => const NoTransitionPage(child: AdminHuntingSpeciesPage())),

            GoRoute(path: 'units', name: 'adminHuntingUnits', pageBuilder: (context, state) => const NoTransitionPage(child: AdminHuntingPage(initialTab: 2))),
            GoRoute(path: 'layers', name: 'adminHuntingLayers', pageBuilder: (context, state) => const NoTransitionPage(child: AdminMapLayersPage())),
            GoRoute(path: 'municipalities', name: 'adminHuntingMunicipalities', pageBuilder: (context, state) => const NoTransitionPage(child: AdminHuntingPage(initialTab: 3))),
            GoRoute(path: 'regions', name: 'adminHuntingRegions', pageBuilder: (context, state) => const NoTransitionPage(child: AdminHuntingPage(initialTab: 4))),
          ]),
          GoRoute(path: AppRoutes.adminRoles, name: 'adminRoles', pageBuilder: (context, state) => const NoTransitionPage(child: AdminRolesPage())),
          GoRoute(path: AppRoutes.adminPlatformConfig, name: 'adminPlatformConfig', pageBuilder: (context, state) => const NoTransitionPage(child: AdminLocalizationPage())),
          GoRoute(path: AppRoutes.adminAuditLog, name: 'adminAuditLog', pageBuilder: (context, state) => const NoTransitionPage(child: AdminAuditLogPage())),
          GoRoute(path: AppRoutes.adminSecurity, name: 'adminSecurity', pageBuilder: (context, state) => const NoTransitionPage(child: AdminSecurityPage())),
          GoRoute(path: AppRoutes.adminContent, name: 'adminContent', pageBuilder: (context, state) => NoTransitionPage(child: AdminContentPage(initialId: state.uri.queryParameters['id']))),
          GoRoute(path: AppRoutes.adminLive, name: 'adminLive', pageBuilder: (context, state) => const NoTransitionPage(child: AdminLivePage())),
          GoRoute(path: AppRoutes.adminCommunities, name: 'adminCommunities', pageBuilder: (context, state) => NoTransitionPage(child: AdminCommunitiesPage(initialId: state.uri.queryParameters['id']))),
          GoRoute(path: AppRoutes.adminFinance, name: 'adminFinance', pageBuilder: (context, state) => const NoTransitionPage(child: AdminFinancePage())),
          GoRoute(path: AppRoutes.adminAds, name: 'adminAds', pageBuilder: (context, state) => NoTransitionPage(child: AdminAdsReviewPage(accountFilter: state.uri.queryParameters['account'], creativeFilter: state.uri.queryParameters['creative']))),
          GoRoute(path: AppRoutes.adminOrders, name: 'adminOrders', pageBuilder: (context, state) => const NoTransitionPage(child: AdminOrdersPage())),
          GoRoute(path: AppRoutes.adminAdvertisers, name: 'adminAdvertisers', pageBuilder: (context, state) => const NoTransitionPage(child: AdminAdvertisersPage())),
          GoRoute(path: AppRoutes.adminRevenue, name: 'adminRevenue', pageBuilder: (context, state) => const NoTransitionPage(child: AdminRevenuePage())),
          GoRoute(path: AppRoutes.adminSystem, name: 'adminSystem', pageBuilder: (context, state) => const NoTransitionPage(child: AdminSystemPage())),
          GoRoute(path: '${AppRoutes.adminSystem}/legal/:kind/:version', name: 'adminLegalEditor', pageBuilder: (context, state) => NoTransitionPage(child: AdminLegalEditorPage(kind: state.pathParameters['kind']!, version: state.pathParameters['version'] == 'new' ? null : int.tryParse(state.pathParameters['version']!)))),
          GoRoute(path: AppRoutes.adminNotifications, name: 'adminNotifications', pageBuilder: (context, state) => const NoTransitionPage(child: AdminBroadcastsPage())),
          GoRoute(path: AppRoutes.adminSupport, name: 'adminSupport', pageBuilder: (context, state) => const NoTransitionPage(child: AdminSupportPage())),
          GoRoute(path: '/admin/plugins', name: 'adminPlugins', pageBuilder: (context, state) => const NoTransitionPage(child: AdminPluginsPage())),
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
      ShellRoute(
        builder: (context, state, child) => AdsManagerShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.ads, name: 'adsManager', pageBuilder: (context, state) => const NoTransitionPage(child: AdsCenterPage())),
          GoRoute(path: AppRoutes.boosts, name: 'myBoosts', pageBuilder: (context, state) => const NoTransitionPage(child: MyBoostsPage())),
          GoRoute(path: '${AppRoutes.ads}/campaigns/:campaignId', name: 'adCampaignManager', pageBuilder: (context, state) => NoTransitionPage(child: AdCampaignDetailPage(campaignId: state.pathParameters['campaignId']!))),
          GoRoute(path: '${AppRoutes.ads}/:accountId/:section', name: 'adAccountSection', pageBuilder: (context, state) => NoTransitionPage(child: AdAccountPage(accountId: state.pathParameters['accountId']!, initialSection: state.pathParameters['section']!)), routes: [
            GoRoute(path: 'new', name: 'adCampaignNewManager', pageBuilder: (context, state) => NoTransitionPage(child: AdCampaignWizardPage(accountId: state.pathParameters['accountId']!))),
            GoRoute(path: ':campaignId/edit', name: 'adCampaignEditManager', pageBuilder: (context, state) => NoTransitionPage(child: AdCampaignWizardPage(accountId: state.pathParameters['accountId']!, campaignId: state.pathParameters['campaignId']))),
          ]),
          GoRoute(path: '${AppRoutes.ads}/:accountId', redirect: (_, state) => AppRoutes.adAccountCampaignsPath(state.pathParameters['accountId']!)),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          _branch(AppRoutes.home, 'home', const HomeFeedPage(), childRoutes: [
            GoRoute(path: 'post/:id', name: 'postDetail', pageBuilder: (context, state) => NoTransitionPage(child: PostDetailPage(postId: state.pathParameters['id']!, commentId: state.uri.queryParameters['comment']))),
            GoRoute(path: 'tag/:tag', name: 'hashtag', pageBuilder: (context, state) => NoTransitionPage(child: HashtagPage(tag: state.pathParameters['tag']!))),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.search,
              name: 'search',
              pageBuilder: (context, state) => NoTransitionPage(
                child: SearchPage(
                  initialQuery: state.uri.queryParameters['q'] ?? '',
                  initialCategory: SearchCategoryApi.parse(state.uri.queryParameters['tab']),
                  autofocus: state.uri.queryParameters['focus'] == '1',
                ),
              ),
            ),
          ]),
          _branch(AppRoutes.notifications, 'notifications', const NotificationsPage()),
          _branch(
            AppRoutes.groups,
            'groups',
            const GroupsPage(),
            childRoutes: [
              GoRoute(path: 'new', name: 'groupCreate', pageBuilder: (context, state) => const NoTransitionPage(child: GroupCreatePage())),
              GoRoute(
                path: ':id',
                name: 'groupDetail',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: GroupDetailPage(groupId: state.pathParameters['id']!, debugPreview: Env.previewEnabled && state.uri.queryParameters['debugPreview'] == 'true'),
                ),
                routes: [GoRoute(path: 'studio', name: 'groupStudio', pageBuilder: (context, state) => NoTransitionPage(child: GroupStudioPage(slug: state.pathParameters['id']!)))],
              ),
            ],
          ),
          _branch(
            AppRoutes.forum,
            'forum',
            const ForumsPage(),
            childRoutes: [
              GoRoute(path: 'new', name: 'forumCreate', pageBuilder: (context, state) => const NoTransitionPage(child: ForumCreatePage())),
              GoRoute(path: 'tag/:tag', name: 'forumTag', pageBuilder: (context, state) => NoTransitionPage(child: ForumTagPage(tag: state.pathParameters['tag']!))),
              GoRoute(path: ':slug', name: 'forumDetail', pageBuilder: (context, state) => NoTransitionPage(child: ForumDetailPage(slug: state.pathParameters['slug']!)), routes: [
                GoRoute(path: 'studio', name: 'forumStudio', pageBuilder: (context, state) => NoTransitionPage(child: ForumStudioPage(slug: state.pathParameters['slug']!))),
                GoRoute(path: 't/:threadId', name: 'threadDetail', pageBuilder: (context, state) => NoTransitionPage(child: ThreadPage(slug: state.pathParameters['slug']!, threadId: state.pathParameters['threadId']!, replyId: state.uri.queryParameters['reply']))),
              ]),
            ],
          ),
          _branch(
            AppRoutes.pages,
            'pages',
            const PagesListPage(),
            childRoutes: [
              GoRoute(path: 'new', name: 'pageCreate', pageBuilder: (context, state) => const NoTransitionPage(child: PageCreatePage())),
              GoRoute(path: ':slug', name: 'pageDetail', pageBuilder: (context, state) => NoTransitionPage(child: CommunityPageDetailPage(slug: state.pathParameters['slug']!)), routes: [GoRoute(path: 'studio', name: 'pageStudio', pageBuilder: (context, state) => NoTransitionPage(child: PageStudioPage(slug: state.pathParameters['slug']!)))]),
            ],
            extraRoutes: [
              GoRoute(path: '/p/:pageSlug/articoli/:slug', name: 'articleDetail', pageBuilder: (context, state) => NoTransitionPage(child: ArticleDetailPage(pageSlug: state.pathParameters['pageSlug']!, slug: state.pathParameters['slug']!))),
              GoRoute(path: '/p/:pageSlug/articles/new', name: 'articleNew', pageBuilder: (context, state) => NoTransitionPage(child: ArticleEditorPage(pageSlug: state.pathParameters['pageSlug']!))),
              GoRoute(path: '/p/:pageSlug/articles/edit/:id', name: 'articleEdit', pageBuilder: (context, state) => NoTransitionPage(child: ArticleEditorPage(pageSlug: state.pathParameters['pageSlug']!, articleId: state.pathParameters['id']!))),
            ],
          ),
          _branch(
            AppRoutes.marketplace,
            'marketplace',
            const MarketplacePage(),
            childRoutes: [
              GoRoute(path: 'new', name: 'marketplaceNew', pageBuilder: (context, state) => const NoTransitionPage(child: ListingFormPage())),
              GoRoute(path: 'mine', name: 'marketplaceMine', pageBuilder: (context, state) => const NoTransitionPage(child: MyListingsPage())),
              GoRoute(path: 'seller/:userId', name: 'marketplaceSeller', pageBuilder: (context, state) => NoTransitionPage(child: SellerProfilePage(userId: state.pathParameters['userId']!))),
              GoRoute(
                path: ':id',
                name: 'marketplaceDetail',
                pageBuilder: (context, state) => NoTransitionPage(child: ListingDetailPage(listingId: state.pathParameters['id']!)),
                routes: [GoRoute(path: 'edit', name: 'marketplaceEdit', pageBuilder: (context, state) => NoTransitionPage(child: ListingFormPage(listingId: state.pathParameters['id']!)))],
              ),
            ],
            extraRoutes: [GoRoute(path: AppRoutes.orders, name: 'orders', pageBuilder: (context, state) => NoTransitionPage(child: OrdersPage(initialRole: state.uri.queryParameters['role'] ?? 'buyer')), routes: [GoRoute(path: ':id', name: 'orderDetail', pageBuilder: (context, state) => NoTransitionPage(child: OrderDetailPage(orderId: state.pathParameters['id']!, checkoutResult: state.uri.queryParameters['checkout'])))])],
          ),
          _branch(
            AppRoutes.events,
            'events',
            const EventsPage(),
            childRoutes: [
               GoRoute(path: 'new', name: 'eventCreate', pageBuilder: (context, state) => NoTransitionPage(child: EventFormPage(initialPageId: state.uri.queryParameters['page'], initialGroupId: state.uri.queryParameters['group']))),
              GoRoute(
                path: ':id',
                name: 'eventDetail',
                pageBuilder: (context, state) => NoTransitionPage(child: EventDetailPage(eventId: state.pathParameters['id']!, debugPreview: Env.previewEnabled && state.uri.queryParameters['debugPreview'] == 'true')),
                 routes: [
                   GoRoute(path: 'edit', name: 'eventEdit', pageBuilder: (context, state) => NoTransitionPage(child: EventFormPage(eventId: state.pathParameters['id']!))),
                   GoRoute(path: 'manage', name: 'eventManage', pageBuilder: (context, state) => NoTransitionPage(child: EventManagePage(eventId: state.pathParameters['id']!)), routes: [GoRoute(path: 'scan', name: 'eventScan', pageBuilder: (context, state) => NoTransitionPage(child: EventScanPage(eventId: state.pathParameters['id']!)))]),
                   GoRoute(path: 'ticket', name: 'eventTicket', pageBuilder: (context, state) => NoTransitionPage(child: EventTicketPage(eventId: state.pathParameters['id']!))),
                 ],
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
                GoRoute(path: 'species/:speciesId', name: 'huntingSpecies', pageBuilder: (context, state) => NoTransitionPage(child: HuntingSpeciesPage(speciesId: state.pathParameters['speciesId']!))),
             ],
              extraRoutes: [
                GoRoute(path: AppRoutes.map, name: 'map', pageBuilder: (context, state) => NoTransitionPage(child: MapPage(initialLat: double.tryParse(state.uri.queryParameters['lat'] ?? ''), initialLng: double.tryParse(state.uri.queryParameters['lng'] ?? '')))),
                GoRoute(path: AppRoutes.diary, name: 'diary', pageBuilder: (context, state) => NoTransitionPage(child: DiaryPage(initialTab: state.uri.queryParameters['tab'] == 'stats' ? 1 : 0, initialSeason: state.uri.queryParameters['season'])), routes: [GoRoute(path: 'new', name: 'diaryNew', pageBuilder: (context, state) => const NoTransitionPage(child: OutingFormPage())), GoRoute(path: ':id', name: 'diaryDetail', pageBuilder: (context, state) => NoTransitionPage(child: OutingDetailPage(outingId: state.pathParameters['id']!)), routes: [GoRoute(path: 'edit', name: 'diaryEdit', pageBuilder: (context, state) => NoTransitionPage(child: OutingFormPage(outingId: state.pathParameters['id']!)))])]),
                GoRoute(path: AppRoutes.dogs, name: 'dogs', pageBuilder: (context, state) => const NoTransitionPage(child: DogsPage()), routes: [GoRoute(path: 'new', name: 'dogNew', pageBuilder: (context, state) => const NoTransitionPage(child: DogFormPage())), GoRoute(path: 'search', name: 'dogSearch', pageBuilder: (context, state) => const NoTransitionPage(child: DogSearchPage())), GoRoute(path: ':id', name: 'dogDetail', pageBuilder: (context, state) => NoTransitionPage(child: DogProfilePage(dogId: state.pathParameters['id']!)), routes: [GoRoute(path: 'edit', name: 'dogEdit', pageBuilder: (context, state) => NoTransitionPage(child: DogFormPage(dogId: state.pathParameters['id']!)))])]),
                GoRoute(path: AppRoutes.sightings, name: 'sightings', pageBuilder: (context, state) => NoTransitionPage(child: SightingsPage(initialTab: state.uri.queryParameters['tab'] == 'nearby' ? 1 : 0, initialSpeciesId: state.uri.queryParameters['species'], initialDays: int.tryParse(state.uri.queryParameters['days'] ?? '') ?? 90, initialRadius: double.tryParse(state.uri.queryParameters['radius'] ?? '') ?? 25, initialLat: double.tryParse(state.uri.queryParameters['lat'] ?? ''), initialLng: double.tryParse(state.uri.queryParameters['lng'] ?? ''))), routes: [GoRoute(path: 'new', name: 'sightingNew', pageBuilder: (context, state) => const NoTransitionPage(child: SightingFormPage())), GoRoute(path: 'alerts', name: 'sightingAlerts', pageBuilder: (context, state) => NoTransitionPage(child: SightingAlertsPage(openForm: state.uri.queryParameters['create'] == '1'))), GoRoute(path: ':id', name: 'sightingDetail', pageBuilder: (context, state) => NoTransitionPage(child: SightingDetailPage(sightingId: state.pathParameters['id']!)), routes: [GoRoute(path: 'edit', name: 'sightingEdit', pageBuilder: (context, state) => NoTransitionPage(child: SightingFormPage(sightingId: state.pathParameters['id']!)))])]),
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
                  child: ConversationPage(conversationId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          _branch(
            AppRoutes.profile,
            'profile',
            ProfilePage(initialTab: null),
            extraRoutes: [
               GoRoute(path: AppRoutes.albumCreate, name: 'albumCreate', pageBuilder: (context, state) => const NoTransitionPage(child: AlbumFormPage())),
               GoRoute(path: '/albums/:id', name: 'albumDetail', pageBuilder: (context, state) => NoTransitionPage(child: AlbumDetailPage(albumId: state.pathParameters['id']!, openUpload: state.uri.queryParameters['upload'] == '1')), routes: [GoRoute(path: 'edit', name: 'albumEdit', pageBuilder: (context, state) => NoTransitionPage(child: AlbumFormPage(albumId: state.pathParameters['id']!)))]),
               GoRoute(path: AppRoutes.profileEdit, name: 'profileEdit', pageBuilder: (context, state) => const NoTransitionPage(child: ProfileEditPage())),
               GoRoute(path: AppRoutes.settings, name: 'settings', pageBuilder: (context, state) => const NoTransitionPage(child: SettingsPage()), routes: [GoRoute(path: 'mfa', name: 'mfaEnroll', pageBuilder: (context, state) => const NoTransitionPage(child: MfaEnrollPage())), GoRoute(path: 'login-methods', name: 'loginMethods', pageBuilder: (context, state) => const NoTransitionPage(child: LoginMethodsPage())), GoRoute(path: 'notifications', name: 'notificationSettings', pageBuilder: (context, state) => const NoTransitionPage(child: NotificationPreferencesPage())), GoRoute(path: 'privacy', name: 'privacySecurity', pageBuilder: (context, state) => const NoTransitionPage(child: PrivacySecurityPage())), GoRoute(path: 'ads', name: 'adsSettings', pageBuilder: (context, state) => const NoTransitionPage(child: AdsPreferencesPage())), GoRoute(path: 'verification', name: 'verification', pageBuilder: (context, state) => const NoTransitionPage(child: VerificationPage())), GoRoute(path: 'payments', name: 'paymentSettings', pageBuilder: (context, state) => NoTransitionPage(child: PaymentSettingsPage(returnedFromOnboarding: state.uri.queryParameters['onboarding'] == 'return'))), GoRoute(path: 'billing', name: 'billing', pageBuilder: (context, state) => NoTransitionPage(child: BillingPage(setupResult: state.uri.queryParameters['setup'])))]),
                GoRoute(path: AppRoutes.support, name: 'support', pageBuilder: (context, state) => const NoTransitionPage(child: SupportPage()), routes: [GoRoute(path: ':id', name: 'supportTicket', pageBuilder: (context, state) => NoTransitionPage(child: SupportTicketPage(ticketId: state.pathParameters['id']!)))]),
               GoRoute(path: AppRoutes.scheduledPosts, name: 'scheduledPosts', pageBuilder: (context, state) => NoTransitionPage(child: ScheduledPostsPage(pageId: state.uri.queryParameters['page_id']))),
               GoRoute(path: AppRoutes.ads, name: 'ads', pageBuilder: (context, state) => const NoTransitionPage(child: AdsCenterPage()), routes: [
                 GoRoute(path: 'campaigns/:campaignId', name: 'adCampaign', pageBuilder: (context, state) => NoTransitionPage(child: AdCampaignDetailPage(campaignId: state.pathParameters['campaignId']!))),
                 GoRoute(path: ':accountId', name: 'adAccount', pageBuilder: (context, state) => NoTransitionPage(child: AdAccountPage(accountId: state.pathParameters['accountId']!, initialSection: 'campaigns')), routes: [
                   GoRoute(path: 'campaigns', name: 'adAccountCampaigns', pageBuilder: (context, state) => NoTransitionPage(child: AdAccountPage(accountId: state.pathParameters['accountId']!, initialSection: 'campaigns'))),
                   GoRoute(path: 'audiences', name: 'adAccountAudiences', pageBuilder: (context, state) => NoTransitionPage(child: AdAccountPage(accountId: state.pathParameters['accountId']!, initialSection: 'audiences'))),
                   GoRoute(path: 'creatives', name: 'adAccountCreatives', pageBuilder: (context, state) => NoTransitionPage(child: AdAccountPage(accountId: state.pathParameters['accountId']!, initialSection: 'creatives'))),
                   GoRoute(path: 'billing', name: 'adAccountBilling', pageBuilder: (context, state) => NoTransitionPage(child: AdAccountPage(accountId: state.pathParameters['accountId']!, initialSection: 'billing'))),
                   GoRoute(path: 'report', name: 'adAccountReport', pageBuilder: (context, state) => NoTransitionPage(child: AdAccountPage(accountId: state.pathParameters['accountId']!, initialSection: 'report'))),
                   GoRoute(path: 'settings', name: 'adAccountSettings', pageBuilder: (context, state) => NoTransitionPage(child: AdAccountPage(accountId: state.pathParameters['accountId']!, initialSection: 'settings'))),
                   GoRoute(path: 'campaigns/new', name: 'adCampaignNew', pageBuilder: (context, state) => NoTransitionPage(child: AdCampaignWizardPage(accountId: state.pathParameters['accountId']!))),
                   GoRoute(path: 'campaigns/:campaignId/edit', name: 'adCampaignEdit', pageBuilder: (context, state) => NoTransitionPage(child: AdCampaignWizardPage(accountId: state.pathParameters['accountId']!, campaignId: state.pathParameters['campaignId']))),
                 ]),
               ]),
               GoRoute(path: AppRoutes.friendRequests, name: 'friendRequests', pageBuilder: (context, state) => const NoTransitionPage(child: FriendRequestsPage())),
               GoRoute(path: AppRoutes.people, name: 'people', pageBuilder: (context, state) => const NoTransitionPage(child: PeopleSuggestionsPage())),
              GoRoute(
                path: AppRoutes.publicProfile,
                name: 'publicProfile',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: PublicProfilePage(
                    username: state.pathParameters['username']!,
                    debugPreview: Env.previewEnabled && state.uri.queryParameters['debugPreview'] == 'true',
                     initialTab: state.uri.queryParameters['tab'],
                   ),
                 ),
                 routes: [GoRoute(path: 'connections', name: 'connections', pageBuilder: (context, state) => NoTransitionPage(child: ConnectionsPage(username: state.pathParameters['username']!, initialTab: state.uri.queryParameters['tab'] ?? 'followers')))],
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
