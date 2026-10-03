import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/config/app_config.dart';
import 'package:hb_social/core/l10n/app_locales.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/auth/providers/user_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Main entry point for HB Social.
///
/// This sets up:
/// - easy_localization for multilingual support (default locale: Italian)
/// - Riverpod for state management, with SharedPreferences injected for
///   local-only persistence until the Supabase backend is connected
/// - go_router navigation
/// - Material 3 theming with the HB Social brand palette
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: AppLocales.translationsPath,
      fallbackLocale: AppLocales.fallback,
      startLocale: AppLocales.it,
      child: ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,

      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,

      routerConfig: AppRouter.router,
    );
  }
}
