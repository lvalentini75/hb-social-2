import 'package:dio/dio.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves a public Storage path while preserving already absolute URLs.
String storagePublicUrl(SupabaseClient client, String bucket, String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final encodedPath = path.split('/').map(Uri.encodeComponent).join('/');
  return '${SupabaseConfig.url}/storage/v1/object/public/${Uri.encodeComponent(bucket)}/$encodedPath';
}

/// Creates a short-lived URL for a private Storage object through the REST API.
Future<String> storageSignedUrl(SupabaseClient client, String bucket, String path, {int expiresIn = 600}) async {
  final session = client.auth.currentSession;
  if (session == null) throw const AppException('errors.login_required');
  final encodedPath = path.split('/').map(Uri.encodeComponent).join('/');
  try {
    final response = await Dio().post<Map<String, dynamic>>('${SupabaseConfig.url}/storage/v1/object/sign/${Uri.encodeComponent(bucket)}/$encodedPath', data: {'expiresIn': expiresIn}, options: Options(headers: {'Authorization': 'Bearer ${session.accessToken}', 'apikey': SupabaseConfig.anonKey, 'Content-Type': 'application/json'}));
    final signedPath = response.data?['signedURL'] as String?;
    if (signedPath == null || signedPath.isEmpty) throw const AppException('errors.not_authorized');
    return signedPath.startsWith('http') ? signedPath : '${SupabaseConfig.url}/storage/v1$signedPath';
  } on DioException catch (error) {
    if (error.response?.statusCode == 401 || error.response?.statusCode == 403) throw const AppException('errors.login_required');
    throw const AppException('errors.not_authorized');
  }
}