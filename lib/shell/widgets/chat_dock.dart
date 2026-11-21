import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/chat/presentation/conversation_page.dart';
import 'package:hb_social/features/chat/presentation/messages_page.dart';
import 'package:hb_social/features/chat/providers/chat_providers.dart';

/// Persistent desktop messaging surface shared by all non-message shell pages.
class ChatDock extends ConsumerWidget {
  final bool enabled;
  const ChatDock({super.key, this.enabled = true});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    if (!enabled || MediaQuery.sizeOf(context).width < AppBreakpoints.mobile || ref.watch(authSessionProvider).value == null || path.startsWith('/messages')) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;
    final dock = ref.watch(chatDockProvider);
    final unread = ref.watch(unreadConversationsCountProvider).value ?? 0;
    final panel = Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
        for (final id in dock.openIds) ...[ChatDockWindow(conversationId: id, minimized: dock.minimizedIds.contains(id)), const SizedBox(width: AppSpacing.sm)],
        if (dock.listOpen) ChatDockList(),
      ]),
      const SizedBox(height: AppSpacing.sm),
      Material(elevation: 3, shadowColor: LightModeColors.lightShadow, borderRadius: BorderRadius.circular(AppRadius.pill), color: LightModeColors.lightSurface, child: InkWell(borderRadius: BorderRadius.circular(AppRadius.pill), onTap: () => ref.read(chatDockProvider.notifier).toggleList(), child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.chat_bubble_outline_rounded, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Text('nav.messages'.tr(), style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w700)), if (unread > 0) ...[const SizedBox(width: AppSpacing.sm), HBBadge.count(count: unread)]])))),
    ]);
    return Positioned(right: width >= 1280 ? AppSpacing.xl : AppSpacing.lg, bottom: AppSpacing.md, child: panel);
  }
}

class ChatDockList extends ConsumerWidget {
  const ChatDockList({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(width: 360, height: 560, child: HBCard(shadow: AppShadows.level3, child: ConversationInbox(selectedId: null, compact: true, onNewConversation: () => showNewConversationSheet(context), onConversationTap: (id) => ref.read(chatDockProvider.notifier).open(id))));
}

class ChatDockWindow extends ConsumerWidget {
  final String conversationId;
  final bool minimized;
  const ChatDockWindow({super.key, required this.conversationId, required this.minimized});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = ref.watch(conversationProvider(conversationId));
    final me = ref.watch(authSessionProvider).value?.user.id;
    if (minimized) return Material(elevation: 3, borderRadius: BorderRadius.circular(AppRadius.pill), color: LightModeColors.lightSurface, child: InkWell(onTap: () => ref.read(chatDockProvider.notifier).toggleMinimized(conversationId), child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm), child: Text(conversation.value?.displayName(me) ?? 'nav.messages'.tr()))));
    return SizedBox(width: 340, height: 460, child: HBCard(shadow: AppShadows.level3, child: conversation.when(loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'chat.error_title'.tr(), message: 'chat.error_message'.tr()), data: (item) => item == null ? HBEmptyState(icon: Icons.chat_bubble_outline, title: 'chat.unavailable_title'.tr(), message: 'chat.unavailable_message'.tr()) : Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), child: Row(children: [Expanded(child: Text(item.displayName(me), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall)), HBButton.icon(icon: Icons.remove_rounded, onPressed: () => ref.read(chatDockProvider.notifier).toggleMinimized(conversationId)), HBButton.icon(icon: Icons.open_in_full_rounded, onPressed: () => context.go(AppRoutes.conversationDetailPath(conversationId))), HBButton.icon(icon: Icons.close_rounded, onPressed: () => ref.read(chatDockProvider.notifier).close(conversationId))])),
      const Divider(height: 1), Expanded(child: ConversationThread(conversation: item)),
    ]))));
  }
}