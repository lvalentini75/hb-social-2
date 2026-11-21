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
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/core/widgets/hb_page_header.dart';
import 'package:hb_social/features/dogs/domain/dog.dart';
import 'package:hb_social/features/dogs/presentation/dog_widgets.dart';
import 'package:hb_social/features/dogs/providers/dog_providers.dart';

class DogsPage extends ConsumerStatefulWidget {
  const DogsPage({super.key});
  @override
  ConsumerState<DogsPage> createState() => _DogsPageState();
}

class _DogsPageState extends ConsumerState<DogsPage> {
  bool archiveOpen = false;

  @override
  Widget build(BuildContext context) => PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg), sliver: SliverList.list(children: [
    ref.watch(myDogsProvider).when(
      loading: () => const HBListSkeleton(count: 3),
      error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'dogs.error_title'.tr(), message: 'dogs.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(myDogsProvider)))),
      data: (dogs) {
        final active = dogs.where((dog) => dog.status == DogStatus.active).toList();
        final archived = dogs.where((dog) => dog.status != DogStatus.active).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HBPageHeader(title: 'dogs.title'.tr(), subtitle: 'dogs.subtitle'.tr(), action: MediaQuery.sizeOf(context).width < AppBreakpoints.mobile ? null : Row(mainAxisSize: MainAxisSize.min, children: [HBButton.ghost(label: 'dogs.search.action'.tr(), icon: Icons.search_rounded, onPressed: () => context.push(AppRoutes.dogsSearch)), const SizedBox(width: AppSpacing.sm), HBButton.primary(label: 'dogs.add'.tr(), icon: Icons.add_rounded, onPressed: () => context.push(AppRoutes.dogsNew))])),
          const SizedBox(height: AppSpacing.md),
          if (MediaQuery.sizeOf(context).width < AppBreakpoints.mobile) ...[Row(children: [Expanded(child: HBButton.secondary(label: 'dogs.search.action'.tr(), icon: Icons.search_rounded, onPressed: () => context.push(AppRoutes.dogsSearch))), const SizedBox(width: AppSpacing.sm), Expanded(child: HBButton.primary(label: 'dogs.add'.tr(), icon: Icons.add_rounded, onPressed: () => context.push(AppRoutes.dogsNew)))]), const SizedBox(height: AppSpacing.md)],
          DogRemindersCard(reminders: ref.watch(dogRemindersProvider)),
          const SizedBox(height: AppSpacing.lg),
          if (dogs.isEmpty) HBCard(child: HBEmptyState(icon: Icons.pets_outlined, title: 'dogs.empty_title'.tr(), message: 'dogs.empty_message'.tr(), action: HBButton.primary(label: 'dogs.add'.tr(), onPressed: () => context.push(AppRoutes.dogsNew)))) else ...[
            if (active.isNotEmpty) DogCards(dogs: active),
            if (archived.isNotEmpty) ...[const SizedBox(height: AppSpacing.lg), InkWell(onTap: () => setState(() => archiveOpen = !archiveOpen), child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Row(children: [Expanded(child: Text('dogs.archive'.tr(namedArgs: {'count': '${archived.length}'}), style: context.textStyles.titleMedium)), Icon(archiveOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded)]))), if (archiveOpen) DogCards(dogs: archived)],
          ],
        ]);
      },
    ),
  ]))]));
}

class DogRemindersCard extends StatelessWidget {
  final AsyncValue<List<DogReminder>> reminders;
  const DogRemindersCard({super.key, required this.reminders});
  @override
  Widget build(BuildContext context) => reminders.when(loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink(), data: (items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('dogs.reminders.title'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), for (final item in items) ListTile(contentPadding: EdgeInsets.zero, leading: Icon(item.daysLeft < 0 ? Icons.warning_amber_rounded : Icons.notifications_active_outlined, color: item.daysLeft < 0 ? LightModeColors.lightError : LightModeColors.lightWarning), title: Text('dogs.reminders.item'.tr(namedArgs: {'title': item.title, 'dog': item.dogName})), subtitle: Text(item.daysLeft < 0 ? 'dogs.reminders.overdue'.tr(namedArgs: {'days': '${-item.daysLeft}'}) : 'dogs.reminders.in_days'.tr(namedArgs: {'days': '${item.daysLeft}'})), onTap: () => context.push('${AppRoutes.dogDetailPath(item.dogId)}?section=health'))]));
  });
}