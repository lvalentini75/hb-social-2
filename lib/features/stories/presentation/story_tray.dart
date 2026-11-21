import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/features/ads/domain/ad_delivery.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/stories/domain/story.dart';
import 'package:hb_social/features/stories/presentation/story_composer.dart';
import 'package:hb_social/features/stories/providers/story_providers.dart';
import 'package:hb_social/features/safety/providers/safety_providers.dart';
import 'package:hb_social/features/feed/presentation/widgets/post_video.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/presentation/widgets/ad_preview_card.dart';
import 'package:hb_social/features/ads/presentation/widgets/sponsored_card.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';

/// Stories row. On web it is a 96×128 tile card; on mobile it is the
/// circular ring list of the PD4 mockup.
class StoryTray extends ConsumerWidget {
  const StoryTray({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;
    final profile = ref.watch(currentProfileProvider).value;
    final currentUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final tray = ref.watch(storyTrayProvider);
    final client = ref.watch(supabaseClientProvider);
    final blocked = ref.watch(locallyBlockedUserIdsProvider);

    final items = tray.value ?? const <StoryTrayItem>[];
    final mine = currentUserId == null ? null : items.where((item) => item.authorId == currentUserId).firstOrNull;
    final others = items.where((item) => item.authorId != currentUserId && !blocked.contains(item.authorId)).toList();
    final storyAds = others.length >= 3 ? ref.watch(deliveredAdsProvider(const AdPlacementRequest(AdPlacement.stories))).value ?? const [] : const [];

    if (!isWide) {
      return SizedBox(
        height: 104,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          MobileStoryCircle(
            label: 'story_tray.create'.tr(),
            name: profile?.displayName,
            avatarUrl: profile?.avatarUrl,
            isCreate: true,
            onTap: mine == null ? () => showStoryComposer(context) : () => context.push(AppRoutes.storyPath(mine.username)),
            onAdd: () => showStoryComposer(context),
          ),
          for (final item in others) ...[
            const SizedBox(width: AppSpacing.md),
            MobileStoryCircle(label: item.displayName, name: item.displayName, avatarUrl: item.avatarUrl, seen: item.unseenCount == 0, onTap: () => context.push(AppRoutes.storyPath(item.username))),
          ],
          if (tray.isLoading) ...[const SizedBox(width: AppSpacing.md), const HBSkeleton(width: 72, height: 72, radius: AppRadius.pill)],
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: LightModeColors.surface, borderRadius: BorderRadius.circular(AppRadius.cardWeb), boxShadow: AppShadows.card),
      child: SizedBox(
        height: 128,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          CreateStoryTile(
            coverUrl: mine == null ? null : _nonEmpty(storagePublicUrl(client, 'story-media', mine.latestThumbnailPath ?? mine.latestMediaPath)),
            onTap: () => showStoryComposer(context),
          ),
          for (var index = 0; index < others.length; index++) ...[
            const SizedBox(width: 12),
            StoryTrayTile(item: others[index], coverUrl: _nonEmpty(storagePublicUrl(client, 'story-media', others[index].latestThumbnailPath ?? others[index].latestMediaPath))),
            if (index == 2 && storyAds.isNotEmpty) ...[const SizedBox(width: 12), SponsoredCard(ad: storyAds.first, variant: AdPreviewVariant.story)],
          ],
          if (others.isNotEmpty) ...[const SizedBox(width: 12), SeeAllStoriesTile(onTap: () => context.go(AppRoutes.search))],
        ]),
      ),
    );
  }
}

String? _nonEmpty(String value) => value.isEmpty ? null : value;

/// Web "Crea storia" tile: the user's latest cover or a soft background.
class CreateStoryTile extends StatelessWidget {
  final String? coverUrl;
  final VoidCallback onTap;

  const CreateStoryTile({super.key, this.coverUrl, required this.onTap});

  @override
  Widget build(BuildContext context) => StoryTileShell(
    onTap: onTap,
    background: coverUrl == null ? null : Image.network(coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.surfaceSoft)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), shape: BoxShape.circle), child: const Icon(Icons.add_rounded, size: 24, color: LightModeColors.bosco)),
      const SizedBox(height: AppSpacing.sm),
      Text('story_tray.create'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: appFont(13, FontWeight.w600, color: coverUrl == null ? LightModeColors.text : Colors.white)),
    ]),
  );
}

