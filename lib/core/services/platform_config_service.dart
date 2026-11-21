import 'package:hb_social/core/services/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ObservabilityConfig {
  final bool enabled;
  final String dsn;
  final String environment;
  final double tracesSampleRate;

  const ObservabilityConfig({required this.enabled, required this.dsn, required this.environment, required this.tracesSampleRate});

  factory ObservabilityConfig.fromJson(Map<String, dynamic> json) => ObservabilityConfig(
    enabled: json['sentry_enabled'] as bool? ?? false,
    dsn: json['sentry_dsn']?.toString() ?? '',
    environment: json['environment']?.toString() ?? 'dev',
    tracesSampleRate: ((json['traces_sample_rate'] as num?) ?? 0).toDouble().clamp(0, 1),
  );
}

class AuthProviderConfig {
  final bool enabled;
  final List<String> platforms;
  final bool nativeIos;

  const AuthProviderConfig({required this.enabled, required this.platforms, this.nativeIos = false});
  factory AuthProviderConfig.fromJson(Map<String, dynamic> json) => AuthProviderConfig(
    enabled: json['enabled'] == true,
    platforms: [for (final value in json['platforms'] as List? ?? const []) value.toString()],
    nativeIos: json['native_ios'] == true,
  );
}

class AuthPlatformConfig {
  final Map<String, AuthProviderConfig> providers;
  final List<String> order;
  final bool emailPassword;
  final bool magicLink;
  final bool manualLinking;

  const AuthPlatformConfig({required this.providers, required this.order, required this.emailPassword, required this.magicLink, required this.manualLinking});
  factory AuthPlatformConfig.fromJson(Map<String, dynamic> json) {
    final rawProviders = Map<String, dynamic>.from(json['providers'] as Map? ?? const {});
    return AuthPlatformConfig(
      providers: {for (final entry in rawProviders.entries) entry.key: AuthProviderConfig.fromJson(Map<String, dynamic>.from(entry.value as Map? ?? const {}))},
      order: [for (final value in json['order'] as List? ?? const []) value.toString()],
      emailPassword: json['email_password'] != false,
      magicLink: json['magic_link'] == true,
      manualLinking: json['manual_linking'] == true,
    );
  }
}

class ReleaseConfig {
  final String minAppVersion;
  final String latestAppVersion;
  final String forceUpdateBelow;
  final bool updateAvailable;
  final bool maintenanceMode;
  final Map<String, String> maintenanceMessage;
  final Map<String, String> storeUrls;
  final String webUrl;
  final List<String> firearmsShowcasePlatforms;

  const ReleaseConfig({required this.minAppVersion, required this.latestAppVersion, required this.forceUpdateBelow, required this.updateAvailable, required this.maintenanceMode, required this.maintenanceMessage, required this.storeUrls, required this.webUrl, required this.firearmsShowcasePlatforms});

  factory ReleaseConfig.fromJson(Map<String, dynamic> json) => ReleaseConfig(
    minAppVersion: json['min_app_version']?.toString() ?? '0.0.0',
    latestAppVersion: json['latest_app_version']?.toString() ?? '0.0.0',
    forceUpdateBelow: json['force_update_below']?.toString() ?? '0.0.0',
    updateAvailable: json['update_available'] == true,
    maintenanceMode: json['maintenance_mode'] == true,
    maintenanceMessage: Map<String, String>.from((json['maintenance_message'] as Map? ?? const {}).map((key, value) => MapEntry(key.toString(), value.toString()))),
    storeUrls: Map<String, String>.from((json['store_urls'] as Map? ?? const {}).map((key, value) => MapEntry(key.toString(), value.toString()))),
    webUrl: json['web_url']?.toString() ?? '',
    firearmsShowcasePlatforms: [for (final value in json['firearms_showcase_platforms'] as List? ?? const []) value.toString()],
  );

  String maintenanceText(String locale) => maintenanceMessage[locale] ?? maintenanceMessage['en'] ?? maintenanceMessage['it'] ?? '';
}

class PlatformConfig {
  final ObservabilityConfig observability;
  final AuthPlatformConfig auth;
  final List<String> supportCategories;
  final String translationsVersion;
  final ReleaseConfig release;
  final Map<String, int> legalVersions;
  final int minAge;
  final DateTime? serverTime;

  const PlatformConfig({required this.observability, required this.auth, required this.supportCategories, required this.translationsVersion, required this.release, required this.legalVersions, required this.minAge, required this.serverTime});

  factory PlatformConfig.fromJson(Map<String, dynamic> json) => PlatformConfig(
    observability: ObservabilityConfig.fromJson(Map<String, dynamic>.from(json['observability'] as Map? ?? const {})),
    auth: AuthPlatformConfig.fromJson(Map<String, dynamic>.from(json['auth'] as Map? ?? const {})),
    supportCategories: [for (final value in json['support_categories'] as List? ?? const []) value.toString()],
    translationsVersion: json['translations_version']?.toString() ?? '0',
    release: ReleaseConfig.fromJson(Map<String, dynamic>.from(json['release'] as Map? ?? const {})),
    legalVersions: Map<String, int>.from((json['legal_versions'] as Map? ?? const {}).map((key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0))),
    minAge: (json['min_age'] as num?)?.toInt() ?? 18,
    serverTime: DateTime.tryParse(json['server_time']?.toString() ?? '')?.toUtc(),
  );
}

class PlatformConfigService {
  final SupabaseClient _client;
  const PlatformConfigService(this._client);

  Future<PlatformConfig> load() async {
    try {
      final raw = await _client.rpc('app_config');
      final value = raw is List && raw.isNotEmpty ? raw.first : raw;
      return PlatformConfig.fromJson(Map<String, dynamic>.from(value as Map));
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}