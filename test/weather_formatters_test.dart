import 'package:flutter_test/flutter_test.dart';
import 'package:hb_social/features/weather/presentation/weather_formatters.dart';

void main() {
  test('wind direction uses a 16-point compass', () {
    expect(windDirection16(0), 'N');
    expect(windDirection16(22.5), 'NNE');
    expect(windDirection16(225), 'SW');
    expect(windDirection16(359), 'N');
  });

  test('wind force follows the requested thresholds', () {
    expect(beaufortKey(1.9), 'calm');
    expect(beaufortKey(2), 'light_air');
    expect(beaufortKey(29), 'strong_breeze');
    expect(beaufortKey(62), 'gale');
  });
}