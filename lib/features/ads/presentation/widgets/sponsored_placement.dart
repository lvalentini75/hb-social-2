import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/features/ads/domain/ad_delivery.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/presentation/widgets/ad_preview_card.dart';
import 'package:hb_social/features/ads/presentation/widgets/sponsored_card.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';

class SponsoredPlacement extends ConsumerWidget {
  final AdPlacement placement;
  final AdPreviewVariant variant;
  final Map<String, dynamic> contextData;
  const SponsoredPlacement({super.key, required this.placement, this.variant = AdPreviewVariant.feed, this.contextData = const {}});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(deliveredAdsProvider(AdPlacementRequest(placement, context: contextData))).when(data: (items) => items.isEmpty ? const SizedBox.shrink() : SponsoredCard(ad: items.first, variant: variant), loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink());
}