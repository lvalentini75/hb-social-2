import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/services/feature_flags_service.dart';
import 'package:hb_social/core/services/platform_config_service.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

final platformConfigServiceProvider = Provider<PlatformConfigService>((ref) => PlatformConfigService(ref.watch(supabaseClientProvider)));
final platformConfigProvider = FutureProvider<PlatformConfig>((ref) => ref.watch(platformConfigServiceProvider).load());
final featureFlagsServiceProvider = Provider<FeatureFlagsService>((ref) => FeatureFlagsService(ref.watch(supabaseClientProvider)));
final featureFlagsProvider = FutureProvider<Map<String, bool>>((ref) async {
  ref.watch(authSessionProvider);
  final country = ref.watch(userSettingsProvider.select((value) => value.countryCode));
  return ref.watch(featureFlagsServiceProvider).refresh(countryCode: country);
});

bool featureEnabled(Ref ref, String module) => ref.watch(featureFlagsProvider).value?[module] ?? false;