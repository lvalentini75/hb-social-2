import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/dogs/domain/dog.dart';
import 'package:hb_social/features/dogs/presentation/dog_widgets.dart';
import 'package:hb_social/features/dogs/presentation/dog_cynology_sections.dart';
import 'package:hb_social/features/dogs/providers/dog_providers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

class DogProfilePage extends ConsumerWidget {
  final String dogId;
  const DogProfilePage({super.key, required this.dogId});

  Future<void> _share() => Share.share('/dogs/$dogId');

  Future<void> _setStatus(BuildContext context, WidgetRef ref, DogProfile profile) async {
    final result = await showModalBottomSheet<({DogStatus status, DateTime? date})>(context: context, useSafeArea: true, showDragHandle: true, builder: (_) => DogStatusSheet(current: profile.dog.status));
    if (result == null || !context.mounted) return;
    if (result.status == DogStatus.deceased) {
      final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('dogs.status.deceased'.tr()), content: Text('dogs.deceased_memory'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.secondary(label: 'dogs.confirm'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
      if (!confirmed) return;
    }
    try { await ref.read(dogsRepositoryProvider).setStatus(dogId, result.status, deceasedOn: result.date); ref.invalidate(dogProfileProvider(dogId)); ref.invalidate(myDogsProvider); ref.invalidate(dogsOfProvider(profile.dog.ownerId)); }
    on AppException catch (error) { if (context.mounted) _message(context, error.messageKey); }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, DogProfile profile) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('dogs.delete_title'.tr()), content: Text('dogs.delete_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.secondary(label: 'dogs.delete'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
    if (!confirmed) return;
    try { await ref.read(dogsRepositoryProvider).delete(dogId); ref.invalidate(myDogsProvider); ref.invalidate(dogsOfProvider(profile.dog.ownerId)); if (context.mounted) context.go(AppRoutes.dogs); }
    on AppException catch (error) {
      if (!context.mounted) return;
      if (error.messageKey == 'dogs.errors.in_use') {
        final status = await showDialog<DogStatus>(context: context, builder: (dialogContext) => AlertDialog(title: Text('dogs.in_use_title'.tr()), content: Text('dogs.in_use_message'.tr()), actions: [HBButton.ghost(label: 'dogs.status.retired'.tr(), onPressed: () => dialogContext.pop(DogStatus.retired)), HBButton.secondary(label: 'dogs.status.deceased'.tr(), onPressed: () => dialogContext.pop(DogStatus.deceased))]));
        if (status != null) { await ref.read(dogsRepositoryProvider).setStatus(dogId, status, deceasedOn: status == DogStatus.deceased ? DateTime.now() : null); ref.invalidate(dogProfileProvider(dogId)); ref.invalidate(myDogsProvider); ref.invalidate(dogsOfProvider(profile.dog.ownerId)); }
      } else { _message(context, error.messageKey); }
    }
  }

  void _message(BuildContext context, String key) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr())));

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(dogProfileProvider(dogId)).when(
    loading: () => const PageColumns(center: Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.lg), child: HBSkeleton(height: 520, radius: AppRadius.lg))),
    error: (_, __) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.pets_outlined, title: 'dogs.unavailable_title'.tr(), message: 'dogs.unavailable_message'.tr()))),
    data: (profile) => DogProfileBody(profile: profile, onShare: _share, onStatus: () => _setStatus(context, ref, profile), onDelete: () => _delete(context, ref, profile)),
  );
}

