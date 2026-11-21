import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/core/widgets/composer_sheet.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/features/safety/presentation/report_sheet.dart';
import 'package:hb_social/features/sightings/data/sightings_repository.dart';
import 'package:hb_social/features/sightings/domain/sighting.dart';
import 'package:hb_social/features/sightings/providers/sightings_providers.dart';
import 'package:hb_social/features/sightings/domain/sighting_alert.dart';
import 'package:latlong2/latlong.dart';

class SightingDetailPage extends ConsumerWidget {
  final String sightingId;
  const SightingDetailPage({super.key, required this.sightingId});

  Future<void> _delete(BuildContext context, WidgetRef ref, SightingDetail detail) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text('sightings.delete.title'.tr()), content: Text('sightings.delete.message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop(false)), HBButton.secondary(label: 'sightings.actions.delete'.tr(), onPressed: () => dialog.pop(true))])) ?? false;
    if (!confirmed) return;
    try { await ref.read(sightingsRepositoryProvider).delete(detail.id); ref.invalidate(mySightingsProvider); ref.invalidate(sightingsOfProvider); if (context.mounted) context.go(AppRoutes.sightings); }
    on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  Future<void> _visibility(BuildContext context, WidgetRef ref, SightingDetail detail, SightingVisibility visibility) async {
    try {
      await ref.read(sightingsRepositoryProvider).upsert(SightingInput(id: detail.id, speciesId: detail.species.id, sightedAt: detail.sightedAt, animalsCount: detail.animalsCount, kind: detail.kind, lat: detail.isExact ? detail.lat : null, lng: detail.isExact ? detail.lng : null, accuracyM: detail.accuracyM, municipalityId: detail.isExact ? null : detail.municipality?.id, regionId: detail.region?.id, notes: detail.notes, visibility: visibility, mediaPath: detail.mediaPath, thumbnailPath: detail.thumbnailPath, logId: detail.logId));
      ref.invalidate(sightingDetailProvider(detail.id)); ref.invalidate(mySightingsProvider); ref.invalidate(sightingsOfProvider);
    } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(sightingDetailProvider(sightingId)).when(
    loading: () => const PageColumns(center: Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.lg), child: HBSkeleton(height: 600, radius: AppRadius.lg))),
    error: (_, __) => PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.visibility_off_outlined, title: 'sightings.unavailable.title'.tr(), message: 'sightings.unavailable.message'.tr()))))])),
    data: (detail) => SightingDetailBody(detail: detail, onDelete: () => _delete(context, ref, detail), onVisibility: (value) => _visibility(context, ref, detail, value)),
  );
}

