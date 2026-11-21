import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/features/support/domain/support_ticket.dart';
import 'package:hb_social/features/support/presentation/support_ticket_form.dart';
import 'package:hb_social/features/support/providers/support_providers.dart';
import 'package:timeago/timeago.dart' as timeago;

class SupportPage extends ConsumerWidget {
  const SupportPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(supportTicketsProvider);
    return ListPageScaffold(title: 'support.title'.tr(), subtitle: 'support.subtitle'.tr(), action: HBButton.primary(label: 'support.new'.tr(), icon: Icons.add, onPressed: () async { await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const SupportTicketForm()); ref.invalidate(supportTicketsProvider); }), body: tickets.when(
      loading: () => const HBListSkeleton(),
      error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'support.error'.tr(), message: 'support.error_help'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(supportTicketsProvider))),
      data: (items) => items.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.support_agent_outlined, title: 'support.empty'.tr(), message: 'support.empty_help'.tr())) : Column(children: [for (final item in items) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: SupportTicketCard(ticket: item))]),
    ));
  }
}

class SupportTicketCard extends StatelessWidget {
  final SupportTicket ticket;
  const SupportTicketCard({super.key, required this.ticket});
  @override Widget build(BuildContext context) => HBCard(child: InkWell(onTap: () => context.push(AppRoutes.supportTicketPath(ticket.id)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(ticket.subject, style: context.textStyles.titleMedium), const SizedBox(height: 6), Wrap(spacing: 8, children: [HBStatusChip(kind: ticket.status == 'closed' ? HBStatusKind.neutral : ticket.status == 'answered' ? HBStatusKind.approved : HBStatusKind.pending, label: 'support.status.${ticket.status}'.tr()), Text('support.category.${ticket.category}'.tr()), Text('support.last_activity'.tr(namedArgs: {'time': timeago.format(ticket.lastMessageAt.toLocal(), locale: context.locale.languageCode)}))])])), if (ticket.unreadStaffReplies > 0) HBBadge.label(label: '${ticket.unreadStaffReplies}')])));
}

void showSupportError(BuildContext context, Object error) { final key = error is AppException ? error.messageKey : 'support.error'; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr()))); }