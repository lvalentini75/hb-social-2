import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/dogs/domain/dog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class DogsRepository {
  final SupabaseClient _client;
  final MediaUploadService _uploads;
  List<DogBreed>? _breedCache;

  DogsRepository(this._client) : _uploads = MediaUploadService(_client);

  String get _userId {
    final value = _client.auth.currentUser?.id;
    if (value == null) throw const AppException('errors.login_required');
    return value;
  }

  String get currentUserId => _userId;

  Future<List<DogBreed>> breeds() async {
    if (_breedCache != null) return _breedCache!;
    try {
      final rows = await _client.rpc('list_dog_breeds');
      return _breedCache = [for (final row in rows as List) DogBreed.fromJson(Map<String, dynamic>.from(row as Map))];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<Dog>> myDogs() => dogsOf(_userId);

  Future<List<Dog>> dogsOf(String userId) async {
    try {
      final rows = await _client.rpc('dogs_of', params: {'p_user': userId});
      return [for (final row in rows as List) Dog.fromJson(Map<String, dynamic>.from(row as Map))];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<DogProfile> profile(String dogId) async {
    try {
      final value = await _client.rpc('dog_profile', params: {'p_dog_id': dogId});
      if (value == null) throw const AppException('dogs.errors.not_found');
      final json = Map<String, dynamic>.from(value is List ? value.first as Map : value as Map);
      for (final item in json['recent_posts'] as List? ?? const []) {
        final post = item as Map;
        post['media_url'] = storagePublicUrl(_client, 'post-media', post['media_path'] as String?);
      }
      return DogProfile.fromJson(json);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> upsert(DogInput input) async {
    try {
      return await _client.rpc('upsert_dog', params: {'p_id': input.id, 'p_name': input.name.trim(), 'p_breed_id': input.breedId, 'p_sex': input.sex, 'p_birth_date': input.birthDate?.toIso8601String().substring(0, 10), 'p_description': _blank(input.description), 'p_color': _blank(input.color), 'p_weight_kg': input.weightKg, 'p_pedigree_number': _blank(input.pedigreeNumber), 'p_microchip_number': _blank(input.microchipNumber), 'p_father_name': _blank(input.fatherName), 'p_mother_name': _blank(input.motherName), 'p_kennel_name': _blank(input.kennelName), 'p_breeder_page_id': input.breederPageId, 'p_avatar_url': input.avatarUrl, 'p_cover_url': input.coverUrl, 'p_visibility': input.visibility.code}) as String;
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> setStatus(String dogId, DogStatus status, {DateTime? deceasedOn}) async {
    try { await _client.rpc('set_dog_status', params: {'p_id': dogId, 'p_status': status.code, 'p_deceased_on': deceasedOn?.toIso8601String().substring(0, 10)}); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> delete(String dogId) async {
    try {
      final value = await _client.rpc('delete_dog', params: {'p_id': dogId});
      final paths = (value as List? ?? const []).map((item) => item.toString()).toList();
      if (paths.isNotEmpty) await _client.storage.from('dog-docs').remove(paths);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> uploadAvatar(String dogId, Uint8List bytes, ValueChanged<double> onProgress) => _upload('avatars', dogId, bytes, onProgress);
  Future<String> uploadCover(String dogId, Uint8List bytes, ValueChanged<double> onProgress) => _upload('covers', dogId, bytes, onProgress);

  Future<String> upsertTrial(DogTrialInput input) async {
    try {
      return (await _client.rpc('upsert_dog_trial', params: {'p_dog_id': input.dogId, 'p_id': input.id, 'p_kind': input.kind, 'p_title': input.title.trim(), 'p_trial_date': _date(input.date), 'p_place': _blank(input.place), 'p_organizer': _blank(input.organizer), 'p_judge': _blank(input.judge), 'p_result': _blank(input.result), 'p_points': _blank(input.points), 'p_notes': _blank(input.notes), 'p_event_id': input.eventId, 'p_certificate_path': input.certificatePath})).toString();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> deleteTrial(String id) async {
    try {
      final result = await _client.rpc('delete_dog_trial', params: {'p_id': id});
      final paths = (result as List? ?? const []).map((item) => item.toString()).toList();
      if (paths.isNotEmpty) await _client.storage.from('dog-docs').remove(paths);
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> uploadCertificate(String dogId, Uint8List bytes, String extension, ValueChanged<double> onProgress) async {
    final ext = extension.toLowerCase() == 'jpeg' ? 'jpg' : extension.toLowerCase();
    if (!const {'pdf', 'jpg', 'png', 'webp'}.contains(ext)) throw const AppException('errors.file_type_not_allowed');
    if (bytes.length > 10 * 1024 * 1024) throw const AppException('errors.file_too_large');
    final path = '$_userId/$dogId/${const Uuid().v4()}.$ext';
    final mime = ext == 'pdf' ? 'application/pdf' : ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg';
    return (await _uploads.uploadBytes(bucket: 'dog-docs', path: path, bytes: bytes, contentType: mime, onProgress: onProgress, isPublic: false)).path;
  }

  Future<String> certificateUrl(String path) async {
    try { return await _client.storage.from('dog-docs').createSignedUrl(path, 3600); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> upsertHealth(DogHealthInput input) async {
    try { return (await _client.rpc('upsert_dog_health', params: {'p_dog_id': input.dogId, 'p_id': input.id, 'p_kind': input.kind, 'p_title': input.title.trim(), 'p_performed_on': _date(input.performedOn), 'p_due_on': input.dueOn == null ? null : _date(input.dueOn!), 'p_vet_name': _blank(input.vetName), 'p_notes': _blank(input.notes)})).toString(); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> deleteHealth(String id) async {
    try { await _client.rpc('delete_dog_health', params: {'p_id': id}); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<DogReminder>> reminders({int days = 30}) async {
    if (_client.auth.currentUser == null) return const [];
    try { final rows = await _client.rpc('my_dog_reminders', params: {'p_days': days}); return [for (final row in rows as List) DogReminder.fromJson(Map<String, dynamic>.from(row as Map))]; }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<DogSearchResult>> search({String? query, String? breedId, int limit = 30, int offset = 0}) async {
    try {
      final rows = await _client.rpc('search_dogs', params: {'p_query': _blank(query), 'p_breed_id': breedId, 'p_limit': limit, 'p_offset': offset});
      return [for (final row in rows as List) DogSearchResult.fromJson(Map<String, dynamic>.from(row as Map))];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<Dog>> breederDogs(String pageId) async {
    try {
      final rows = await _client.from('dogs').select().eq('breeder_page_id', pageId).neq('status', 'deceased').order('name');
      return [for (final row in rows as List) Dog.fromJson(Map<String, dynamic>.from(row as Map))];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> tagPostDogs(String postId, List<String> dogIds) async {
    try { await _client.rpc('tag_post_dogs', params: {'p_post_id': postId, 'p_dog_ids': dogIds}); }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<String>> postDogIds(String postId) async {
    try { final rows = await _client.from('post_dogs').select('dog_id').eq('post_id', postId); return [for (final row in rows as List) row['dog_id'] as String]; }
    catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<List<DogEventChoice>> trialEvents() async {
    try {
      final participantRows = await _client.from('event_participants').select('event_id').eq('user_id', _userId).neq('status', 'cancelled');
      final ownedRows = await _client.from('events').select('id').or('organizer_user_id.eq.$_userId,created_by.eq.$_userId');
      final ids = {...(participantRows as List).map((row) => row['event_id'] as String), ...(ownedRows as List).map((row) => row['id'] as String)}.toList();
      if (ids.isEmpty) return const [];
      final rows = await _client.from('events').select('id,title,category,description').inFilter('id', ids).order('starts_at', ascending: false);
      return [for (final row in rows as List) if (_isCynologyEvent(Map<String, dynamic>.from(row as Map))) DogEventChoice(id: row['id'] as String, title: row['title'] as String)];
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  bool _isCynologyEvent(Map<String, dynamic> row) {
    final category = row['category']?.toString().toLowerCase() ?? '';
    final text = '${row['title'] ?? ''} ${row['description'] ?? ''}'.toLowerCase();
    return category.contains('dog') || category.contains('cyn') || category == 'meetup' || RegExp(r'prova|raduno|cinofil').hasMatch(text);
  }

  Future<String> _upload(String bucket, String dogId, Uint8List bytes, ValueChanged<double> onProgress) async {
    final result = await _uploads.uploadBytes(bucket: bucket, path: '$_userId/dog_$dogId.jpg', bytes: bytes, contentType: 'image/jpeg', onProgress: onProgress, upsert: true);
    return result.publicUrl!;
  }

  String? _blank(String? value) => value?.trim().isEmpty == true ? null : value?.trim();
  String _date(DateTime value) => value.toIso8601String().substring(0, 10);
}