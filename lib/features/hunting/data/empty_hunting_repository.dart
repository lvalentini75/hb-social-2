import 'package:hb_social/features/hunting/data/hunting_repository.dart';

class EmptyHuntingRepository implements HuntingRepository {
  const EmptyHuntingRepository();

  @override
  Future<List<String>> getRegions(String countryCode) async => const [];

  @override
  Future<List<String>> getHuntingUnits(String countryCode, String? regionId) async => const [];

  @override
  Future<List<String>> getCalendar(String countryCode, String? regionId, String? unitId) async => const [];
}