class DogProfileBody extends StatelessWidget {
  final DogProfile profile;
  final VoidCallback onShare;
  final VoidCallback onStatus;
  final VoidCallback onDelete;
  const DogProfileBody({super.key, required this.profile, required this.onShare, required this.onStatus, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dog = profile.dog;
    final breed = profile.breed;
    final subtitle = [dog.breed ?? 'dogs.mixed_breed'.tr(), if (breed != null) 'dogs.fci_group'.tr(namedArgs: {'group': '${breed.fciGroup}', 'name': 'dogs.fci.${breed.fciGroup}'.tr()}), if (breed != null) 'dogs.work_type.${breed.workType}'.tr()].join(' · ');
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      HBCard.media(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(clipBehavior: Clip.none, children: [AspectRatio(aspectRatio: 3, child: dog.coverUrl == null ? const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.landscape_outlined, color: LightModeColors.lightTextTertiary)) : Image.network(dog.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft))), Positioned(left: AppSpacing.lg, bottom: -44, child: HBAvatar(name: dog.name, imageUrl: dog.avatarUrl, size: 92, ringColor: LightModeColors.lightSurface))]),
        Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 54, AppSpacing.lg, AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(dog.name, style: context.textStyles.headlineSmall), const SizedBox(height: 2), Text(subtitle, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])), PopupMenuButton<String>(icon: const Icon(Icons.more_horiz_rounded), onSelected: (value) { if (value == 'share') onShare(); if (value == 'edit') context.push(AppRoutes.dogEditPath(dog.id)); if (value == 'status') onStatus(); if (value == 'delete') onDelete(); }, itemBuilder: (_) => [if (profile.isOwner) PopupMenuItem(value: 'edit', child: Text('dogs.edit'.tr())), if (profile.isOwner) PopupMenuItem(value: 'status', child: Text('dogs.change_status'.tr())), if (profile.isOwner) PopupMenuItem(value: 'delete', child: Text('dogs.delete'.tr())), PopupMenuItem(value: 'share', child: Text('dogs.share'.tr()))])]),
          const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [if (dog.status != DogStatus.active) HBStatusChip(kind: dog.status == DogStatus.deceased ? HBStatusKind.neutral : HBStatusKind.info, label: dog.status.labelKey.tr()), Text(dog.status == DogStatus.deceased && dog.deceasedOn != null ? 'dogs.deceased_on'.tr(namedArgs: {'date': DateFormat.yMMMd(context.locale.languageCode).format(dog.deceasedOn!)}) : [if (dog.sex != null) 'dogs.sex.${dog.sex}'.tr(), dogAgeLabel(context, dog.ageMonths), if (dog.color?.isNotEmpty == true) dog.color!, if (dog.weightKg != null) 'dogs.weight'.tr(namedArgs: {'value': dog.weightKg!.toStringAsFixed(1)})].join(' · '))]),
          if (dog.kennelName?.isNotEmpty == true) ...[const SizedBox(height: AppSpacing.sm), Text('dogs.kennel'.tr(namedArgs: {'name': dog.kennelName!}))],
          if (dog.description?.isNotEmpty == true) ...[const SizedBox(height: AppSpacing.md), ExpandableDescription(text: dog.description!)],
          const SizedBox(height: AppSpacing.md), InkWell(onTap: () => context.push(AppRoutes.publicProfilePath(profile.owner.username)), child: Row(mainAxisSize: MainAxisSize.min, children: [HBAvatar(name: profile.owner.displayName, imageUrl: profile.owner.avatarUrl, size: 36), const SizedBox(width: AppSpacing.sm), Text(profile.owner.displayName, style: context.textStyles.titleSmall)])),
          if (profile.breeder != null) ...[const SizedBox(height: AppSpacing.sm), InkWell(onTap: () => context.push(AppRoutes.pageDetailPath(profile.breeder!.slug)), child: Text('dogs.breeder_value'.tr(namedArgs: {'name': profile.breeder!.name}), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightPrimary)))],
        ])),
      ])),
      const SizedBox(height: AppSpacing.md), DogPedigreePanel(profile: profile),
      if (profile.nextDue != null) ...[const SizedBox(height: AppSpacing.md), DogNextDueCard(record: profile.nextDue!)],
      const SizedBox(height: AppSpacing.md), DogStatsPanel(profile: profile),
      const SizedBox(height: AppSpacing.md), DogTrialsSection(profile: profile),
      if (profile.health != null) ...[const SizedBox(height: AppSpacing.md), DogHealthSection(profile: profile)],
      if (profile.recentOutings.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), DogOutingsPanel(items: profile.recentOutings)],
      if (profile.recentPosts.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), DogPostsPanel(items: profile.recentPosts)],
      const SizedBox(height: AppSpacing.xxl),
    ]))]));
  }
}

class ExpandableDescription extends StatefulWidget {
  final String text;
  const ExpandableDescription({super.key, required this.text});
  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}
class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.text, maxLines: expanded ? null : 4, overflow: expanded ? null : TextOverflow.ellipsis), if (widget.text.length > 180) HBButton.ghost(label: (expanded ? 'dogs.show_less' : 'dogs.show_all').tr(), onPressed: () => setState(() => expanded = !expanded), size: HBButtonSize.sm)]);
}

class DogPedigreePanel extends StatelessWidget {
  final DogProfile profile;
  const DogPedigreePanel({super.key, required this.profile});
  @override
  Widget build(BuildContext context) {
    final dog = profile.dog;
    final empty = [dog.pedigreeNumber, dog.fatherName, dog.motherName, dog.microchipNumber].every((item) => item?.isNotEmpty != true);
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('dogs.pedigree'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.md), if (empty && profile.isOwner) HBButton.soft(label: 'dogs.add_pedigree'.tr(), onPressed: () => context.push(AppRoutes.dogEditPath(dog.id))) else ...[if (dog.pedigreeNumber != null) DogInfoRow(label: 'dogs.pedigree_number'.tr(), value: dog.pedigreeNumber!), if (dog.fatherName != null) DogInfoRow(label: 'dogs.father'.tr(), value: dog.fatherName!), if (dog.motherName != null) DogInfoRow(label: 'dogs.mother'.tr(), value: dog.motherName!), if (profile.isOwner && dog.microchipNumber != null) DogInfoRow(label: 'dogs.microchip'.tr(), value: dog.microchipNumber!, action: HBButton.ghost(label: 'dogs.copy'.tr(), onPressed: () => Clipboard.setData(ClipboardData(text: dog.microchipNumber!)), size: HBButtonSize.sm))]]) );
  }
}

class DogInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? action;
  const DogInfoRow({super.key, required this.label, required this.value, this.action});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Row(children: [SizedBox(width: 120, child: Text(label, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))), Expanded(child: Text(value)), if (action != null) action!]));
}

class DogStatsPanel extends StatelessWidget {
  final DogProfile profile;
  const DogStatsPanel({super.key, required this.profile});
  @override
  Widget build(BuildContext context) {
    final stats = profile.stats;
    final values = [('dogs.stats.outings', stats.outings), ('dogs.stats.harvests', stats.harvests), ('dogs.stats.seasons', stats.seasons), ('dogs.stats.trials', stats.trials)];
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('dogs.stats.title'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.md), LayoutBuilder(builder: (_, constraints) => Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final item in values) SizedBox(width: (constraints.maxWidth - AppSpacing.sm) / 2, child: HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${item.$2}', style: context.textStyles.headlineSmall), Text(item.$1.tr(), style: context.textStyles.bodySmall)])))])), if (stats.lastOuting != null) ...[const SizedBox(height: AppSpacing.md), Text('dogs.stats.last_outing'.tr(namedArgs: {'time': timeago.format(stats.lastOuting!.toLocal(), locale: context.locale.languageCode)}))], if (stats.outings > 0 && profile.recentOutings.isEmpty) ...[const SizedBox(height: AppSpacing.sm), Text('dogs.stats.private_outings'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))], if (stats.bySpecies.isNotEmpty) ...[const SizedBox(height: AppSpacing.lg), Text('dogs.stats.by_species'.tr(), style: context.textStyles.titleSmall), for (final item in stats.bySpecies) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Row(children: [Expanded(child: Text(item.nameIt.isEmpty ? item.scientificName : item.nameIt)), Text('dogs.stats.species_values'.tr(namedArgs: {'harvests': '${item.harvests}', 'outings': '${item.outings}'}))]))]]) );
  }
}

class DogOutingsPanel extends StatelessWidget {
  final List<DogRecentOuting> items;
  const DogOutingsPanel({super.key, required this.items});
  @override
  Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('dogs.recent_outings'.tr(), style: context.textStyles.titleMedium), for (final item in items) ListTile(contentPadding: EdgeInsets.zero, title: Text(item.title ?? item.zoneName ?? 'diary.default_outing'.tr()), subtitle: Text(DateFormat.yMMMd(context.locale.languageCode).format(item.startedAt.toLocal())), trailing: Text('dogs.harvest_count'.tr(namedArgs: {'count': '${item.harvestTotal}'})), onTap: () => context.push(AppRoutes.diaryDetailPath(item.id))) ]));
}

class DogPostsPanel extends StatelessWidget {
  final List<DogRecentPost> items;
  const DogPostsPanel({super.key, required this.items});
  @override
  Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('dogs.recent_posts'.tr(), style: context.textStyles.titleMedium), for (final item in items) ListTile(contentPadding: EdgeInsets.zero, leading: item.mediaUrl == null ? const Icon(Icons.article_outlined) : ClipRRect(borderRadius: BorderRadius.circular(AppRadius.xs), child: Image.network(item.mediaUrl!, width: 52, height: 52, fit: BoxFit.cover)), title: Text(item.content?.isNotEmpty == true ? item.content! : 'dogs.post'.tr(), maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: Text(timeago.format(item.createdAt.toLocal(), locale: context.locale.languageCode)), onTap: () => context.push(AppRoutes.postPath(item.id))) ]));
}

class DogStatusSheet extends StatefulWidget {
  final DogStatus current;
  const DogStatusSheet({super.key, required this.current});
  @override
  State<DogStatusSheet> createState() => _DogStatusSheetState();
}
class _DogStatusSheetState extends State<DogStatusSheet> {
  late DogStatus status = widget.current;
  DateTime? date;
  Future<void> _date() async { final value = await showDatePicker(context: context, initialDate: date ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365 * 25)), lastDate: DateTime.now()); if (value != null) setState(() => date = value); }
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('dogs.change_status'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), for (final item in DogStatus.values) RadioListTile<DogStatus>(value: item, groupValue: status, title: Text(item.labelKey.tr()), onChanged: (value) => setState(() => status = value!)), if (status == DogStatus.deceased) HBButton.secondary(label: date == null ? 'dogs.select_date'.tr() : DateFormat.yMMMd(context.locale.languageCode).format(date!), onPressed: _date), const SizedBox(height: AppSpacing.md), HBButton.primary(label: 'common.save'.tr(), onPressed: status == DogStatus.deceased && date == null ? null : () => context.pop((status: status, date: date)))]));
}