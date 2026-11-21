import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/services/translation_service.dart';

final translationServiceProvider = Provider<TranslationService>((ref) {
  final locale = ref.watch(userSettingsProvider.select((value) => value.locale.languageCode));
  return TranslationService(ref.watch(supabaseClientProvider), () => locale);
});

final translationUsageProvider = FutureProvider<TranslationUsage>((ref) => ref.watch(translationServiceProvider).usage());