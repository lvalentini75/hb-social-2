import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/config/app_config.dart';
import 'package:hb_social/core/l10n/app_locales.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Main entry point for HB Social.
///
/// This sets up:
/// - easy_localization for multilingual support (default locale: Italian)
/// - intl date formatting data for every supported locale (used by the Home
///   greeting header's date line)
/// - Riverpod for state management
/// - go_router navigation
/// - Material 3 theming with the HB Social brand palette
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  for (final locale in AppLocales.supported) {
    await initializeDateFormatting(locale.languageCode);
  }

  runApp(
    EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: AppLocales.translationsPath,
      fallbackLocale: AppLocales.fallback,
      startLocale: AppLocales.it,
      child: const ProviderScope(child: MyApp()),
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
