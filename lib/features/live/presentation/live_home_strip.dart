import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/live/presentation/live_widgets.dart';
import 'package:hb_social/features/live/providers/live_providers.dart';

class LiveHomeStrip extends ConsumerWidget {
  const LiveHomeStrip({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(liveActiveProvider).maybeWhen(data: (items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('live.home_title'.tr(), style: AppText.title),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(height: 200, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm), itemBuilder: (_, index) => LiveStreamCard(stream: items[index], onTap: () => context.push(AppRoutes.livePath(items[index].id))))),
      ]),
    );
  }, orElse: () => const SizedBox.shrink());
}