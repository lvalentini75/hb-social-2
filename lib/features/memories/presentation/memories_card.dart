import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/features/feed/presentation/widgets/share_sheet.dart';
import 'package:hb_social/features/home/providers/feed_providers.dart';
import 'package:hb_social/features/memories/domain/memory.dart';
import 'package:hb_social/features/memories/providers/memories_providers.dart';

class MemoriesTodayCard extends ConsumerWidget {
  const MemoriesTodayCard({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(memoriesTodayProvider).maybeWhen(data: (items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: HBCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('memories.title'.tr(), style: context.textStyles.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(height: 280, child: PageView.builder(controller: PageController(viewportFraction: items.length == 1 ? 1 : .88), itemCount: items.length, itemBuilder: (_, index) => Padding(padding: EdgeInsets.only(right: index < items.length - 1 ? AppSpacing.sm : 0), child: MemoryTile(item: items[index])))),
        ]),
      ),
    );
  }, orElse: () => const SizedBox.shrink());
}

class MemoryTile extends ConsumerWidget {
  final MemoryItem item;
  const MemoryTile({super.key, required this.item});

  void _open(BuildContext context) => context.push(item.itemType == 'post' ? AppRoutes.postPath(item.itemId) : AppRoutes.diaryDetailPath(item.itemId));

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    try {
      final post = await ref.read(feedRepositoryProvider).getById(item.itemId);
      if (post != null && context.mounted) await showShareSheet(context, post, initialText: item.yearsAgo == 1 ? 'memories.share_one'.tr() : 'memories.share_many'.tr(namedArgs: {'years': '${item.yearsAgo}'}));
    } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(memoriesRepositoryProvider).dismiss(item);
      ref.invalidate(memoriesTodayProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('memories.dismissed'.tr())));
    } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  @override Widget build(BuildContext context, WidgetRef ref) {
    final image = item.thumbnailPath ?? item.mediaPath;
    return InkWell(onTap: () => _open(context), borderRadius: BorderRadius.circular(AppRadius.md), child: Container(decoration: BoxDecoration(color: LightModeColors.surfaceSoft, borderRadius: BorderRadius.circular(AppRadius.md)), clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: image == null ? Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text(item.text ?? item.locationName ?? '', maxLines: 6, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: context.textStyles.titleMedium))) : Stack(fit: StackFit.expand, children: [Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.boscoTint, child: Icon(Icons.history_rounded))), if (item.kind == 'video') const Center(child: Icon(Icons.play_circle_fill_rounded, size: 52, color: Colors.white))])),
      Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.yearsAgo == 1 ? 'memories.one_year'.tr() : 'memories.years'.tr(namedArgs: {'years': '${item.yearsAgo}'}), style: context.textStyles.labelLarge?.withColor(LightModeColors.bosco)), if (item.itemType == 'hunting_log') Text('memories.outing_meta'.tr(namedArgs: {'place': item.locationName ?? '', 'count': '${item.countA}'}), maxLines: 1, overflow: TextOverflow.ellipsis), Row(children: [if (item.itemType == 'post') HBButton.ghost(label: 'memories.share'.tr(), icon: Icons.ios_share_outlined, size: HBButtonSize.sm, onPressed: () => _share(context, ref)), const Spacer(), HBButton.ghost(label: 'memories.hide'.tr(), size: HBButtonSize.sm, onPressed: () => _dismiss(context, ref))])]))
    ])));
  }
}