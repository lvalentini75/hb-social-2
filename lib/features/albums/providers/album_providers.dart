import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/albums/data/album_media_url_service.dart';
import 'package:hb_social/features/albums/data/albums_repository.dart';
import 'package:hb_social/features/albums/domain/album.dart';
import 'package:hb_social/features/albums/domain/album_media.dart';
import 'package:uuid/uuid.dart';

final albumsRepositoryProvider = Provider<AlbumsRepository>((ref) => AlbumsRepository(ref.watch(supabaseClientProvider)));
final albumMediaUrlServiceProvider = Provider<AlbumMediaUrlService>((ref) => AlbumMediaUrlService(ref.watch(supabaseClientProvider)));
final albumsByOwnerProvider = FutureProvider.autoDispose.family<List<Album>, String>((ref, ownerId) => ref.watch(albumsRepositoryProvider).fetchByOwner(ownerId));
final albumProvider = FutureProvider.autoDispose.family<Album?, String>((ref, id) => ref.watch(albumsRepositoryProvider).getById(id));
final albumMediaProvider = AsyncNotifierProvider.autoDispose.family<AlbumMediaNotifier, AlbumMediaState, String>((albumId) => AlbumMediaNotifier(albumId));
final albumUploadProvider = AsyncNotifierProvider.family<AlbumUploadNotifier, AlbumUploadState, String>((albumId) => AlbumUploadNotifier(albumId));

class AlbumMediaState {
  final List<AlbumMedia> items;
  final bool hasMore;
  final bool loadingMore;
  const AlbumMediaState({required this.items, required this.hasMore, this.loadingMore = false});
  AlbumMediaState copyWith({List<AlbumMedia>? items, bool? hasMore, bool? loadingMore}) => AlbumMediaState(items: items ?? this.items, hasMore: hasMore ?? this.hasMore, loadingMore: loadingMore ?? this.loadingMore);
}

class AlbumMediaNotifier extends AsyncNotifier<AlbumMediaState> {
  final String albumId;
  AlbumMediaNotifier(this.albumId);

  @override
  Future<AlbumMediaState> build() async {
    final items = await ref.watch(albumsRepositoryProvider).fetchMedia(albumId);
    return AlbumMediaState(items: items, hasMore: items.length == 60);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await ref.read(albumsRepositoryProvider).fetchMedia(albumId, offset: current.items.length);
      state = AsyncData(current.copyWith(items: [...current.items, ...next], hasMore: next.length == 60, loadingMore: false));
    } catch (error, stackTrace) { state = AsyncError(error, stackTrace); }
  }

  Future<void> loadAll() async {
    while (state.value?.hasMore == true) {
      await loadMore();
      if (state.hasError) return;
    }
  }

  void addLocal(List<AlbumMedia> media) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(items: [...current.items, ...media]));
  }

  void updateLocal(AlbumMedia media) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(items: current.items.map((item) => item.id == media.id ? media : item).toList()));
  }

  Future<void> remove(AlbumMedia media) async {
    await ref.read(albumsRepositoryProvider).removeMedia(media.id);
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(items: current.items.where((item) => item.id != media.id).toList()));
    ref.read(albumMediaUrlServiceProvider).evict([media.path, if (media.thumbnailPath != null) media.thumbnailPath!]);
    ref.invalidate(albumProvider(albumId));
  }

  Future<void> reorder(List<String> ids) async {
    await ref.read(albumsRepositoryProvider).reorder(albumId, ids);
    final current = state.value;
    if (current == null) return;
    final byId = {for (final item in current.items) item.id: item};
    state = AsyncData(current.copyWith(items: ids.map((id) => byId[id]).whereType<AlbumMedia>().toList()));
  }


  Future<void> updateMedia(AlbumMedia media, {String? caption, DateTime? takenAt}) async {
    await ref.read(albumsRepositoryProvider).updateMedia(media.id, caption: caption, takenAt: takenAt);
    updateLocal(media.copyWith(caption: caption, takenAt: takenAt, clearCaption: caption == null, clearTakenAt: takenAt == null));
  }
}

enum AlbumUploadStatus { waiting, uploading, complete, failed, cancelled }

class AlbumUploadItem {
  final String localId;
  final PreparedUpload upload;
  final AlbumUploadStatus status;
  final double progress;
  final String? errorKey;
  const AlbumUploadItem({required this.localId, required this.upload, this.status = AlbumUploadStatus.waiting, this.progress = 0, this.errorKey});
  AlbumUploadItem copyWith({AlbumUploadStatus? status, double? progress, String? errorKey}) => AlbumUploadItem(localId: localId, upload: upload, status: status ?? this.status, progress: progress ?? this.progress, errorKey: errorKey);
}

class AlbumUploadState {
  final List<AlbumUploadItem> items;
  final bool running;
  const AlbumUploadState({this.items = const [], this.running = false});
  int get done => items.where((item) => item.status == AlbumUploadStatus.complete).length;
  double get totalProgress => items.isEmpty ? 0 : items.fold<double>(0, (sum, item) => sum + item.progress) / items.length;
  bool get visible => items.any((item) => item.status != AlbumUploadStatus.complete && item.status != AlbumUploadStatus.cancelled);
  AlbumUploadState copyWith({List<AlbumUploadItem>? items, bool? running}) => AlbumUploadState(items: items ?? this.items, running: running ?? this.running);
}

