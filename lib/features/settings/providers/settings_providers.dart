import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/settings/data/settings_repository.dart';
import 'package:hb_social/features/admin/domain/admin_p41_models.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => SettingsRepository(ref.watch(supabaseClientProvider)));
final userSettingsRepositoryProvider = Provider<UserSettingsRepository>((ref) => UserSettingsRepository(ref.watch(supabaseClientProvider)));
final privateUserSettingsProvider = FutureProvider<UserSettingsRecord?>((ref) async {
  await ref.watch(authSessionProvider.future);
  return ref.watch(userSettingsRepositoryProvider).getMine();
});
final settingsSaveProvider = AsyncNotifierProvider<SettingsSaveNotifier, void>(SettingsSaveNotifier.new);
final myDataExportsProvider = FutureProvider.autoDispose<List<DataExportRecord>>((ref) => ref.watch(userSettingsRepositoryProvider).myDataExports());
final myAccountDeletionProvider = FutureProvider<AccountDeletionStatus>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) return const AccountDeletionStatus(pending: false);
  return ref.watch(userSettingsRepositoryProvider).accountDeletionStatus();
});

class SettingsSaveNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save(Map<String, dynamic> values) async {
    final session = await ref.read(authSessionProvider.future);
    if (session == null) throw const AppException('errors.not_authorized');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(settingsRepositoryProvider).updateProfile(session.user.id, values));
    if (state.hasError) throw state.error!;
    ref.invalidate(currentProfileProvider);
  }
}