import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/features/sightings/domain/sighting.dart';
import 'package:hb_social/features/sightings/providers/sightings_providers.dart';
import 'package:timeago/timeago.dart' as timeago;

class SightingCard extends ConsumerWidget {
  final Sighting sighting;
  final bool compact;
  const SightingCard({super.key, required this.sighting, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(sightingsRepositoryProvider);
    final image = repository.publicUrl(sighting.thumbnailPath ?? sighting.mediaPath);
    final place = [sighting.municipality?.name, sighting.unit?.name].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    final title = 'sightings.animals'.plural(sighting.animalsCount, namedArgs: {'count': '${sighting.animalsCount}', 'species': sighting.species.name});
    return HBCard(padding: EdgeInsets.zero, child: InkWell(borderRadius: BorderRadius.circular(AppRadius.md), onTap: () => context.push(AppRoutes.sightingDetailPath(sighting.id)), child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: SizedBox.square(dimension: compact ? 64 : 84, child: image == null ? ColoredBox(color: LightModeColors.lightPrimarySoft, child: Icon(sighting.kind.icon, color: LightModeColors.lightPrimary, size: 30)) : Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => ColoredBox(color: LightModeColors.lightPrimarySoft, child: Icon(sighting.kind.icon, color: LightModeColors.lightPrimary))))),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.xs), Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [HBChip(label: sighting.kind.labelKey.tr(), selected: false, icon: sighting.kind.icon), if (sighting.isMine) HBChip(label: sighting.visibility.labelKey.tr(), selected: false), if (sighting.logId != null) HBChip(label: 'sightings.outing_badge'.tr(), selected: false)]), const SizedBox(height: AppSpacing.xs), Text('${timeago.format(sighting.sightedAt.toLocal(), locale: context.locale.languageCode)} · ${DateFormat.Hm(context.locale.languageCode).format(sighting.sightedAt.toLocal())}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), if (place.isNotEmpty) Text(place, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])),
      const Icon(Icons.chevron_right_rounded, color: LightModeColors.lightTextTertiary),
    ]))));
  }
}

class SightingsList extends StatelessWidget {
  final List<Sighting> items;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onLoadMore;
  const SightingsList({super.key, required this.items, required this.hasMore, required this.loadingMore, required this.onLoadMore});
  @override
  Widget build(BuildContext context) => Column(children: [for (final item in items) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: SightingCard(sighting: item)), if (hasMore) HBButton.secondary(label: loadingMore ? 'common.loading'.tr() : 'feed.load_more'.tr(), onPressed: loadingMore ? null : onLoadMore)]);
}