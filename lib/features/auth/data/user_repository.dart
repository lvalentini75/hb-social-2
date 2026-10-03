import 'dart:convert';

import 'package:hb_social/features/auth/domain/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads and writes the current user to local storage. This is a stand-in
/// for a real backend and will be replaced by Supabase in the next step.
class UserRepository {
  static const _storageKey = 'hb_current_user';

  final SharedPreferences _prefs;

  UserRepository(this._prefs);

  AppUser? loadCurrentUser() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCurrentUser(AppUser user) async {
    await _prefs.setString(_storageKey, jsonEncode(user.toJson()));
  }

  Future<void> clearCurrentUser() async {
    await _prefs.remove(_storageKey);
  }
}
