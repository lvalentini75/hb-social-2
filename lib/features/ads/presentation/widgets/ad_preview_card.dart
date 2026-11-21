import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/features/ads/data/ads_repository.dart';
import 'package:hb_social/features/ads/domain/ad_models.dart';
import 'package:hb_social/features/feed/presentation/widgets/post_video.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AdPreviewVariant { feed, rightRail, tile, story, search }

/// Shared representation used by Ads Manager, moderation and live delivery.
class AdPreviewCard extends StatelessWidget {
  final SupabaseClient client;
  final String advertiserName;
  final String? advertiserAvatar;
  final String headline;
  final String body;
  final String cta;
  final String? ctaLabel;
  final List<AdCreativeMedia> media;
  final Map<String, dynamic>? destination;
  final AdPreviewVariant variant;
  final Widget? trailing;
  final bool verified;
  final VoidCallback? onTap;
  final VoidCallback? onCta;
  final VoidCallback? onAdvertiserTap;

  const AdPreviewCard({super.key, required this.client, required this.advertiserName, this.advertiserAvatar, required this.headline, required this.body, required this.cta, this.ctaLabel, this.media = const [], this.destination, this.variant = AdPreviewVariant.feed, this.trailing, this.verified = false, this.onTap, this.onCta, this.onAdvertiserTap});

  @override
  Widget build(BuildContext context) {
    if (variant == AdPreviewVariant.search) return _SearchAdPreview(card: this);
    if (variant == AdPreviewVariant.story) return _StoryAdPreview(card: this);
    final compact = variant == AdPreviewVariant.rightRail;
    final tile = variant == AdPreviewVariant.tile;
    const story = false;
    return ConstrainedBox(constraints: BoxConstraints(maxWidth: compact ? 340 : tile ? 420 : 620), child: HBCard.media(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 2, child: ColoredBox(color: LightModeColors.lightAccentBrass)),
      if (!tile) Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [GestureDetector(onTap: onAdvertiserTap, child: HBAvatar(size: compact ? 32 : 40, name: advertiserName, imageUrl: advertiserAvatar)), const SizedBox(width: AppSpacing.sm), Expanded(child: GestureDetector(onTap: onAdvertiserTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Flexible(child: Text(advertiserName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodyMedium?.bold)), if (verified) const Padding(padding: EdgeInsets.only(left: 4), child: HBBadge(kind: HBBadgeKind.verified))]), Text('ads.delivery.sponsored'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]))), if (trailing != null) trailing!])),
      if (!tile && !story && body.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md), child: Text(body, maxLines: compact ? 2 : 5, overflow: TextOverflow.ellipsis)),
      AdPreviewMedia(client: client, media: media, destination: destination, aspectRatio: story ? 9 / 16 : tile ? 1 : compact ? 1.6 : 1.91),
      Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (tile) Text('ads.delivery.sponsored'.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant)), Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (headline.isNotEmpty) Text(headline, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall?.bold), if (!tile && destination?['subtitle'] != null) Text(destination!['subtitle'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])), const SizedBox(width: AppSpacing.sm), HBButton.soft(label: ctaLabel ?? 'ads.cta.$cta'.tr(), onPressed: onCta, size: HBButtonSize.sm)])])),
    ])));
  }
}

class AdPreviewMedia extends StatelessWidget {
  final SupabaseClient client;
  final List<AdCreativeMedia> media;
  final Map<String, dynamic>? destination;
  final double aspectRatio;
  const AdPreviewMedia({super.key, required this.client, required this.media, this.destination, required this.aspectRatio});
  @override Widget build(BuildContext context) {
    final values = media.isEmpty ? [AdCreativeMedia(path: destination?['image_path']?.toString() ?? '', kind: 'image')] : media;
    if (values.length > 1) return AspectRatio(aspectRatio: aspectRatio, child: PageView(children: [for (final item in values) _AdMediaItem(client: client, media: item, destination: destination)]));
    return AspectRatio(aspectRatio: aspectRatio, child: _AdMediaItem(client: client, media: values.first, destination: destination));
  }
}

class _AdMediaItem extends StatelessWidget {
  final SupabaseClient client;
  final AdCreativeMedia media;
  final Map<String, dynamic>? destination;
  const _AdMediaItem({required this.client, required this.media, this.destination});
  @override Widget build(BuildContext context) {
    final bucket = media.path.isEmpty ? _bucket(destination?['type']?.toString()) : AdsRepository.creativeBucket;
    final url = storagePublicUrl(client, bucket, media.path);
    final poster = storagePublicUrl(client, AdsRepository.creativeBucket, media.posterPath);
    if (media.kind == 'video' && url.isNotEmpty) return PostVideo(showControls: false, media: PostMedia(id: 'ad-${media.path}', url: url, kind: 'video', sortOrder: media.sortOrder, width: media.width, height: media.height, thumbnailUrl: poster));
    return url.isEmpty ? const ColoredBox(color: LightModeColors.lightBackgroundSoft) : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft));
  }
}

class _SearchAdPreview extends StatelessWidget {
  final AdPreviewCard card;
  const _SearchAdPreview({required this.card});
  @override Widget build(BuildContext context) => HBCard(padding: const EdgeInsets.all(AppSpacing.sm), child: InkWell(onTap: card.onTap, child: Row(children: [SizedBox(width: 72, height: 72, child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: AdPreviewMedia(client: card.client, media: card.media, destination: card.destination, aspectRatio: 1))), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ads.delivery.sponsored'.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightPrimary)), Text(card.headline, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodyMedium?.bold), Text(card.advertiserName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall)])), if (card.trailing != null) card.trailing!])));
}

class _StoryAdPreview extends StatelessWidget {
  final AdPreviewCard card;
  const _StoryAdPreview({required this.card});
  @override Widget build(BuildContext context) => SizedBox(width: 100, child: InkWell(onTap: card.onTap, borderRadius: BorderRadius.circular(AppRadius.md), child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: Stack(fit: StackFit.expand, children: [AdPreviewMedia(client: card.client, media: card.media, destination: card.destination, aspectRatio: 9 / 16), const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black26, Colors.transparent, Colors.black54]))), Positioned(top: AppSpacing.xs, left: AppSpacing.xs, child: HBAvatar(name: card.advertiserName, imageUrl: card.advertiserAvatar, size: 34)), Positioned(top: 0, right: 0, child: card.trailing ?? const SizedBox.shrink()), Positioned(left: AppSpacing.xs, right: AppSpacing.xs, bottom: AppSpacing.xs, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ads.delivery.sponsored'.tr(), style: context.textStyles.labelSmall?.copyWith(color: Colors.white)), Text(card.headline, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700))]))]))));
}

String _bucket(String? type) => switch (type) { 'post' => 'post-media', 'listing' => 'listing-media', 'event' => 'event-media', 'page' => 'page-media', _ => AdsRepository.creativeBucket };