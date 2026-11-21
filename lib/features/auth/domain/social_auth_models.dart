class SocialAuthState {
  final String userId;
  final String? email;
  final bool emailConfirmed;
  final bool hasPassword;
  final List<String> providers;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final bool avatarIsExternal;
  final String? countryCode;
  final String locale;
  final String? homeRegionId;
  final String status;
  final bool ageConfirmed;
  final bool onboardingCompleted;
  final bool needsProfileSetup;
  final int minAge;

  const SocialAuthState({required this.userId, this.email, required this.emailConfirmed, required this.hasPassword, required this.providers, this.username, this.displayName, this.avatarUrl, required this.avatarIsExternal, this.countryCode, required this.locale, this.homeRegionId, required this.status, required this.ageConfirmed, required this.onboardingCompleted, required this.needsProfileSetup, required this.minAge});
  factory SocialAuthState.fromJson(Map<String, dynamic> json) => SocialAuthState(
    userId: json['user_id'].toString(), email: json['email']?.toString(), emailConfirmed: json['email_confirmed'] == true, hasPassword: json['has_password'] == true,
    providers: [for (final value in json['providers'] as List? ?? const []) value.toString()], username: json['username']?.toString(), displayName: json['display_name']?.toString(), avatarUrl: json['avatar_url']?.toString(), avatarIsExternal: json['avatar_is_external'] == true,
    countryCode: json['country_code']?.toString(), locale: json['locale']?.toString() ?? 'it', homeRegionId: json['home_region_id']?.toString(), status: json['status']?.toString() ?? 'active', ageConfirmed: json['age_confirmed'] == true,
    onboardingCompleted: json['onboarding_completed'] == true, needsProfileSetup: json['needs_profile_setup'] == true, minAge: (json['min_age'] as num?)?.toInt() ?? 18,
  );
}

class UsernameAvailability {
  final String username;
  final bool available;
  final String? reason;
  const UsernameAvailability({required this.username, required this.available, this.reason});
  factory UsernameAvailability.fromJson(Map<String, dynamic> json) => UsernameAvailability(username: json['username']?.toString() ?? '', available: json['available'] == true, reason: json['reason']?.toString());
}

class AuthIdentityInfo {
  final String id;
  final String provider;
  final String? email;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
  const AuthIdentityInfo({required this.id, required this.provider, this.email, required this.createdAt, this.lastSignInAt});
  factory AuthIdentityInfo.fromJson(Map<String, dynamic> json) => AuthIdentityInfo(id: json['id'].toString(), provider: json['provider']?.toString() ?? 'email', email: json['email']?.toString(), createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), lastSignInAt: DateTime.tryParse(json['last_sign_in_at']?.toString() ?? '')?.toUtc());
}

class MyAuthIdentities {
  final List<AuthIdentityInfo> identities;
  final String? email;
  final bool hasPassword;
  final bool canUnlink;
  final bool manualLinking;
  final List<String> providersEnabled;
  const MyAuthIdentities({required this.identities, this.email, required this.hasPassword, required this.canUnlink, required this.manualLinking, required this.providersEnabled});
  factory MyAuthIdentities.fromJson(Map<String, dynamic> json) => MyAuthIdentities(
    identities: [for (final value in json['identities'] as List? ?? const []) AuthIdentityInfo.fromJson(Map<String, dynamic>.from(value as Map))], email: json['email']?.toString(), hasPassword: json['has_password'] == true, canUnlink: json['can_unlink'] == true, manualLinking: json['manual_linking'] == true,
    providersEnabled: [for (final value in json['providers_enabled'] as List? ?? const []) value.toString()],
  );
}