class AlbumUploadNotifier extends AsyncNotifier<AlbumUploadState> {
  final String albumId;
  AlbumUploadNotifier(this.albumId);
  @override
  Future<AlbumUploadState> build() async => const AlbumUploadState();

  Future<void> enqueue(List<PreparedUpload> uploads) async {
    final current = state.value ?? const AlbumUploadState();
    final additions = uploads.map((upload) => AlbumUploadItem(localId: const Uuid().v4(), upload: upload)).toList();
    state = AsyncData(current.copyWith(items: [...current.items.where((item) => item.status == AlbumUploadStatus.failed), ...additions]));
    await _run();
  }

  void cancel(String localId) => _update(localId, (item) => item.status == AlbumUploadStatus.waiting ? item.copyWith(status: AlbumUploadStatus.cancelled) : item);

  Future<void> retryFailed() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(items: current.items.map((item) => item.status == AlbumUploadStatus.failed ? item.copyWith(status: AlbumUploadStatus.waiting, progress: 0, errorKey: null) : item).toList()));
    await _run();
  }

  Future<void> _run() async {
    var current = state.value;
    if (current == null || current.running) return;
    state = AsyncData(current.copyWith(running: true));
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) { state = AsyncError(const AppException('errors.login_required'), StackTrace.current); return; }
    final uploaded = <AlbumMedia>[];
    final uploadedPaths = <String>[];
    for (final initial in List<AlbumUploadItem>.from(state.value!.items)) {
      final live = state.value!.items.where((item) => item.localId == initial.localId).firstOrNull;
      if (live == null || live.status != AlbumUploadStatus.waiting) continue;
      _update(live.localId, (item) => item.copyWith(status: AlbumUploadStatus.uploading));
      try {
        final uuid = const Uuid().v4();
        String? thumbnailPath;
        if (live.upload.poster != null) {
          thumbnailPath = '$userId/$albumId/${uuid}_poster.jpg';
          await ref.read(mediaUploadServiceProvider).uploadBytes(bucket: 'album-media', path: thumbnailPath, bytes: live.upload.poster!.bytes, contentType: 'image/jpeg', isPublic: false, onProgress: (value) => _update(live.localId, (item) => item.copyWith(progress: value * .15)));
          uploadedPaths.add(thumbnailPath);
        }
        final path = '$userId/$albumId/$uuid.${live.upload.extension}';
        await ref.read(mediaUploadServiceProvider).uploadBytes(bucket: 'album-media', path: path, bytes: live.upload.bytes, contentType: live.upload.contentType, isPublic: false, onProgress: (value) => _update(live.localId, (item) => item.copyWith(progress: (live.upload.poster == null ? value : .15 + value * .85))));
        uploadedPaths.add(path);
        uploaded.add(AlbumMedia(id: '', albumId: albumId, ownerId: userId, path: path, kind: live.upload.mediaKind == 'video' ? AlbumMediaKind.video : AlbumMediaKind.image, width: live.upload.width, height: live.upload.height, durationMs: live.upload.durationMs, thumbnailPath: thumbnailPath, sizeBytes: live.upload.bytes.length, takenAt: live.upload.takenAt, sortOrder: 0, createdAt: DateTime.now().toUtc()));
        _update(live.localId, (item) => item.copyWith(status: AlbumUploadStatus.complete, progress: 1));
      } on AppException catch (error) { _update(live.localId, (item) => item.copyWith(status: AlbumUploadStatus.failed, errorKey: error.messageKey)); }
      catch (_) { _update(live.localId, (item) => item.copyWith(status: AlbumUploadStatus.failed, errorKey: 'errors.upload_failed')); }
    }
    try {
      if (uploaded.isNotEmpty) {
        final ids = await ref.read(albumsRepositoryProvider).addMedia(albumId, uploaded);
        final persisted = [for (var index = 0; index < uploaded.length; index++) AlbumMedia(id: index < ids.length ? ids[index] : '', albumId: albumId, ownerId: uploaded[index].ownerId, path: uploaded[index].path, kind: uploaded[index].kind, width: uploaded[index].width, height: uploaded[index].height, durationMs: uploaded[index].durationMs, thumbnailPath: uploaded[index].thumbnailPath, sizeBytes: uploaded[index].sizeBytes, takenAt: uploaded[index].takenAt, sortOrder: (ref.read(albumMediaProvider(albumId)).value?.items.length ?? 0) + index, createdAt: uploaded[index].createdAt)];
        ref.read(albumMediaProvider(albumId).notifier).addLocal(persisted);
        ref.invalidate(albumProvider(albumId));
        ref.invalidate(albumsByOwnerProvider(userId));
      }
    } on AppException catch (error) {
      try { await ref.read(supabaseClientProvider).storage.from('album-media').remove(uploadedPaths); } catch (_) {}
      final value = state.value!;
      state = AsyncData(value.copyWith(items: value.items.map((item) => item.status == AlbumUploadStatus.complete ? item.copyWith(status: AlbumUploadStatus.failed, errorKey: error.messageKey) : item).toList(), running: false));
      return;
    }
    final value = state.value!;
    state = AsyncData(value.copyWith(items: value.items.where((item) => item.status != AlbumUploadStatus.complete && item.status != AlbumUploadStatus.cancelled).toList(), running: false));
  }

  void _update(String id, AlbumUploadItem Function(AlbumUploadItem item) update) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(items: current.items.map((item) => item.localId == id ? update(item) : item).toList()));
  }
}