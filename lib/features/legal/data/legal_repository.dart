import 'package:hb_social/core/config/app_constants.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/core/services/platform_info.dart';
import 'package:hb_social/features/legal/domain/legal_document.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LegalRepository {
  final SupabaseClient client;
  const LegalRepository(this.client);

  Future<List<LegalDocument>> current(String locale) async => [for (final row in await _list('legal_documents_current', {'p_locale': locale})) LegalDocument.fromJson(row)];
  Future<LegalDocument> document(String kind, String locale, {int? version}) async => LegalDocument.fromJson(await _object('legal_document', {'p_kind': kind, 'p_locale': locale, 'p_version': version}));
  Future<PendingLegalConsents> pending(String locale) async => PendingLegalConsents.fromJson(await _object('my_pending_consents', {'p_locale': locale}));
  Future<List<LegalConsentRecord>> myConsents() async => [for (final row in await _list('my_consents', const {})) LegalConsentRecord.fromJson(row)];
  Future<void> accept(String kind, int version, String locale) async => _rpc('accept_legal', {'p_kind': kind, 'p_version': version, 'p_platform': currentPlatformName, 'p_app_version': AppConstants.appVersion, 'p_locale': locale});
  Future<void> acceptCurrent(String kind, String locale) async {
    Future<LegalDocument> publishedDocument() async {
      final documents = await current(locale);
      for (final document in documents) {
        if (document.kind == kind) return document;
      }
      throw const AppException('legal.errors.legal_version_not_found');
    }

    var document = await publishedDocument();
    try {
      await accept(kind, document.version, locale);
    } on AppException catch (error) {
      if (error.messageKey != 'legal.errors.legal_version_outdated') rethrow;
      document = await publishedDocument();
      await accept(kind, document.version, locale);
    }
  }

  Future<List<Map<String, dynamic>>> _list(String name, Map<String, dynamic> params) async { final raw = await _rpc(name, params); return [for (final row in raw as List? ?? const []) Map<String, dynamic>.from(row as Map)]; }
  Future<Map<String, dynamic>> _object(String name, Map<String, dynamic> params) async { final raw = await _rpc(name, params); final value = raw is List && raw.isNotEmpty ? raw.first : raw; return Map<String, dynamic>.from(value as Map? ?? const {}); }
  Future<Object?> _rpc(String name, Map<String, dynamic> params) async {
    try { return await client.rpc(name, params: params); }
    catch (error) { final message = error.toString().toLowerCase(); for (final key in legalErrorKeys) { if (message.contains(key)) throw AppException('legal.errors.$key'); } throw ErrorMapper.fromSupabase(error); }
  }
}

const legalErrorKeys = {'not_authenticated','legal_kind_invalid','legal_locale_invalid','legal_content_invalid','legal_version_published','legal_version_not_found','legal_locales_missing','legal_version_outdated','age_confirmation_required','admin_permission_denied','admin_superadmin_required','settings_value_invalid'};