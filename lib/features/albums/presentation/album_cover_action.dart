import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/widgets/hb_image_cropper.dart';
import 'package:hb_social/features/albums/domain/album.dart';
import 'package:hb_social/features/albums/domain/album_media.dart';
import 'package:hb_social/features/albums/providers/album_providers.dart';
import 'package:uuid/uuid.dart';

/// Coordinates the private cropped thumbnail used as an album cover.
class AlbumCoverAction {
  const AlbumCoverAction._();

  static Future<void> run(BuildContext context, WidgetRef ref, Album album, AlbumMedia media) async {
    if (media.kind != AlbumMediaKind.image) { await ref.read(albumsRepositoryProvider).setCover(album.id, media.id); _refresh(ref, album); return; }
    final source = await ref.read(albumMediaUrlServiceProvider).download(media.path);
    if (!context.mounted) return;
    final cropped = await HBImageCropper.show(context, bytes: source, aspectRatio: 1, outputWidth: 800, outputHeight: 800, jpegQuality: 85);
    String? uploadedPath;
    try {
      if (cropped != null) {
        final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
        if (userId == null) throw const AppException('errors.login_required');
        uploadedPath = '$userId/${album.id}/cover_${const Uuid().v4()}.jpg';
        await ref.read(mediaUploadServiceProvider).uploadBytes(bucket: 'album-media', path: uploadedPath, bytes: cropped, contentType: 'image/jpeg', isPublic: false, onProgress: (_) {});
      }
      await ref.read(albumsRepositoryProvider).setCover(album.id, media.id, coverPath: uploadedPath);
      ref.read(albumMediaUrlServiceProvider).evict([if (album.coverPath != null) album.coverPath!]);
      _refresh(ref, album);
    } catch (_) {
      if (uploadedPath != null) { try { await ref.read(supabaseClientProvider).storage.from('album-media').remove([uploadedPath]); } catch (_) {} }
      rethrow;
    }
  }

  static void _refresh(WidgetRef ref, Album album) { ref.invalidate(albumProvider(album.id)); ref.invalidate(albumsByOwnerProvider(album.ownerId)); }
}