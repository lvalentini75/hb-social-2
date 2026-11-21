/// Global, non-translatable app configuration values.
class AppConfig {
  static const String appName = 'HB Social';
  static const String appUrl = String.fromEnvironment('HB_APP_URL', defaultValue: 'https://hbsocial.it');
  static const int minPasswordLength = 8;
  static const int onboardingStepCount = 3;
}
