import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/features/safety/providers/safety_providers.dart' as safety;
import 'package:hb_social/features/feed/presentation/widgets/post_video.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';

class PostMediaGrid extends StatelessWidget {
  final List<PostMedia> media;

  /// Overrides the default (mobile = square, desktop = AppRadius.sm) corner
  /// radius. Used by the post card to inset the media with a 16 px radius.
  final BorderRadius? radius;

  const PostMediaGrid({super.key, required this.media, this.radius});

  void _open(BuildContext context, int index) => context.push(AppRoutes.media, extra: MediaViewerArgs(media: media, initialIndex: index));

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();
    final isMobile = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;
    final resolvedRadius = radius ?? (isMobile ? BorderRadius.zero : BorderRadius.circular(AppRadius.sm));
    if (media.length == 1 && media.first.kind == 'video') return ClipRRect(borderRadius: resolvedRadius, child: PostVideo(media: media.first));
    return ClipRRect(
      borderRadius: resolvedRadius,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (media.length == 1) {
          final item = media.first;
          final raw = item.width != null && item.height != null && item.height! > 0 ? item.width! / item.height! : 16 / 9;
          final aspect = raw.clamp(4 / 5, 16 / 9).toDouble();
          return AspectRatio(aspectRatio: aspect, child: PostNetworkImage(media: item, onTap: () => _open(context, 0)));
        }
        final height = width * 0.72;
        if (media.length == 2) return SizedBox(height: height, child: Row(children: [_tile(context, 0), const SizedBox(width: 2), _tile(context, 1)]));
        if (media.length == 3) return SizedBox(height: height, child: Row(children: [_tile(context, 0, flex: 2), const SizedBox(width: 2), Expanded(child: Column(children: [_tile(context, 1), const SizedBox(height: 2), _tile(context, 2)]))]));
        return SizedBox(height: height, child: Column(children: [Expanded(child: Row(children: [_tile(context, 0), const SizedBox(width: 2), _tile(context, 1)])), const SizedBox(height: 2), Expanded(child: Row(children: [_tile(context, 2), const SizedBox(width: 2), _tile(context, 3, overlay: media.length > 4 ? media.length - 4 : null)]))]));
      }),
    );
  }

  Widget _tile(BuildContext context, int index, {int flex = 1, int? overlay}) => Expanded(
    flex: flex,
    child: Stack(fit: StackFit.expand, children: [
      media[index].kind == 'video' ? PostVideo(media: media[index]) : PostNetworkImage(media: media[index], onTap: () => _open(context, index)),
      if (overlay != null) InkWell(onTap: () => _open(context, index), child: ColoredBox(color: Colors.black54, child: Center(child: Text('+$overlay', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))))),
    ]),
  );
}

/// Applies the country policy and the user's session choice to post media.
class SensitivePostMedia extends ConsumerWidget {
  final FeedPost post;
  final BorderRadius? radius;

  const SensitivePostMedia({super.key, required this.post, this.radius});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (post.media.isEmpty) return const SizedBox.shrink();
    final policy = ref.watch(safety.countryPolicyProvider(post.countryCode)).value;
    final revealed = ref.watch(safety.revealedSensitivePostsProvider).contains(post.id);
    final showSensitive = ref.watch(userSettingsProvider.select((settings) => settings.showSensitive));
    final shouldBlur = post.isSensitive && (policy?.blurHarvestPhotos ?? true) && !showSensitive && !revealed;
    if (!shouldBlur) return PostMediaGrid(media: post.media, radius: radius);
    return ClipRRect(borderRadius: radius ?? BorderRadius.zero, child: Stack(alignment: Alignment.center, children: [
      IgnorePointer(child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: PostMediaGrid(media: post.media, radius: radius))),
      Positioned.fill(child: ColoredBox(color: Colors.black38)),
      Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.visibility_off_rounded, color: Colors.white, size: 32),
          const SizedBox(height: AppSpacing.xs),
          Text('sensitive.title'.tr(), textAlign: TextAlign.center, style: context.textStyles.titleMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: AppSpacing.xs),
          Text('sensitive.message'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodySmall?.copyWith(color: Colors.white)),
          const SizedBox(height: AppSpacing.sm),
          HBButton.soft(label: 'sensitive.show'.tr(), onPressed: () => ref.read(safety.revealedSensitivePostsProvider.notifier).state = {...ref.read(safety.revealedSensitivePostsProvider), post.id}, size: HBButtonSize.sm),
        ]),
      ),
    ]));
  }
}

class PostNetworkImage extends StatelessWidget {
  final PostMedia media;
  final VoidCallback onTap;

  const PostNetworkImage({super.key, required this.media, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Image.network(
      media.url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, synchronous) => AnimatedOpacity(opacity: frame == null && !synchronous ? 0 : 1, duration: AppMotion.of(context).base, child: child),
      loadingBuilder: (context, child, progress) => progress == null ? child : const HBSkeleton(width: double.infinity, height: double.infinity),
      errorBuilder: (context, error, stackTrace) => ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.broken_image_outlined), const SizedBox(height: AppSpacing.xs), Text('feed.media_unavailable'.tr())]))),
    ),
  );
}

class MediaViewerArgs {
  final List<PostMedia> media;
  final int initialIndex;

  const MediaViewerArgs({required this.media, required this.initialIndex});
}