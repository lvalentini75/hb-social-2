import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/profile/data/profile_repository.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/media_upload_service.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository(ref.watch(supabaseClientProvider)));

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  final userId = session?.user.id;
  if (userId == null) return null;
  try {
    return await ref.watch(profileRepositoryProvider).getMyProfile(userId);
  } on AppException {
    rethrow;
  }
});

final profileSaveProvider = AsyncNotifierProvider.autoDispose<ProfileSaveNotifier, void>(ProfileSaveNotifier.new);

class ProfileSaveNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save({required UserProfile current, required String username, required String displayName, required String bio, required String? regionId, String? municipalityId, String? huntingUnitId, PreparedUpload? avatar, PreparedUpload? cover, UploadProgress? avatarProgress, UploadProgress? coverProgress, void Function(int index)? onUploadIndex, VoidCallback? onPublishing}) async {
    final normalizedUsername = username.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(normalizedUsername)) throw const AppException('profile.edit.username_invalid');
    final repository = ref.read(profileRepositoryProvider);
    if (normalizedUsername != current.username && !await repository.isUsernameAvailable(normalizedUsername, excludingUserId: current.id)) throw const AppException('auth.errors.username_in_use');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final media = ref.read(mediaUploadServiceProvider);
      UploadedMedia? newAvatar;
      UploadedMedia? newCover;
      var profileUpdated = false;
      try {
        var uploadIndex = 0;
        if (avatar != null) {
          onUploadIndex?.call(++uploadIndex);
          newAvatar = await media.uploadToBucket(bucket: 'avatars', userId: current.id, upload: avatar, isPublic: true, progress: avatarProgress);
        }
        if (cover != null) {
          onUploadIndex?.call(++uploadIndex);
          newCover = await media.uploadToBucket(bucket: 'covers', userId: current.id, upload: cover, isPublic: true, progress: coverProgress);
        }
        onPublishing?.call();
        await repository.updateMyProfile(current.id, {'username': normalizedUsername, 'display_name': displayName.trim(), 'bio': bio.trim().isEmpty ? null : bio.trim(), 'home_region_id': regionId, 'home_municipality_id': municipalityId, 'hunting_unit_id': huntingUnitId, if (newAvatar != null) 'avatar_url': newAvatar.publicUrl, if (newCover != null) 'cover_url': newCover.publicUrl});
        profileUpdated = true;
        try {
          if (newAvatar != null) await media.delete('avatars', media.pathFromPublicUrl('avatars', current.avatarUrl));
          if (newCover != null) await media.delete('covers', media.pathFromPublicUrl('covers', current.coverUrl));
        } catch (_) {
          // A stale previous image must not roll back a successfully saved profile.
        }
        ref.invalidate(currentProfileProvider);
      } catch (_) {
        if (!profileUpdated) {
          if (newAvatar != null) await media.delete('avatars', newAvatar.path);
          if (newCover != null) await media.delete('covers', newCover.path);
        }
        rethrow;
      }
    });
    if (state.hasError) throw state.error!;
  }
}