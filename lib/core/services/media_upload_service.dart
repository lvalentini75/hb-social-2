import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/camera_capture_result.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/video_poster_service.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:hb_social/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PreparedUpload {
  final Uint8List bytes;
  final String extension;
  final String contentType;
  final int? width;
  final int? height;
  final int? durationMs;
  final VideoPoster? poster;
  final String? fileName;
  final String? mediaKind;
  final DateTime? takenAt;

  const PreparedUpload({required this.bytes, required this.extension, required this.contentType, this.width, this.height, this.durationMs, this.poster, this.fileName, this.mediaKind, this.takenAt});
}

class UploadedMedia {
  final String path;
  final String? publicUrl;

  const UploadedMedia({required this.path, this.publicUrl});
}

/// Broadcasts the progress of one upload from zero to one.
class UploadProgress {
  final _controller = StreamController<double>.broadcast();

  Stream<double> get stream => _controller.stream;

  void add(double value) => _controller.add(value.clamp(0, 1));
  Future<void> close() => _controller.close();
}

/// Picks, resizes and stores user-owned media without relying on platform files.
class MediaUploadService {
  final SupabaseClient _client;
  final Dio _dio;

  MediaUploadService(this._client) : _dio = Dio();

  Future<Uint8List?> pickImageBytes() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'], allowMultiple: false, withData: true);
    if (result == null) return null;
    final file = result.files.single;
    if (file.bytes == null) throw const AppException('errors.file_unreadable');
    if (file.bytes!.length > 50 * 1024 * 1024) throw const AppException('errors.file_too_large');
    if (img.decodeImage(file.bytes!) == null) throw const AppException('errors.image_processing_failed');
    return file.bytes!;
  }

  /// Resizes and encodes one camera photo with the shared upload envelope.
  PreparedUpload prepareCapturedImage(CapturedMedia media, {int maxDimension = 2048, int quality = 85}) {
    if (media.bytes.length > 50 * 1024 * 1024) throw const AppException('errors.file_too_large');
    final decoded = img.decodeImage(media.bytes);
    if (decoded == null) throw const AppException('errors.image_processing_failed');
    final longest = max(decoded.width, decoded.height);
    final resized = longest <= maxDimension
        ? decoded
        : img.copyResize(decoded, width: decoded.width >= decoded.height ? maxDimension : null, height: decoded.height > decoded.width ? maxDimension : null, interpolation: img.Interpolation.average);
    return PreparedUpload(bytes: Uint8List.fromList(img.encodeJpg(resized, quality: quality)), extension: 'jpg', contentType: 'image/jpeg', width: resized.width, height: resized.height, fileName: media.name, mediaKind: 'image');
  }

  /// Wraps one recorded video and extracts its poster frame.
  Future<PreparedUpload> prepareCapturedVideo(CapturedMedia media, {int maxBytes = 100 * 1024 * 1024}) async {
    if (media.bytes.length > maxBytes) throw const AppException('errors.file_too_large');
    final extension = const {'mp4', 'mov'}.contains(media.extension) ? media.extension : 'mp4';
    final poster = await const VideoPosterService().extract(PlatformFile(name: media.name, size: media.bytes.length, bytes: media.bytes));
    return PreparedUpload(bytes: media.bytes, extension: extension, contentType: extension == 'mov' ? 'video/quicktime' : 'video/mp4', width: poster?.width, height: poster?.height, durationMs: poster?.durationMs, poster: poster, fileName: media.name, mediaKind: 'video');
  }

  PreparedUpload prepareJpeg(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const AppException('errors.image_processing_failed');
    return PreparedUpload(bytes: bytes, extension: 'jpg', contentType: 'image/jpeg', width: decoded.width, height: decoded.height, mediaKind: 'image');
  }

  Future<PreparedUpload?> pickAndPrepareImage({required int maxDimension}) async {
    final result = await FilePicker.pickFiles(type: FileType.image, allowMultiple: false, withData: true);
    if (result == null) return null;
    final bytes = result.files.single.bytes;
    if (bytes == null) throw const AppException('profile.edit.image_error');
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const AppException('profile.edit.image_error');
    final longest = max(decoded.width, decoded.height);
    final prepared = longest <= maxDimension
        ? decoded
        : img.copyResize(decoded, width: decoded.width >= decoded.height ? maxDimension : null, height: decoded.height > decoded.width ? maxDimension : null, interpolation: img.Interpolation.average);
    return PreparedUpload(bytes: Uint8List.fromList(img.encodeJpg(prepared, quality: 85)), extension: 'jpg', contentType: 'image/jpeg', width: prepared.width, height: prepared.height);
  }

  Future<List<PreparedUpload>> pickPostImages({required int remaining}) async {
    final files = <({Uint8List bytes, String extension})>[];
    if (kIsWeb) {
      final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'], allowMultiple: true, withData: true);
      if (result == null) return const [];
      for (final file in result.files.take(remaining)) {
        if (file.bytes == null) throw const AppException('errors.upload_failed');
        files.add((bytes: file.bytes!, extension: (file.extension ?? '').toLowerCase()));
      }
    } else {
      final picked = await ImagePicker().pickMultiImage(limit: remaining);
      for (final file in picked.take(remaining)) {
        files.add((bytes: await file.readAsBytes(), extension: file.name.split('.').last.toLowerCase()));
      }
    }
    final prepared = <PreparedUpload>[];
    for (final file in files) {
      if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(file.extension)) throw const AppException('errors.file_type_not_allowed');
      if (file.bytes.length > 10 * 1024 * 1024) throw const AppException('errors.file_too_large');
      final decoded = img.decodeImage(file.bytes);
      if (decoded == null) throw const AppException('errors.file_type_not_allowed');
      final longest = max(decoded.width, decoded.height);
      final resized = longest <= 2048
          ? decoded
          : img.copyResize(decoded, width: decoded.width >= decoded.height ? 2048 : null, height: decoded.height > decoded.width ? 2048 : null, interpolation: img.Interpolation.average);
      prepared.add(PreparedUpload(bytes: Uint8List.fromList(img.encodeJpg(resized, quality: 85)), extension: 'jpg', contentType: 'image/jpeg', width: resized.width, height: resized.height));
    }
    return prepared;
  }

  /// Selects chat images and applies the chat-specific 1600px/quality envelope.
  Future<List<PreparedUpload>> pickChatImages({int limit = 5}) async {
    final selected = <({Uint8List bytes, String extension, String name})>[];
    if (!kIsWeb) {
      final images = await ImagePicker().pickMultiImage(limit: limit);
      for (final image in images.take(limit)) { selected.add((bytes: await image.readAsBytes(), extension: image.name.split('.').last.toLowerCase(), name: image.name)); }
    } else {
      final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'], allowMultiple: true, withData: true);
      if (result == null) return const [];
      for (final file in result.files.take(limit)) { if (file.bytes == null) throw const AppException('errors.file_unreadable'); selected.add((bytes: file.bytes!, extension: (file.extension ?? '').toLowerCase(), name: file.name)); }
    }
    final uploads = <PreparedUpload>[];
    for (final file in selected) {
      final bytes = file.bytes;
      if (bytes.length > 25 * 1024 * 1024) throw const AppException('errors.file_too_large');
      final extension = file.extension;
      final decoded = img.decodeImage(bytes);
      if (decoded == null || !const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) throw const AppException('errors.file_type_not_allowed');
      final longest = max(decoded.width, decoded.height);
      final resized = longest <= 1600 ? decoded : img.copyResize(decoded, width: decoded.width >= decoded.height ? 1600 : null, height: decoded.height > decoded.width ? 1600 : null, interpolation: img.Interpolation.average);
      final keepOriginal = bytes.length <= 2 * 1024 * 1024 && const {'png', 'webp'}.contains(extension) && longest <= 1600;
      uploads.add(PreparedUpload(bytes: keepOriginal ? bytes : Uint8List.fromList(img.encodeJpg(resized, quality: 82)), extension: keepOriginal ? extension : 'jpg', contentType: keepOriginal ? (extension == 'png' ? 'image/png' : 'image/webp') : 'image/jpeg', width: resized.width, height: resized.height, fileName: file.name, mediaKind: 'image'));
    }
    return uploads;
  }

  Future<PreparedUpload?> pickPostVideo() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['mp4', 'mov'], allowMultiple: false, withData: true);
    if (result == null) return null;
    final file = result.files.single;
    final posterFuture = const VideoPosterService().extract(file);
    if (file.bytes == null) throw const AppException('errors.upload_failed');
    final extension = (file.extension ?? '').toLowerCase();
    if (!const {'mp4', 'mov'}.contains(extension)) throw const AppException('errors.file_type_not_allowed');
    if (file.bytes!.length > 100 * 1024 * 1024) throw const AppException('errors.file_too_large');
    final poster = await posterFuture;
    return PreparedUpload(bytes: file.bytes!, extension: extension, contentType: extension == 'mov' ? 'video/quicktime' : 'video/mp4', width: poster?.width, height: poster?.height, durationMs: poster?.durationMs, poster: poster);
  }

  Future<List<PreparedUpload>> pickForumAttachments({required int remaining}) async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov', 'pdf'], allowMultiple: true, withData: true);
    if (result == null) return const [];
    if (result.files.length > remaining) throw const AppException('forum_advanced.errors.attachments_too_many');
    final uploads = <PreparedUpload>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) throw const AppException('errors.file_unreadable');
      final extension = (file.extension ?? '').toLowerCase();
      if (const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        if (bytes.length > 8 * 1024 * 1024) throw const AppException('forum_advanced.errors.attachments_too_large');
        final image = img.decodeImage(bytes);
        if (image == null) throw const AppException('forum_advanced.errors.attachments_invalid');
        final mime = extension == 'png' ? 'image/png' : extension == 'webp' ? 'image/webp' : 'image/jpeg';
        uploads.add(PreparedUpload(bytes: bytes, extension: extension == 'jpeg' ? 'jpg' : extension, contentType: mime, width: image.width, height: image.height, fileName: file.name, mediaKind: 'image'));
      } else if (extension == 'pdf') {
        if (bytes.length > 10 * 1024 * 1024) throw const AppException('forum_advanced.errors.attachments_too_large');
        uploads.add(PreparedUpload(bytes: bytes, extension: extension, contentType: 'application/pdf', fileName: file.name, mediaKind: 'document'));
      } else if (const {'mp4', 'mov'}.contains(extension)) {
        if (bytes.length > 50 * 1024 * 1024) throw const AppException('forum_advanced.errors.attachments_too_large');
        final poster = await const VideoPosterService().extract(file);
        uploads.add(PreparedUpload(bytes: bytes, extension: extension, contentType: extension == 'mov' ? 'video/quicktime' : 'video/mp4', width: poster?.width, height: poster?.height, durationMs: poster?.durationMs, poster: poster, fileName: file.name, mediaKind: 'video'));
      } else {
        throw const AppException('forum_advanced.errors.attachments_invalid');
      }
    }
    return uploads;
  }

  /// Selects album images and videos and applies the shared 2048px envelope.
  Future<({List<PreparedUpload> uploads, int tooLarge})> pickAlbumMedia({int limit = 30}) async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov'], allowMultiple: true, withData: true);
    if (result == null) return (uploads: const <PreparedUpload>[], tooLarge: 0);
    if (result.files.length > limit) throw const AppException('albums.errors.max_per_upload');
    return _prepareAlbumFiles(result.files);
  }

  Future<({List<PreparedUpload> uploads, int tooLarge})> _prepareAlbumFiles(List<PlatformFile> files) async {
    final uploads = <PreparedUpload>[];
    var tooLarge = 0;
    for (final file in files) {
      final bytes = file.bytes;
      if (bytes == null) throw const AppException('errors.file_unreadable');
      if (bytes.length > 50 * 1024 * 1024) { tooLarge++; continue; }
      final extension = (file.extension ?? file.name.split('.').last).toLowerCase();
      if (const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        final decoded = img.decodeImage(bytes);
        if (decoded == null) throw const AppException('errors.image_processing_failed');
        final longest = max(decoded.width, decoded.height);
        final resized = longest <= 2048 ? decoded : img.copyResize(decoded, width: decoded.width >= decoded.height ? 2048 : null, height: decoded.height > decoded.width ? 2048 : null, interpolation: img.Interpolation.average);
        final keepOriginal = bytes.length <= 2 * 1024 * 1024 && const {'png', 'webp'}.contains(extension) && longest <= 2048;
        uploads.add(PreparedUpload(bytes: keepOriginal ? bytes : Uint8List.fromList(img.encodeJpg(resized, quality: 85)), extension: keepOriginal ? extension : 'jpg', contentType: keepOriginal ? (extension == 'png' ? 'image/png' : 'image/webp') : 'image/jpeg', width: resized.width, height: resized.height, fileName: file.name, mediaKind: 'image'));
      } else if (const {'mp4', 'mov'}.contains(extension)) {
        final poster = await const VideoPosterService().extract(file);
        uploads.add(PreparedUpload(bytes: bytes, extension: extension, contentType: extension == 'mov' ? 'video/quicktime' : 'video/mp4', width: poster?.width, height: poster?.height, durationMs: poster?.durationMs, poster: poster, fileName: file.name, mediaKind: 'video'));
      } else {
        throw const AppException('errors.file_type_not_allowed');
      }
    }
    return (uploads: uploads, tooLarge: tooLarge);
  }

  /// Resizes story images to the upload envelope and encodes them as JPEG 85.
  PreparedUpload prepareStoryImage(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const AppException('errors.image_processing_failed');
    final scale = min(1.0, min(1080 / decoded.width, 1920 / decoded.height));
    final prepared = scale == 1 ? decoded : img.copyResize(decoded, width: (decoded.width * scale).round(), height: (decoded.height * scale).round(), interpolation: img.Interpolation.average);
    return PreparedUpload(bytes: Uint8List.fromList(img.encodeJpg(prepared, quality: 85)), extension: 'jpg', contentType: 'image/jpeg', width: prepared.width, height: prepared.height);
  }

  Future<PreparedUpload?> pickDocument() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'], allowMultiple: false, withData: true);
    if (result == null) return null;
    final file = result.files.single;
    if (file.bytes == null) throw const AppException('profile.badge.document_error');
    final extension = (file.extension ?? '').toLowerCase();
    if (file.bytes!.length > 10 * 1024 * 1024) throw const AppException('errors.file_too_large');
    if (extension == 'pdf') return PreparedUpload(bytes: file.bytes!, extension: 'pdf', contentType: 'application/pdf', fileName: file.name, mediaKind: 'document');
    if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) throw const AppException('profile.badge.document_error');
    final decoded = img.decodeImage(file.bytes!);
    if (decoded == null) throw const AppException('profile.badge.document_error');
    final longest = max(decoded.width, decoded.height);
    final resized = longest <= 1600 ? decoded : img.copyResize(decoded, width: decoded.width >= decoded.height ? 1600 : null, height: decoded.height > decoded.width ? 1600 : null, interpolation: img.Interpolation.average);
    final bytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    if (bytes.length > 10 * 1024 * 1024) throw const AppException('errors.file_too_large');
    return PreparedUpload(bytes: bytes, extension: 'jpg', contentType: 'image/jpeg', width: resized.width, height: resized.height, fileName: file.name, mediaKind: 'image');
  }

  Future<UploadedMedia> uploadToBucket({required String bucket, required String userId, required PreparedUpload upload, required bool isPublic, UploadProgress? progress}) async {
    final session = _client.auth.currentSession;
    if (session == null) throw const AppException('errors.login_required');
    final path = '$userId/${_uuid()}.${upload.extension}';
    try {
      progress?.add(0);
      await _dio.post<void>(
        '${SupabaseConfig.url}/storage/v1/object/$bucket/$path',
        data: upload.bytes,
        options: Options(headers: {'Authorization': 'Bearer ${session.accessToken}', 'apikey': SupabaseConfig.anonKey, 'Content-Type': upload.contentType, 'x-upsert': 'false', 'Content-Length': upload.bytes.length}, responseType: ResponseType.json),
        onSendProgress: (sent, total) => progress?.add(total > 0 ? sent / total : 0),
      );
      progress?.add(1);
      final encodedPath = path.split('/').map(Uri.encodeComponent).join('/');
      final publicUrl = isPublic ? '${SupabaseConfig.url}/storage/v1/object/public/${Uri.encodeComponent(bucket)}/$encodedPath?v=${DateTime.now().millisecondsSinceEpoch}' : null;
      return UploadedMedia(path: path, publicUrl: publicUrl);
    } on DioException catch (error) {
      throw _uploadException(error.response?.statusCode);
    } catch (error) {
      if (error is AppException) rethrow;
      throw const AppException('errors.upload_failed');
    }
  }

  Future<UploadedMedia> uploadBytes({required String bucket, required String path, required Uint8List bytes, required String contentType, required ValueChanged<double> onProgress, bool isPublic = true, bool upsert = false}) async {
    final session = _client.auth.currentSession;
    if (session == null) throw const AppException('errors.login_required');
    try {
      onProgress(0);
      await _dio.post<void>(
        '${SupabaseConfig.url}/storage/v1/object/$bucket/$path',
        data: bytes,
        options: Options(headers: {'Authorization': 'Bearer ${session.accessToken}', 'apikey': SupabaseConfig.anonKey, 'Content-Type': contentType, 'x-upsert': '$upsert', 'Content-Length': bytes.length}, responseType: ResponseType.json),
        onSendProgress: (sent, total) => onProgress(total > 0 ? sent / total : 0),
      );
      onProgress(1);
      final encodedPath = path.split('/').map(Uri.encodeComponent).join('/');
      return UploadedMedia(path: path, publicUrl: isPublic ? '${SupabaseConfig.url}/storage/v1/object/public/${Uri.encodeComponent(bucket)}/$encodedPath?v=${DateTime.now().millisecondsSinceEpoch}' : null);
    } on DioException catch (error) {
      throw _uploadException(error.response?.statusCode);
    } catch (error) {
      if (error is AppException) rethrow;
      throw const AppException('errors.upload_failed');
    }
  }

  Future<UploadedMedia> uploadPoster({required String bucket, required Uint8List bytes, UploadProgress? progress}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AppException('errors.login_required');
    final path = '$userId/${_uuid()}_poster.jpg';
    return uploadBytes(bucket: bucket, path: path, bytes: bytes, contentType: 'image/jpeg', onProgress: (value) => progress?.add(value));
  }

  AppException _uploadException(int? statusCode) => switch (statusCode) {
    413 => const AppException('errors.file_too_large'),
    415 => const AppException('errors.file_type_not_allowed'),
    401 || 403 => const AppException('errors.login_required'),
    _ => const AppException('errors.upload_failed'),
  };

  Future<void> delete(String bucket, String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }

  String? pathFromPublicUrl(String bucket, String? url) {
    if (url == null) return null;
    final marker = '/storage/v1/object/public/$bucket/';
    final index = url.indexOf(marker);
    return index < 0 ? null : Uri.decodeComponent(url.substring(index + marker.length).split('?').first);
  }

  String _uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}