class SightingDetailBody extends ConsumerWidget {
  final SightingDetail detail;
  final VoidCallback onDelete;
  final ValueChanged<SightingVisibility> onVisibility;
  const SightingDetailBody({super.key, required this.detail, required this.onDelete, required this.onVisibility});

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final bytes = await ref.read(sightingsRepositoryProvider).downloadPhoto(detail.mediaPath);
    final media = bytes == null ? null : ref.read(mediaUploadServiceProvider).prepareJpeg(bytes);
    final lat = detail.lat == null ? null : double.parse(detail.lat!.toStringAsFixed(2));
    final lng = detail.lng == null ? null : double.parse(detail.lng!.toStringAsFixed(2));
    if (!context.mounted) return;
    await showComposerSheet(context, initialText: 'p30b.share.text'.tr(namedArgs: {'count': '${detail.animalsCount}', 'species': detail.species.name, 'place': detail.municipality?.name ?? 'p30b.nearby.area'.tr(), 'date': DateFormat.yMMMd(context.locale.languageCode).format(detail.sightedAt.toLocal())}), initialLocationName: detail.municipality?.name ?? 'p30b.nearby.area'.tr(), initialLatitude: lat, initialLongitude: lng, initialMedia: media, initialCheckin: true, locationPrivacyNoteKey: 'p30b.share.privacy_note');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(sightingsRepositoryProvider).publicUrl(detail.mediaPath);
    final place = [if (detail.municipality != null) '${detail.municipality!.name}${detail.municipality!.provinceCode == null ? '' : ' (${detail.municipality!.provinceCode})'}', detail.unit?.name, detail.region?.name].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    final title = 'sightings.animals'.plural(detail.animalsCount, namedArgs: {'count': '${detail.animalsCount}', 'species': detail.species.name});
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      if (image != null) ...[HBCard.media(child: InkWell(onTap: () => showDialog<void>(context: context, builder: (_) => Dialog.fullscreen(backgroundColor: Colors.black, child: Stack(children: [Positioned.fill(child: InteractiveViewer(minScale: 1, maxScale: 5, child: Image.network(image, fit: BoxFit.contain))), Positioned(top: AppSpacing.lg, right: AppSpacing.lg, child: HBButton.icon(icon: Icons.close_rounded, onPressed: () => context.pop()))]))), child: AspectRatio(aspectRatio: 16 / 9, child: Image.network(image, fit: BoxFit.cover)))), const SizedBox(height: AppSpacing.lg)],
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.xs), Wrap(spacing: AppSpacing.xs, children: [HBChip(label: detail.kind.labelKey.tr(), selected: false, icon: detail.kind.icon), if (detail.isMine) HBChip(label: detail.visibility.labelKey.tr(), selected: false)]), const SizedBox(height: AppSpacing.sm), Text(DateFormat('EEEE d MMMM y · HH:mm', context.locale.languageCode).format(detail.sightedAt.toLocal()), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant))])), if (detail.isMine) PopupMenuButton<String>(onSelected: (value) { if (value == 'edit') context.push(AppRoutes.sightingEditPath(detail.id)); if (value == 'delete') onDelete(); }, itemBuilder: (_) => [PopupMenuItem(value: 'edit', child: Text('sightings.actions.edit'.tr())), PopupMenuItem(value: 'delete', child: Text('sightings.actions.delete'.tr()))])]),
      const SizedBox(height: AppSpacing.lg),
      HBTile(child: InkWell(onTap: () => context.push(AppRoutes.publicProfilePath(detail.author.username)), child: Row(children: [HBAvatar(name: detail.author.displayName, imageUrl: detail.author.avatarUrl, size: 44), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(detail.author.displayName, style: context.textStyles.titleSmall), Text('@${detail.author.username}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])), const Icon(Icons.chevron_right_rounded)]))),
      if (place.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), SightingDetailSection(icon: Icons.place_outlined, title: 'sightings.detail.place'.tr(), child: Text(place))],
      if (detail.hasPosition && detail.lat != null && detail.lng != null) ...[const SizedBox(height: AppSpacing.md), SightingDetailSection(icon: Icons.map_outlined, title: 'sightings.detail.position'.tr(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SightingPrivacyMap(latitude: detail.lat!, longitude: detail.lng!, exact: detail.isExact, accuracyM: detail.accuracyM), const SizedBox(height: AppSpacing.sm), Text((detail.isMine ? 'sightings.detail.exact_only_you' : 'sightings.detail.approximate_shared').tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), if (!detail.isExact) Text('sightings.detail.approximate_label'.tr(), style: context.textStyles.labelMedium?.withColor(LightModeColors.lightPrimary))]))],
      if (detail.notes?.isNotEmpty == true) ...[const SizedBox(height: AppSpacing.md), SightingDetailSection(icon: Icons.notes_rounded, title: 'sightings.detail.notes'.tr(), child: Text(detail.notes!))],
      if (detail.isMine && detail.outing != null) ...[const SizedBox(height: AppSpacing.md), SightingDetailSection(icon: Icons.menu_book_outlined, title: 'sightings.detail.outing'.tr(), child: HBButton.ghost(label: detail.outing!.title ?? detail.outing!.zoneName ?? 'sightings.outing_badge'.tr(), onPressed: () => context.push(AppRoutes.diaryDetailPath(detail.outing!.id))))],
      const SizedBox(height: AppSpacing.lg),
      if (detail.isMine) Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [if (detail.visibility != SightingVisibility.private) HBButton.primary(label: 'p30b.share.action'.tr(), icon: Icons.share_outlined, onPressed: () => _share(context, ref)), HBButton.secondary(label: 'sightings.actions.edit'.tr(), icon: Icons.edit_outlined, onPressed: () => context.push(AppRoutes.sightingEditPath(detail.id))), PopupMenuButton<SightingVisibility>(onSelected: onVisibility, itemBuilder: (_) => [for (final value in SightingVisibility.values) PopupMenuItem(value: value, child: Text(value.labelKey.tr()))], child: HBButton.soft(label: 'sightings.actions.change_visibility'.tr(), icon: Icons.visibility_outlined, onPressed: null)), HBButton.ghost(label: 'sightings.actions.delete'.tr(), icon: Icons.delete_outline, onPressed: onDelete)]) else Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBButton.primary(label: 'sightings.alerts.for_species_here'.tr(), icon: Icons.notifications_active_outlined, onPressed: detail.lat == null ? null : () { ref.read(sightingAlertPrefillProvider.notifier).state = SightingAlertPrefill(speciesId: detail.species.id, speciesName: detail.species.name, lat: detail.lat, lng: detail.lng); context.push('${AppRoutes.sightingAlerts}?create=1'); }), HBButton.secondary(label: 'sightings.actions.open_map'.tr(), icon: Icons.map_outlined, onPressed: detail.lat == null ? null : () => context.push('${AppRoutes.map}?lat=${detail.lat}&lng=${detail.lng}')), HBButton.ghost(label: 'sightings.actions.report'.tr(), icon: Icons.flag_outlined, onPressed: () async { if (await showReportSheet(context, targetType: 'sighting', targetId: detail.id) && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('safety.report_success'.tr()))); })]),
      const SizedBox(height: AppSpacing.xxl),
    ]))]));
  }
}

class SightingDetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const SightingDetailSection({super.key, required this.icon, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Text(title, style: context.textStyles.titleMedium)]), const SizedBox(height: AppSpacing.sm), child]));
}

class SightingPrivacyMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final bool exact;
  final double? accuracyM;
  const SightingPrivacyMap({super.key, required this.latitude, required this.longitude, required this.exact, this.accuracyM});
  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SizedBox(height: 240, child: FlutterMap(options: MapOptions(initialCenter: point, initialZoom: exact ? 15 : 13), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hbsocial.app'), CircleLayer(circles: [CircleMarker(point: point, radius: exact ? accuracyM?.clamp(10, 500) ?? 30 : 600, useRadiusInMeter: true, color: LightModeColors.lightPrimary.withValues(alpha: 0.16), borderColor: LightModeColors.lightPrimary, borderStrokeWidth: 2)]), if (exact) MarkerLayer(markers: [Marker(point: point, width: 42, height: 42, child: const Icon(Icons.location_pin, color: LightModeColors.lightError, size: 42))]), RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors', onTap: () {})])] )));
  }
}