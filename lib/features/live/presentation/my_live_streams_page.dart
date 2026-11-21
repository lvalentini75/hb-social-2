import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/features/live/domain/live_models.dart';
import 'package:hb_social/features/live/providers/live_providers.dart';

class MyLiveStreamsPage extends ConsumerWidget {
  const MyLiveStreamsPage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => ListPageScaffold(title: 'live.mine_title'.tr(), action: HBButton.primary(label: 'live.create'.tr(), onPressed: () => context.push(AppRoutes.liveNew)), body: ref.watch(myLiveStreamsProvider).when(loading: () => const HBListSkeleton(), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'live.error'.tr(), message: 'live.error_message'.tr()), data: (items) => items.isEmpty ? HBEmptyState(icon: Icons.live_tv_outlined, title: 'live.mine_empty'.tr(), message: 'live.mine_empty_message'.tr()) : Column(children: [for (final item in items) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: MyLiveStreamCard(stream: item))])));
}

class MyLiveStreamCard extends ConsumerWidget {
  final LiveStream stream;
  const MyLiveStreamCard({super.key, required this.stream});
  @override Widget build(BuildContext context, WidgetRef ref) => HBCard(child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(stream.title, style: AppText.cardTitle), Text('live.status.${stream.status}'.tr()), if (stream.status == 'ended') Text('live.public_summary'.tr(namedArgs: {'peak': '${stream.peakViewers}'}))])), if (stream.status == 'scheduled') HBButton.primary(label: 'live.start'.tr(), onPressed: () async { await ref.read(liveRepositoryProvider).start(stream.id); if (context.mounted) context.push(AppRoutes.livePath(stream.id)); }) else HBButton.secondary(label: 'common.open'.tr(), onPressed: () => context.push(AppRoutes.livePath(stream.id)))]));
}