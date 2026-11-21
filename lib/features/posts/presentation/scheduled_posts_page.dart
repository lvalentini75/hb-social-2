import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_page_header.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/feed/presentation/widgets/post_media_grid.dart';
import 'package:hb_social/features/posts/domain/scheduled_post.dart';
import 'package:hb_social/features/posts/providers/scheduled_posts_providers.dart';

class ScheduledPostsPage extends ConsumerWidget {
  final String? pageId;
  const ScheduledPostsPage({super.key, this.pageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(scheduledPostsProvider(pageId));
    return PageColumns(center: CustomScrollView(slivers: [
      SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
        HBPageHeader(title: 'posts.scheduled.title'.tr(), subtitle: 'posts.scheduled.subtitle'.tr()),
        const SizedBox(height: AppSpacing.md),
        value.when(
          loading: () => const HBListSkeleton(count: 4),
          error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'posts.scheduled.error_title'.tr(), message: 'posts.scheduled.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(scheduledPostsProvider(pageId))))),
          data: (items) => items.isEmpty
              ? HBCard(child: HBEmptyState(icon: Icons.schedule_outlined, title: 'posts.scheduled.empty_title'.tr(), message: 'posts.scheduled.empty_message'.tr()))
              : Column(children: [for (var index = 0; index < items.length; index++) ...[ScheduledPostCard(item: items[index], pageId: pageId), if (index < items.length - 1) const SizedBox(height: AppSpacing.md)]]),
        ),
      ])),
    ]));
  }
}

class ScheduledPostCard extends ConsumerWidget {
  final ScheduledPost item;
  final String? pageId;
  const ScheduledPostCard({super.key, required this.item, this.pageId});

  Future<void> _run(BuildContext context, WidgetRef ref, String action) async {
    final repository = ref.read(scheduledPostsRepositoryProvider);
    try {
      if (action == 'publish') await repository.publishNow(item.post.id);
      if (action == 'reschedule') {
        final value = await showDialog<DateTime>(context: context, builder: (_) => ScheduledDateDialog(initial: item.scheduledAt));
        if (value == null) return;
        await repository.reschedule(item.post.id, value);
      }
      if (action == 'delete') {
        final confirmed = await showDialog<bool>(context: context, builder: (_) => const ScheduledDeleteDialog()) ?? false;
        if (!confirmed) return;
        await repository.delete(item.post.id);
      }
      ref.invalidate(scheduledPostsProvider(pageId));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('posts.scheduled.action_done'.tr())));
    } on AppException catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = item.post;
    final identity = post.page?.name ?? post.author.displayName;
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        HBAvatar(name: identity, imageUrl: post.page?.avatarUrl ?? post.author.avatarUrl, size: 42),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(identity, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall), const SizedBox(height: AppSpacing.xs), HBStatusChip(kind: HBStatusKind.pending, label: 'posts.scheduled.badge'.tr(namedArgs: {'date': DateFormat.yMd(context.locale.toString()).add_Hm().format(item.scheduledAt.toLocal())}))])),
        PopupMenuButton<String>(onSelected: (value) => _run(context, ref, value), itemBuilder: (_) => [PopupMenuItem(value: 'publish', child: Text('posts.scheduled.publish_now'.tr())), PopupMenuItem(value: 'reschedule', child: Text('posts.scheduled.change_date'.tr())), PopupMenuItem(value: 'delete', child: Text('posts.scheduled.delete'.tr()))]),
      ]),
      if (post.group != null || post.page != null) ...[const SizedBox(height: AppSpacing.sm), HBChip(label: post.group?.name ?? post.page!.name, selected: false, icon: post.group != null ? Icons.group_outlined : Icons.flag_outlined)],
      if (post.content?.isNotEmpty == true) ...[const SizedBox(height: AppSpacing.md), Text(post.content!, maxLines: 6, overflow: TextOverflow.ellipsis)],
      if (post.media.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), SensitivePostMedia(post: post)],
      const SizedBox(height: AppSpacing.sm),
      Text('posts.scheduled.created'.tr(namedArgs: {'time': relativeTime(context, post.createdAt)}), style: context.textStyles.bodySmall?.withColor(LightModeColors.textSecondary)),
    ]));
  }
}

class ScheduledDateDialog extends StatefulWidget {
  final DateTime initial;
  const ScheduledDateDialog({super.key, required this.initial});
  @override State<ScheduledDateDialog> createState() => _ScheduledDateDialogState();
}

class _ScheduledDateDialogState extends State<ScheduledDateDialog> {
  late DateTime value = widget.initial.toLocal();
  Future<void> _pick() async {
    final date = await showDatePicker(context: context, initialDate: value, firstDate: DateTime.now().add(const Duration(minutes: 5)), lastDate: DateTime.now().add(const Duration(days: 30)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value));
    if (time != null) setState(() => value = DateTime(date.year, date.month, date.day, time.hour, (time.minute ~/ 5) * 5));
  }
  @override Widget build(BuildContext context) => AlertDialog(title: Text('composer.schedule.action'.tr()), content: InkWell(onTap: _pick, child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), child: Row(children: [const Icon(Icons.schedule_outlined), const SizedBox(width: AppSpacing.sm), Text(DateFormat.yMd(context.locale.toString()).add_Hm().format(value))]))), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop()), HBButton.primary(label: 'common.save'.tr(), onPressed: () => context.pop(value))]);
}

class ScheduledDeleteDialog extends StatelessWidget {
  const ScheduledDeleteDialog({super.key});
  @override Widget build(BuildContext context) => AlertDialog(title: Text('posts.scheduled.delete_title'.tr()), content: Text('posts.scheduled.delete_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop(false)), HBButton.primary(label: 'posts.scheduled.delete'.tr(), onPressed: () => context.pop(true))]);
}