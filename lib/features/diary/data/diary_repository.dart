import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/diary/domain/diary_season.dart';
import 'package:hb_social/features/diary/domain/diary_season_stats.dart';
import 'package:hb_social/features/diary/domain/outing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OutingInput {
  final String? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? title;
  final String? zoneName;
  final String? regionId;
  final String? huntingUnitId;
  final String? municipalityId;
  final HuntingMethod method;
  final String? notes;
  final OutingVisibility visibility;
  final int? distanceM;
  final OutingWeather? weather;
  final OutingPoint? point;
  final List<OutingSpecies> species;
  final List<String> dogIds;
  const OutingInput({this.id, required this.startedAt, this.endedAt, this.title, this.zoneName, this.regionId, this.huntingUnitId, this.municipalityId, required this.method, this.notes, required this.visibility, this.distanceM, this.weather, this.point, required this.species, required this.dogIds});
}

class OutingMediaInput {
  final String path;
  final String kind;
  final int? width;
  final int? height;
  final int? durationMs;
  final String? thumbnailPath;
  final int sizeBytes;
  final String? caption;
  const OutingMediaInput({required this.path, required this.kind, this.width, this.height, this.durationMs, this.thumbnailPath, required this.sizeBytes, this.caption});
  Map<String, dynamic> toJson() => {'path': path, 'kind': kind, 'width': width, 'height': height, 'duration_ms': durationMs, 'thumbnail_path': thumbnailPath, 'size_bytes': sizeBytes, 'caption': caption};
}

class DiaryRepository {
  final SupabaseClient _client;
  const DiaryRepository(this._client);

  String get _locale => 'it';

  Future<List<Outing>> listOutings({String? userId, String? season, int offset = 0}) async {
    try {
      final rows = await _client.rpc('list_outings', params: {'p_user': userId, 'p_season': season, 'p_limit': 20, 'p_offset': offset});
      return [for (final row in rows as List) Outing.fromJson(Map<String, dynamic>.from(row as Map), _locale)];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<Outing>> listAllOutings({String? userId, required String season}) async {
    final result = <Outing>[];
    while (true) {
      final page = await listOutings(userId: userId, season: season, offset: result.length);
      result.addAll(page);
      if (page.length < 20) return result;
    }
  }

  Future<DiarySeasonStats> seasonStats({String? userId, String? season}) async {
    try {
      final value = await _client.rpc('diary_season_stats', params: {'p_user': userId, 'p_season': season});
      final json = value is Map ? Map<String, dynamic>.from(value) : Map<String, dynamic>.from((value as List).first as Map);
      return DiarySeasonStats.fromJson(json);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<Outing?> getOuting(String id, {String locale = 'it'}) async {
    try {
      final row = await _client.from('hunting_logs').select('id,user_id,title,zone_name,region_id,hunting_unit_id,municipality_id,started_at,ended_at,hunting_method,weather,distance_m,notes,visibility,harvest_total,media_count,species:hunting_log_species(species_id,harvest_count,seen_count,shots,notes,species:species(id,scientific_name,category,names:species_names(locale,name))),dogs:hunting_log_dogs(dog:dogs(id,name,breed,avatar_url)),media:hunting_log_media(id,path,kind,width,height,duration_ms,thumbnail_path,caption,sort_order),point:hunting_log_points(lat,lng,accuracy_m),region:regions(name),unit:hunting_units(name,unit_type),municipality:municipalities(name,province_code)').eq('id', id).maybeSingle();
      return row == null ? null : Outing.fromJson(Map<String, dynamic>.from(row), locale);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> upsertOuting(OutingInput input) async {
    try {
      final value = await _client.rpc('upsert_outing', params: {
        'p_id': input.id, 'p_started_at': input.startedAt.toUtc().toIso8601String(), 'p_ended_at': input.endedAt?.toUtc().toIso8601String(), 'p_title': input.title, 'p_zone_name': input.zoneName, 'p_region_id': input.regionId, 'p_hunting_unit_id': input.huntingUnitId, 'p_municipality_id': input.municipalityId, 'p_method': input.method.code, 'p_notes': input.notes, 'p_visibility': input.visibility.code, 'p_distance_m': input.distanceM, 'p_weather': input.weather?.toJson(), 'p_lat': input.point?.lat, 'p_lng': input.point?.lng, 'p_accuracy_m': input.point?.accuracyM, 'p_species': input.species.map((item) => item.toRpc()).toList(), 'p_dog_ids': input.dogIds,
      });
      return value as String;
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> deleteOuting(String id) async {
    try {
      final paths = (await _client.rpc('delete_outing', params: {'p_id': id}) as List).cast<String>();
      if (paths.isNotEmpty) await _client.storage.from('diary-media').remove(paths);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> addMedia(String logId, List<OutingMediaInput> items) async {
    try { await _client.rpc('add_outing_media', params: {'p_log_id': logId, 'p_items': items.map((item) => item.toJson()).toList()}); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> removeMedia(String mediaId) async {
    try {
      final paths = (await _client.rpc('remove_outing_media', params: {'p_media_id': mediaId}) as List).cast<String>();
      if (paths.isNotEmpty) await _client.storage.from('diary-media').remove(paths);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> updateMediaCaption(String mediaId, String? caption) async {
    try { await _client.rpc('update_outing_media', params: {'p_media_id': mediaId, 'p_caption': caption}); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<DiarySeason>> seasons({String? userId}) async {
    try {
      final rows = await _client.rpc('diary_seasons', params: {'p_user': userId});
      return [for (final row in rows as List) DiarySeason.fromJson(Map<String, dynamic>.from(row as Map))];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> seasonLabel(DateTime date, String countryCode) async {
    try { return await _client.rpc('hb_season_label', params: {'p_date': date.toIso8601String().substring(0, 10), 'p_country': countryCode}) as String; }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<String>> zoneSuggestions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    try {
      final rows = await _client.from('hunting_logs').select('zone_name').eq('user_id', userId).not('zone_name', 'is', null).order('zone_name');
      return (rows as List).map((row) => row['zone_name'] as String).where((value) => value.isNotEmpty).toSet().toList();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }
}