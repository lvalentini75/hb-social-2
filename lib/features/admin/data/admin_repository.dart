import 'package:hb_social/core/services/error_mapper.dart';
import 'package:hb_social/features/admin/domain/admin_access.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRepository {
  final SupabaseClient _client;

  const AdminRepository(this._client);

  Future<AdminAccess?> getMyAccess() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final accessJson = await _client
          .from('admin_users')
          .select('user_id, mfa_enabled, role:admin_roles(id, name, description)')
          .eq('user_id', userId)
          .maybeSingle();
      if (accessJson == null) return null;
      final role = accessJson['role'] as Map<String, dynamic>?;
      final roleId = role?['id'] as String?;
      if (roleId == null) return null;
      final rows = await _client.from('admin_role_permissions').select('module, access').eq('role_id', roleId);
      final permissions = <String, String>{for (final row in rows as List) row['module'] as String: row['access'] as String};
      return AdminAccess.fromJson(accessJson, permissions);
    } catch (error) {
      throw ErrorMapper.fromSupabase(error);
    }
  }
}