import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/config/app_config.dart';
import 'package:hb_social/core/config/app_constants.dart';
import 'package:hb_social/core/l10n/app_locales.dart';
import 'package:hb_social/core/l10n/hb_translations_loader.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/i18n/locale_resolver.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/supabase/supabase_config.dart';
import 'package:hb_social/features/auth/presentation/auth_bootstrap_gate.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/settings/providers/settings_providers.dart';
import 'package:hb_social/features/notifications/providers/notification_providers.dart';
import 'package:hb_social/features/home/providers/feed_providers.dart';
import 'package:hb_social/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/platform_config_service.dart';
import 'package:hb_social/features/calls/providers/calls_providers.dart';
import 'package:hb_social/core/widgets/release_gate.dart';
import 'package:hb_social/features/legal/presentation/legal_consent_gate.dart';
import 'package:hb_social/core/services/seo_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Main entry point for HB Social.
///
/// This sets up:
/// - easy_localization with device language detection and English fallback
/// - intl date formatting data for every supported locale (used by the Home
///   greeting header's date line)
/// - Riverpod for state management
/// - go_router navigation
/// - Material 3 theming with the HB Social brand palette
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final deviceLocale = LocaleResolver.fromDevice().locale;
  final startupTasks = <Future<dynamic>>[EasyLocalization.ensureInitialized(), SupabaseConfig.initialize()];
  if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) startupTasks.add(Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform));
  timeago.setLocaleMessages('it', timeago.ItMessages());
  timeago.setLocaleMessages('en', timeago.EnMessages());
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  timeago.setLocaleMessages('es', timeago.EsMessages());
  timeago.setLocaleMessages('de', timeago.DeMessages());
  startupTasks.addAll(AppLocales.supported.map((locale) => initializeDateFormatting(locale.languageCode)));
  await Future.wait(startupTasks).timeout(const Duration(seconds: 8));
  if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final app =
    EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: AppLocales.translationsPath,
      assetLoader: const HBTranslationsLoader(),
      startLocale: deviceLocale,
      fallbackLocale: AppLocales.fallback,
      useFallbackTranslations: true,
      saveLocale: true,
      useOnlyLangCode: true,
      child: const ProviderScope(child: MyApp()),
    );
  try {
    final config = await PlatformConfigService(Supabase.instance.client).load().timeout(const Duration(seconds: 3));
    final observability = config.observability;
    if (observability.enabled && observability.dsn.isNotEmpty) {
      await SentryFlutter.init((options) {
        options.dsn = observability.dsn;
        options.environment = observability.environment;
        options.release = AppConstants.appVersion;
        options.tracesSampleRate = observability.tracesSampleRate;
        options.sendDefaultPii = false;
        options.beforeSend = (event, hint) async => event.throwable is AppException ? null : event;
      }, appRunner: () => runApp(app));
      return;
    }
  } catch (_) {}
  runApp(app);
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  static bool _seoListenerInstalled = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SeoService.setLanguage(context.locale.languageCode);
    if (!_seoListenerInstalled) {
      _seoListenerInstalled = true;
      void updateSeo() {
        final path = AppRouter.router.routeInformationProvider.value.uri.path;
        final public = path == AppRoutes.download || path.startsWith('/legal/') || path.startsWith('/p/') || path.startsWith('/events/') || path.startsWith('/u/');
        SeoService.update(title: public ? 'seo.public_title'.tr() : 'seo.private_title'.tr(), description: public ? 'seo.public_description'.tr() : 'seo.private_description'.tr(), path: path);
      }
      AppRouter.router.routeInformationProvider.addListener(updateSeo);
      WidgetsBinding.instance.addPostFrameCallback((_) => updateSeo());
    }
    ErrorMapper.onAccountSuspended = () {
      ref.invalidate(currentProfileProvider);
      AppRouter.router.refresh();
    };
    ref.listen(userSettingsProvider.select((settings) => settings.locale), (_, locale) {
      if (context.locale != locale) context.setLocale(locale);
      SeoService.setLanguage(locale.languageCode);
    });
    ref.listen(authSessionProvider, (_, __) => AppRouter.router.refresh());
    ref.listen(authProfileStateProvider, (_, __) => AppRouter.router.refresh());
    ref.listen(authSessionProvider, (_, __) => _reloadTranslationsIfChanged(context));
    ref.listen(currentProfileProvider, (_, __) => AppRouter.router.refresh());
    ref.listen(privateUserSettingsProvider, (_, __) => AppRouter.router.refresh());
    ref.watch(pushNotificationsControllerProvider);
    ref.watch(realtimeControllerProvider);
    ref.listen(activeCallProvider, (_, next) {
      final call = next.value;
      if (call == null || call.terminal) return;
      final path = AppRouter.router.routeInformationProvider.value.uri.path;
      if (!path.startsWith(AppRoutes.calls)) AppRouter.router.go(AppRoutes.callPath(call.id, incoming: call.direction == 'incoming' && call.status == 'ringing'));
    });
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,

      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      builder: (context, child) => ReleaseGate(child: LegalConsentGate(child: AuthBootstrapGate(child: child ?? const SizedBox.shrink()))),

      routerConfig: AppRouter.router,
    );
  }

  Future<void> _reloadTranslationsIfChanged(BuildContext context) async {
    try {
      final config = await PlatformConfigService(Supabase.instance.client).load();
      final preferences = await SharedPreferences.getInstance();
      final previous = preferences.getString('hb_translations_version');
      if (previous == config.translationsVersion) return;
      await preferences.setString('hb_translations_version', config.translationsVersion);
      if (context.mounted) await context.setLocale(context.locale);
    } catch (_) {}
  }
}
