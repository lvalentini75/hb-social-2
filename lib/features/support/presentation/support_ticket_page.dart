import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/features/support/presentation/support_page.dart';
import 'package:hb_social/features/support/providers/support_providers.dart';

class SupportTicketPage extends ConsumerStatefulWidget {
  final String ticketId;
  const SupportTicketPage({super.key, required this.ticketId});
  @override ConsumerState<SupportTicketPage> createState() => _SupportTicketPageState();
}
class _SupportTicketPageState extends ConsumerState<SupportTicketPage> {
  final reply = TextEditingController(); bool sending = false;
  @override void dispose() { reply.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final messages = ref.watch(supportMessagesProvider(widget.ticketId));
    return CustomScrollView(slivers: [SliverAppBar(title: Text('support.thread.title'.tr()), actions: [PopupMenuButton<String>(onSelected: (_) => close(), itemBuilder: (_) => [PopupMenuItem(value: 'close', child: Text('support.thread.close'.tr()))])]), SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverList.list(children: [messages.when(loading: () => const HBListSkeleton(), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'support.error'.tr(), message: 'support.error_help'.tr()), data: (items) => Column(children: [for (final message in items) Align(alignment: message.staff ? Alignment.centerLeft : Alignment.centerRight, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: HBCard(color: message.staff ? LightModeColors.boscoTint : LightModeColors.surface, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [HBAvatar(name: message.staff ? 'HB Social' : message.authorName, size: 32), const SizedBox(width: 10), Expanded(child: Text(message.body))]))))])), const SizedBox(height: 16), Row(children: [Expanded(child: HBInput(controller: reply, hint: 'support.thread.reply'.tr(), maxLines: 3)), const SizedBox(width: 8), HBButton.primary(label: 'support.thread.send'.tr(), isLoading: sending, onPressed: sending ? null : send)])]))]);
  }
  Future<void> send() async { if (reply.text.trim().isEmpty) return; setState(() => sending = true); try { await ref.read(supportRepositoryProvider).reply(widget.ticketId, reply.text); reply.clear(); ref.invalidate(supportMessagesProvider(widget.ticketId)); } catch (error) { if (mounted) showSupportError(context, error); } finally { if (mounted) setState(() => sending = false); } }
  Future<void> close() async { try { await ref.read(supportRepositoryProvider).close(widget.ticketId); if (mounted) context.pop(); } catch (error) { if (mounted) showSupportError(context, error); } }
}