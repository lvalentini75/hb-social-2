class AppConstants {
  static const String appVersion = '1.0.0';

  static int compareVersions(String left, String right) {
    final a = _parts(left);
    final b = _parts(right);
    for (var index = 0; index < 3; index++) {
      final comparison = a[index].compareTo(b[index]);
      if (comparison != 0) return comparison;
    }
    return 0;
  }

  static List<int> _parts(String value) {
    final raw = value.split('-').first.split('.');
    return List.generate(3, (index) => index < raw.length ? int.tryParse(raw[index]) ?? 0 : 0);
  }
}