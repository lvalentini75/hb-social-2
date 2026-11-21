import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/core/services/realtime_service.dart';
import 'package:hb_social/features/social_graph/domain/social_connection.dart';
import 'package:hb_social/features/social_graph/providers/social_graph_providers.dart';

class FriendRequestsPage extends ConsumerStatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  ConsumerState<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends ConsumerState<FriendRequestsPage> {
  int _tab = 0;
  final Set<String> _working = {};
  final Set<String> _hidden = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() { ref.invalidate(receivedRequestsProvider); ref.invalidate(sentRequestsProvider); ref.invalidate(pendingFriendRequestCountProvider); });
  }

  void _refresh() {
    ref.invalidate(receivedRequestsProvider); ref.invalidate(sentRequestsProvider); ref.invalidate(pendingFriendRequestCountProvider); ref.invalidate(currentProfileProvider);
  }

  Future<void> _respond(FriendRequest request, bool accept) async {
    setState(() => _working.add(request.id));
    setState(() => _hidden.add(request.id));
    try {
      await ref.read(socialGraphRepositoryProvider).respond(request.id, accept);
      _refresh();
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('friend_request_not_pending') || errorMsg.contains('friend_request_not_found')) {
        if (mounted) {
          _refresh();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('friendship.already_handled'.tr())));
        }
      } else {
        if (mounted) setState(() => _hidden.remove(request.id));
      }
    } finally {
      if (mounted) setState(() => _working.remove(request.id));
    }
  }

  Future<void> _cancel(FriendRequest request) async {
    setState(() => _working.add(request.id));
    try { await ref.read(socialGraphRepositoryProvider).cancel(request.id); _refresh(); } finally { if (mounted) setState(() => _working.remove(request.id)); }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(_tab == 0 ? receivedRequestsProvider : sentRequestsProvider);
    return CustomScrollView(slivers: [
      SliverPadding(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md), sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('friendship.requests_title'.tr(), style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.md), HBSegmentedTabs(labels: ['friendship.received'.tr(), 'friendship.sent_tab'.tr()], selectedIndex: _tab, onChanged: (index) { setState(() => _tab = index); if (index == 0) ref.invalidate(pendingFriendRequestCountProvider); })]))),
      value.when(
        loading: () => const SliverPadding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg), sliver: SliverToBoxAdapter(child: HBListSkeleton())),
        error: (_, __) => SliverPadding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), sliver: SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'friendship.error'.tr(), message: 'connections.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: _refresh))))),
        data: (allItems) {
          final items = allItems.where((item) => !_hidden.contains(item.id)).toList();
          return items.isEmpty
            ? SliverPadding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), sliver: SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.person_add_alt, title: (_tab == 0 ? 'friendship.empty_received' : 'friendship.empty_sent').tr(), message: 'friendship.empty_message'.tr()))))
            : SliverPadding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), sliver: SliverList.separated(itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md), itemBuilder: (_, index) => FriendRequestRow(request: items[index], received: _tab == 0, working: _working.contains(items[index].id), onAccept: () => _respond(items[index], true), onDecline: () => _respond(items[index], false), onCancel: () => _cancel(items[index]))));
        },
      ),
      const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
    ]);
  }
}

class FriendRequestRow extends ConsumerWidget {
  final FriendRequest request;
  final bool received;
  final bool working;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onCancel;

  const FriendRequestRow({super.key, required this.request, required this.received, required this.working, required this.onAccept, required this.onDecline, required this.onCancel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authenticated = ref.watch(authSessionProvider).value != null;
    final online = authenticated && (ref.watch(onlineUsersProvider).value?.contains(request.profile.id) ?? false);
    return HBCard(child: InkWell(onTap: () => context.push(AppRoutes.publicProfilePath(request.profile.username)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    HBAvatar(name: request.profile.displayName, imageUrl: request.profile.avatarUrl, size: 44, showPresence: online), const SizedBox(width: AppSpacing.md),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(request.profile.displayName, style: context.textStyles.titleSmall), Text(relativeTime(context, request.createdAt), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightTextTertiary)), if (request.message?.isNotEmpty == true) ...[const SizedBox(height: AppSpacing.xs), Text(request.message!, style: context.textStyles.bodyMedium?.copyWith(fontStyle: FontStyle.italic))], const SizedBox(height: AppSpacing.sm), if (received) Wrap(spacing: AppSpacing.sm, children: [HBButton.primary(label: 'friendship.accept'.tr(), size: HBButtonSize.sm, isLoading: working, onPressed: working ? null : onAccept), HBButton.soft(label: 'friendship.decline'.tr(), size: HBButtonSize.sm, onPressed: working ? null : onDecline)]) else Row(children: [Expanded(child: Text('friendship.pending'.tr(), style: context.textStyles.bodySmall)), HBButton.soft(label: 'friendship.cancel'.tr(), size: HBButtonSize.sm, isLoading: working, onPressed: working ? null : onCancel)])])),
  ])));
  }
}