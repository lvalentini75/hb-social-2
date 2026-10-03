import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/features/auth/data/user_repository.dart';
import 'package:hb_social/features/auth/domain/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main() once SharedPreferences has finished initializing.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden before use');
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(sharedPreferencesProvider));
});

final currentUserProvider = NotifierProvider<CurrentUserNotifier, AppUser?>(CurrentUserNotifier.new);

/// Holds the signed-in user for the lifetime of the app. There is no real
/// backend yet, so "sign up" and "log in" only manage locally stored state.
class CurrentUserNotifier extends Notifier<AppUser?> {
  UserRepository get _repository => ref.read(userRepositoryProvider);

  @override
  AppUser? build() => _repository.loadCurrentUser();

  String _usernameFromEmail(String email) {
    final prefix = email.split('@').first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(9);
    return '${prefix.isEmpty ? 'hunter' : prefix}$suffix';
  }

  Future<AppUser> signUp({required String name, required String email, required String password}) async {
    final now = DateTime.now();
    final user = AppUser(
      id: now.microsecondsSinceEpoch.toString(),
      name: name,
      username: _usernameFromEmail(email),
      email: email,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveCurrentUser(user);
    state = user;
    return user;
  }

  /// Returns true if a locally created account matches the given email.
  /// This is a placeholder until real authentication is wired up.
  bool logIn({required String email, required String password}) {
    final stored = _repository.loadCurrentUser();
    if (stored != null && stored.email.toLowerCase() == email.toLowerCase()) {
      state = stored;
      return true;
    }
    return false;
  }

  Future<void> completeOnboarding({
    required String countryCode,
    String? regionCode,
    required List<String> interestIds,
  }) async {
    final current = state;
    if (current == null) return;
    final updated = current.copyWith(
      countryCode: countryCode,
      regionCode: regionCode,
      interestIds: interestIds,
      onboardingCompleted: true,
    );
    await _repository.saveCurrentUser(updated);
    state = updated;
  }

  Future<void> logOut() async {
    await _repository.clearCurrentUser();
    state = null;
  }
}
