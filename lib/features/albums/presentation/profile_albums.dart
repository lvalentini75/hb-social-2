import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/features/albums/presentation/album_widgets.dart';
import 'package:hb_social/features/albums/providers/album_providers.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';

class ProfileAlbums extends ConsumerWidget {
  final UserProfile owner;
  final bool isOwn;
  const ProfileAlbums({super.key, required this.owner, required this.isOwn});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(albumsByOwnerProvider(owner.id)).when(
    loading: () => LayoutBuilder(builder: (_, constraints) => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: constraints.maxWidth >= 720 ? 3 : 2, mainAxisSpacing: AppSpacing.md, crossAxisSpacing: AppSpacing.md, childAspectRatio: .78), itemCount: 4, itemBuilder: (_, __) => const HBCard(child: SizedBox.expand()))),
    error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'albums.error_title'.tr(), message: 'albums.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(albumsByOwnerProvider(owner.id))))),
    data: (albums) {
      if (albums.isEmpty && !isOwn) return HBCard(child: HBEmptyState(icon: Icons.photo_library_outlined, title: 'albums.empty_title'.tr(), message: 'albums.empty_other'.tr(namedArgs: {'name': owner.displayName})));
      if (albums.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.photo_library_outlined, title: 'albums.empty_title'.tr(), message: 'albums.empty_own'.tr(), action: HBButton.primary(label: 'albums.create_first'.tr(), onPressed: () => context.push(AppRoutes.albumCreate))));
      final paths = albums.map((album) => album.coverPath ?? album.cover?.thumbnailPath ?? album.cover?.path).whereType<String>().toList();
      return FutureBuilder<Map<String, String>>(
        future: ref.read(albumMediaUrlServiceProvider).signedUrls(paths),
        builder: (context, snapshot) => LayoutBuilder(builder: (_, constraints) {
          final count = constraints.maxWidth >= 720 ? 3 : 2;
          return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, mainAxisSpacing: AppSpacing.md, crossAxisSpacing: AppSpacing.md, childAspectRatio: .78), itemCount: albums.length + (isOwn ? 1 : 0), itemBuilder: (_, index) {
            if (isOwn && index == 0) return const NewAlbumCard();
            final album = albums[index - (isOwn ? 1 : 0)];
            final path = album.coverPath ?? album.cover?.thumbnailPath ?? album.cover?.path;
            return AlbumProfileCard(album: album, coverUrl: path == null ? null : snapshot.data?[path], showPrivacy: isOwn);
          });
        }),
      );
    },
  );
}