import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/features/reels/providers/reels_providers.dart';

class ProfileReelsGrid extends ConsumerWidget {
  final String userId;
  final bool isOwn;
  const ProfileReelsGrid({super.key, required this.userId, required this.isOwn});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(reelsByUserProvider(userId)).when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'reels.errors.title'.tr(), message: 'reels.errors.generic'.tr()),
    data: (items) {
      if (items.isEmpty) return HBEmptyState(icon: Icons.video_collection_outlined, title: 'reels.profile.empty'.tr(), message: 'reels.empty.message'.tr());
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 9 / 16, crossAxisSpacing: 3, mainAxisSpacing: 3),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(onTap: () => context.push(AppRoutes.reelPath(item.postId)), child: Stack(fit: StackFit.expand, children: [
            if (item.thumbnailUrl != null) Image.network(item.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.surfaceSoft)) else const ColoredBox(color: LightModeColors.surfaceSoft),
            Positioned(left: 6, bottom: 6, child: Row(children: [const Icon(Icons.play_arrow_rounded, size: 14, color: Colors.white), Text('${item.viewCount}', style: AppText.small.copyWith(color: Colors.white))])),
            Positioned(right: 6, bottom: 6, child: Text('${item.durationSeconds ~/ 60}:${(item.durationSeconds % 60).toString().padLeft(2, '0')}', style: AppText.small.copyWith(color: Colors.white))),
          ]));
        },
      );
    },
  );
}