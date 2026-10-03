/// App environment and feature preview configuration
/// 
/// Flavor-based configuration, independent of build mode (debug/release).
/// Allows preview features on any platform without being tied to kDebugMode.

enum AppFlavor { dev, prod }

class Env {
  /// Current flavor, read from FLAVOR environment variable
  /// Default: 'dev' (allows preview features by default)
  /// Build with: flutter run --dart-define=FLAVOR=prod (to disable previews)
  static const String _flavorString = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const AppFlavor flavor = _flavorString == 'prod' ? AppFlavor.prod : AppFlavor.dev;

  /// True if running in dev flavor (allows preview features)
  static bool get isDev => flavor == AppFlavor.dev;

  /// True if preview features are enabled (Welcome "Esplora l'app", /dev/design-system, admin "Anteprima console")
  static bool get previewEnabled => isDev;
}
