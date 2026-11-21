import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/features/albums/domain/album.dart';
import 'package:hb_social/features/albums/domain/album_media.dart';

class AlbumProfileCard extends StatelessWidget {
  final Album album;
  final String? coverUrl;
  final bool showPrivacy;
  const AlbumProfileCard({super.key, required this.album, this.coverUrl, required this.showPrivacy});

  @override
  Widget build(BuildContext context) => HBCard.media(
    child: InkWell(
      onTap: () => context.push(AppRoutes.albumDetailPath(album.id)), borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)), child: Stack(fit: StackFit.expand, children: [
          if (coverUrl == null) const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.photo_library_outlined, color: LightModeColors.lightTextTertiary)) else Image.network(coverUrl!, fit: BoxFit.cover, loadingBuilder: (_, child, progress) => progress == null ? child : const HBSkeleton(height: double.infinity, width: double.infinity, radius: 0), errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.broken_image_outlined))),
          if (album.coverPath == null && album.cover?.kind == AlbumMediaKind.video) const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 42)),
        ]))),
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(album.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall)), if (showPrivacy && album.visibility != AlbumVisibility.public) Icon(album.visibility == AlbumVisibility.private ? Icons.lock_outline_rounded : Icons.group_outlined, size: 17, color: LightModeColors.lightOnSurfaceVariant)]),
          const SizedBox(height: AppSpacing.xs),
          Text('albums.item_count'.plural(album.itemCount), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
        ])),
      ]),
    ),
  );
}

class NewAlbumCard extends StatelessWidget {
  const NewAlbumCard({super.key});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: AlbumDashedPainter(),
    child: Material(color: LightModeColors.lightPrimarySoft, borderRadius: BorderRadius.circular(AppRadius.lg), child: InkWell(onTap: () => context.push(AppRoutes.albumCreate), borderRadius: BorderRadius.circular(AppRadius.lg), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.add_rounded, color: LightModeColors.lightPrimary, size: 38), const SizedBox(height: AppSpacing.sm), Text('albums.new'.tr(), style: context.textStyles.titleSmall?.withColor(LightModeColors.lightForest))])))),
  );
}

class AlbumDashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = LightModeColors.lightPrimaryOutline..style = PaintingStyle.stroke..strokeWidth = 2;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadius.lg)));
    for (final metric in path.computeMetrics()) { var distance = 0.0; while (distance < metric.length) { canvas.drawPath(metric.extractPath(distance, (distance + 8).clamp(0, metric.length)), paint); distance += 14; } }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AlbumMediaTile extends StatelessWidget {
  final AlbumMedia media;
  final String? url;
  final bool isCover;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback? onSetCover;
  final VoidCallback? onEdit;
  const AlbumMediaTile({super.key, required this.media, this.url, required this.isCover, this.selected = false, this.selectionMode = false, required this.onTap, this.onSetCover, this.onEdit});

  String get duration { final seconds = (media.durationMs ?? 0) ~/ 1000; return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'; }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap, onLongPress: onSetCover,
    child: Stack(fit: StackFit.expand, children: [
      if (url == null) const HBSkeleton(height: double.infinity, width: double.infinity, radius: 0) else Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.broken_image_outlined))),
      if (media.kind == AlbumMediaKind.video) ...[const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40)), Positioned(right: 5, bottom: 5, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(AppRadius.xs)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), child: Text(duration, style: context.textStyles.labelSmall?.copyWith(color: Colors.white)))))],
      if (isCover) Positioned(left: 5, top: 5, child: HBChip(label: 'albums.cover'.tr(), selected: true)),
      if (selectionMode) Positioned(right: 6, top: 6, child: CircleAvatar(radius: 13, backgroundColor: selected ? LightModeColors.lightPrimary : LightModeColors.lightSurface, child: Icon(selected ? Icons.check_rounded : Icons.circle_outlined, size: 18, color: selected ? Colors.white : LightModeColors.lightOnSurfaceVariant))),
      if (onSetCover != null || onEdit != null) Positioned(right: 0, top: 0, child: PopupMenuButton<String>(icon: const Icon(Icons.more_horiz_rounded, color: Colors.white), onSelected: (value) => value == 'cover' ? onSetCover?.call() : onEdit?.call(), itemBuilder: (_) => [if (onSetCover != null) PopupMenuItem(value: 'cover', child: Text('albums.set_cover'.tr())), if (onEdit != null) PopupMenuItem(value: 'edit', child: Text('albums_p23b.media_edit_title'.tr()))])),
    ]),
  );
}