import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/features/verification/domain/verification_request.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class VerificationRepository {
  final SupabaseClient _client;
  final MediaUploadService _media;

  const VerificationRepository(this._client, this._media);

  Future<VerificationStatus> myVerification() async {
    try {
      final result = await _client.rpc('my_verification');
      return VerificationStatus.fromJson(Map<String, dynamic>.from(result as Map));
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<String> submit({required BadgeType badgeType, required Map<String, dynamic> declaredData, required List<VerificationDocument> documents, String? pageId}) async {
    try {
      final result = await _client.rpc('submit_verification_request', params: {'p_badge_type': badgeType.code, 'p_declared_data': declaredData, 'p_documents': documents.map((item) => item.toJson()).toList(), 'p_page_id': pageId});
      return result.toString();
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> cancel(String id) async {
    try {
      final result = await _client.rpc('cancel_verification_request', params: {'p_id': id});
      final paths = (result as List? ?? const []).map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
      if (paths.isNotEmpty) { try { await _client.storage.from('verification-docs').remove(paths); } catch (_) {} }
    } catch (error) { throw ErrorMapper.fromSupabase(error); }
  }

  Future<VerificationDocument> uploadDocument(PreparedUpload file, DocumentKind kind, void Function(double) onProgress) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AppException('errors.login_required');
    if (file.bytes.length > 10 * 1024 * 1024) throw const AppException('verification.errors.file_too_large');
    try {
      final uploaded = await _media.uploadBytes(bucket: 'verification-docs', path: '$userId/${_uuid()}.${file.extension}', bytes: file.bytes, contentType: file.contentType, isPublic: false, onProgress: onProgress);
      return VerificationDocument(path: uploaded.path, kind: kind, name: file.fileName ?? 'verification.doc.${kind.code}', size: file.bytes.length);
    } catch (error) { if (error is AppException) rethrow; throw ErrorMapper.fromSupabase(error); }
  }

  Future<void> removeDocument(String path) async { try { await _media.delete('verification-docs', path); } catch (_) {} }
  Future<String> documentUrl(String path) => storageSignedUrl(_client, 'verification-docs', path, expiresIn: 600);

  String _uuid() => const Uuid().v4();
}