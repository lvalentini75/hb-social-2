import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

class MapGeometry {
  const MapGeometry._();
  static const double earthRadiusM = 6371000;

  static double areaM2(List<LatLng> ring) {
    if (ring.length < 3) return 0;
    final lat0 = ring.map((point) => point.latitude).reduce((a, b) => a + b) / ring.length;
    var sum = 0.0;
    for (var index = 0; index < ring.length; index++) {
      final current = ring[index]; final next = ring[(index + 1) % ring.length];
      final x1 = _radians(current.longitude) * earthRadiusM * math.cos(_radians(lat0));
      final y1 = _radians(current.latitude) * earthRadiusM;
      final x2 = _radians(next.longitude) * earthRadiusM * math.cos(_radians(lat0));
      final y2 = _radians(next.latitude) * earthRadiusM;
      sum += x1 * y2 - x2 * y1;
    }
    return sum.abs() / 2;
  }

  static double perimeterM(List<LatLng> ring) {
    if (ring.length < 2) return 0;
    const distance = Distance();
    var total = 0.0;
    for (var index = 1; index < ring.length; index++) total += distance(ring[index - 1], ring[index]);
    if (ring.length >= 3) total += distance(ring.last, ring.first);
    return total;
  }

  static bool contains(List<LatLng> ring, LatLng point) {
    if (ring.length < 3) return false;
    var inside = false; var previous = ring.length - 1;
    for (var index = 0; index < ring.length; index++) {
      final a = ring[index]; final b = ring[previous];
      if ((a.latitude > point.latitude) != (b.latitude > point.latitude) && point.longitude < (b.longitude - a.longitude) * (point.latitude - a.latitude) / (b.latitude - a.latitude) + a.longitude) inside = !inside;
      previous = index;
    }
    return inside;
  }

  static Map<String, dynamic> polygon(List<LatLng> points) => {'type': 'Polygon', 'coordinates': [[for (final point in points) [point.longitude, point.latitude]]]};
  static double _radians(double value) => value * math.pi / 180;
}