abstract interface class HuntingRepository {
  Future<List<String>> getRegions(String countryCode);
  Future<List<String>> getHuntingUnits(String countryCode, String? regionId);
  Future<List<String>> getCalendar(String countryCode, String? regionId, String? unitId);
}