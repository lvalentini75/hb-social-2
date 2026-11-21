import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/features/reels/domain/reel.dart';
import 'package:hb_social/features/reels/providers/reels_providers.dart';

class MyReelsPage extends ConsumerWidget {
  const MyReelsPage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => ListPageScaffold(title: 'reels.mine.title'.tr(), action: HBButton.primary(label: 'reels.create'.tr(), icon: Icons.add, onPressed: () => context.push(AppRoutes.reelsNew)), body: ref.watch(myReelsProvider).when(loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'reels.errors.title'.tr(), message: 'reels.errors.generic'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(myReelsProvider))), data: (items) => items.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.video_collection_outlined, title: 'reels.mine.empty'.tr(), message: 'reels.empty.message'.tr())) : Column(children: [for (final item in items) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: MyReelCard(item: item))])));
}

class MyReelCard extends ConsumerWidget {
  final ReelVideo item;
  const MyReelCard({super.key, required this.item});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final online = item.status == 'ready' && item.postId != null;
    final failed = item.status == 'failed';
    return HBCard(child: InkWell(onTap: online ? () => context.push(AppRoutes.reelPath(item.postId!)) : null, child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(AppRadius.media), child: SizedBox(width: 72, height: 112, child: item.thumbnailUrl == null ? const ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.video_file_outlined)) : Image.network(item.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.video_file_outlined))))),
      const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.caption?.isNotEmpty == true ? item.caption! : 'reels.caption_empty'.tr(), maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.cardTitle), const SizedBox(height: 6), HBStatusChip(kind: failed ? HBStatusKind.rejected : online ? HBStatusKind.approved : HBStatusKind.pending, label: online ? 'reels.status.ready'.tr(namedArgs: {'views': '${item.viewCount}'}) : failed ? 'reels.status.failed'.tr(namedArgs: {'reason': item.error == 'reel_too_long' ? 'reels.failure.too_long'.tr() : 'reels.failure.processing'.tr()}) : 'reels.status.${item.status}'.tr()), const SizedBox(height: 6), Text(relativeTime(context, item.submittedAt ?? item.createdAt), style: AppText.caption.copyWith(color: LightModeColors.textSecondary)), if (failed) Row(children: [HBButton.ghost(label: 'reels.mine.retry'.tr(), size: HBButtonSize.sm, onPressed: () => context.push(AppRoutes.reelsNew)), HBButton.ghost(label: 'reels.mine.remove'.tr(), size: HBButtonSize.sm, onPressed: () async { await ref.read(reelsRepositoryProvider).discard(item.id); ref.invalidate(myReelsProvider); })])]))
    ])));
  }
}