/// Web story tile: cover, 56 px ringed avatar and the author name.
class StoryTrayTile extends StatelessWidget {
  final StoryTrayItem item;
  final String? coverUrl;

  const StoryTrayTile({super.key, required this.item, this.coverUrl});

  @override
  Widget build(BuildContext context) => StoryTileShell(
    onTap: () => context.push(AppRoutes.storyPath(item.username)),
    background: coverUrl == null ? null : Image.network(coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.bosco)),
    dim: true,
    child: Stack(children: [
      Positioned(top: 24, left: 0, right: 0, child: Center(child: HBAvatar(name: item.displayName, imageUrl: item.avatarUrl, size: 56, ringColor: item.unseenCount > 0 ? LightModeColors.bosco : LightModeColors.storyRingSeen, ringWidth: 3))),
      Positioned(left: 6, right: 6, bottom: 8, child: Text(item.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: appFont(13, FontWeight.w600, color: Colors.white))),
    ]),
  );
}

class SeeAllStoriesTile extends StatelessWidget {
  final VoidCallback onTap;

  const SeeAllStoriesTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => StoryTileShell(
    onTap: onTap,
    child: Center(child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.chevron_right_rounded, size: 22, color: LightModeColors.text))),
  );
}

/// 96×128 rounded shell shared by every web story tile.
class StoryTileShell extends StatelessWidget {
  final Widget child;
  final Widget? background;
  final bool dim;
  final VoidCallback onTap;

  const StoryTileShell({super.key, required this.child, required this.onTap, this.background, this.dim = false});

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(AppRadius.media),
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.media),
      child: SizedBox(
        width: 96, height: 128,
        child: Stack(fit: StackFit.expand, children: [
          background ?? const ColoredBox(color: LightModeColors.surfaceSoft),
          if (dim) const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.center, end: Alignment.bottomCenter, colors: [Colors.transparent, LightModeColors.overlayStrong]))),
          child,
        ]),
      ),
    ),
  );
}

/// Mobile story circle: 72 px with a 2.5 px ring and the label below.
class MobileStoryCircle extends StatelessWidget {
  final String label;
  final String? name;
  final String? avatarUrl;
  final bool seen;
  final bool isCreate;
  final VoidCallback onTap;
  final VoidCallback? onAdd;

  const MobileStoryCircle({super.key, required this.label, this.name, this.avatarUrl, this.seen = false, this.isCreate = false, required this.onTap, this.onAdd});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 80,
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.inner),
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 72, height: 72, child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(child: HBAvatar(name: name ?? '', imageUrl: avatarUrl, size: 72, isGuest: name == null, ringColor: seen ? LightModeColors.storyRingSeen : LightModeColors.bosco, ringWidth: 2.5)),
          if (isCreate && onAdd != null) Positioned(right: -2, bottom: -2, child: Semantics(button: true, label: 'story_tray.add'.tr(), child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onAdd,
            child: Container(width: 24, height: 24, decoration: BoxDecoration(color: LightModeColors.bosco, shape: BoxShape.circle, border: Border.all(color: LightModeColors.surface, width: 2)), child: const Icon(Icons.add_rounded, size: 14, color: Colors.white)),
          ))),
        ])),
        const SizedBox(height: AppSpacing.xs),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppText.caption.withColor(LightModeColors.text)),
      ]),
    ),
  );
}

class StoryTrayVideo extends StatelessWidget {
  final String mediaId;
  final String? mediaUrl;
  final String? thumbnailUrl;

  const StoryTrayVideo({super.key, required this.mediaId, this.mediaUrl, this.thumbnailUrl});

  @override
  Widget build(BuildContext context) => PostVideo(
    showControls: false,
    media: PostMedia(id: 'story-$mediaId', url: mediaUrl ?? '', kind: 'video', sortOrder: 0, thumbnailUrl: thumbnailUrl),
  );
}
