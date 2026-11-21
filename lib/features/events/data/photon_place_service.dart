import 'package:dio/dio.dart';
import 'package:hb_social/core/services/app_exception.dart';

class PhotonPlace {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const PhotonPlace({required this.name, required this.address, required this.latitude, required this.longitude});

  factory PhotonPlace.fromFeature(Map<String, dynamic> feature) {
    final properties = Map<String, dynamic>.from(feature['properties'] as Map? ?? const {});
    final coordinates = ((feature['geometry'] as Map?)?['coordinates'] as List? ?? const []).whereType<num>().toList();
    final street = [properties['street'], properties['housenumber']].where((value) => value?.toString().trim().isNotEmpty == true).join(' ');
    final city = [properties['postcode'], properties['city'] ?? properties['locality']].where((value) => value?.toString().trim().isNotEmpty == true).join(' ');
    final address = [street, city, properties['state'], properties['country']].where((value) => value?.toString().trim().isNotEmpty == true).join(', ');
    return PhotonPlace(name: (properties['name'] ?? properties['city'] ?? properties['locality'] ?? address).toString(), address: address, latitude: coordinates.length > 1 ? coordinates[1].toDouble() : 0, longitude: coordinates.isNotEmpty ? coordinates[0].toDouble() : 0);
  }
}

class PhotonPlaceService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://photon.komoot.io'));

  Future<List<PhotonPlace>> search(String query, {String language = 'it'}) async {
    if (query.trim().length < 3) return const [];
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/', queryParameters: {'q': query.trim(), 'limit': 6, 'lang': language});
      return ((response.data?['features'] as List?) ?? const []).whereType<Map>().map((item) => PhotonPlace.fromFeature(Map<String, dynamic>.from(item))).where((item) => item.latitude != 0 || item.longitude != 0).toList();
    } catch (_) { throw const AppException('event_location.search_error'); }
  }

  Future<PhotonPlace?> reverse(double latitude, double longitude, {String language = 'it'}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/reverse', queryParameters: {'lat': latitude, 'lon': longitude, 'lang': language});
      final features = (response.data?['features'] as List?) ?? const [];
      return features.isEmpty ? null : PhotonPlace.fromFeature(Map<String, dynamic>.from(features.first as Map));
    } catch (_) { throw const AppException('event_location.search_error'); }
  }
}