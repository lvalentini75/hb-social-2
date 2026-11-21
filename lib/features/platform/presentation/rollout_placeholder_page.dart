import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/page_columns.dart';

class RolloutPlaceholderPage extends StatelessWidget {
  final String module;
  const RolloutPlaceholderPage({super.key, required this.module});
  @override Widget build(BuildContext context) => PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.all(24), sliver: SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: module == 'reels' ? Icons.video_collection_outlined : Icons.live_tv_outlined, title: '$module.title'.tr(), message: '$module.rollout_message'.tr()))))]));
}