import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/events/domain/hunting_event.dart';
import 'package:hb_social/features/events/presentation/event_map.dart';
import 'package:hb_social/features/events/providers/event_providers.dart';
import 'package:hb_social/features/orders/providers/order_providers.dart';

class EventManagePage extends ConsumerStatefulWidget {
  final String eventId;
  const EventManagePage({super.key, required this.eventId});
  @override
  ConsumerState<EventManagePage> createState() => _EventManagePageState();
}

class _EventManagePageState extends ConsumerState<EventManagePage> {
  String _tab = 'overview';

  void _refresh() {
    ref.invalidate(eventByIdProvider(widget.eventId));
    ref.invalidate(eventOrganizerSummaryProvider(widget.eventId));
    ref.invalidate(eventParticipantsProvider(widget.eventId));
    ref.invalidate(eventsProvider);
  }

  Future<void> _setStatus(HuntingEvent event, String status) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => EventStatusConfirmation(titleKey: status == 'cancelled' ? 'event_manage.cancel_title' : 'event_manage.publish_title', messageKey: status == 'cancelled' ? 'event_manage.cancel_message' : 'event_manage.publish_message', actionKey: status == 'cancelled' ? 'event_manage.cancel_event' : 'event_manage.publish')) ?? false;
    if (!confirmed) return;
    try {
      await ref.read(eventRepositoryProvider).setEventStatus(event.id, status);
      _refresh();
    } on AppException catch (error) { if (mounted) _message(error.messageKey); }
  }

  void _message(String key) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr())));

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventByIdProvider(widget.eventId));
    final summaryAsync = ref.watch(eventOrganizerSummaryProvider(widget.eventId));
    if (eventAsync.isLoading || summaryAsync.isLoading) return const PageColumns(center: HBListSkeleton(count: 5));
    if (eventAsync.hasError || summaryAsync.hasError) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'event_manage.load_error_title'.tr(), message: 'event_manage.load_error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: _refresh))));
    final event = eventAsync.value;
    if (event == null) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.event_busy_outlined, title: 'events.not_found_title'.tr(), message: 'events.not_found_message'.tr())));
    final summary = summaryAsync.value;
    if (summary == null) return PageColumns(center: EventManageDenied(eventId: event.id));
    final tabs = ['overview', 'participants', 'waitlist', 'checkin', if (summary.isPaidEvent) 'payments'];
    if (!tabs.contains(_tab)) _tab = tabs.first;
    final badges = <int?>[null, summary.confirmed, summary.waitlist, summary.checkedIn, if (summary.isPaidEvent) summary.pendingPayment];
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      HBCard(padding: const EdgeInsets.all(AppSpacing.lg), child: EventManageHeader(event: event, onStatus: (status) => _setStatus(event, status))),
      if (summary.isPaidEvent && !(ref.watch(sellerAccountProvider).value?.active ?? false)) ...[const SizedBox(height: AppSpacing.md), HBTile(child: Row(children: [const Icon(Icons.credit_card_off_outlined), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('p34b.activate_payments_banner'.tr())), HBButton.primary(label: 'orders.activate_payments'.tr(), onPressed: () => context.push(AppRoutes.paymentSettings))]))],
      if (event.status == 'cancelled' && summary.isPaidEvent) ...[const SizedBox(height: AppSpacing.md), HBTile(child: Text('p34b.cancelled_refund_note'.tr()))],
      const SizedBox(height: AppSpacing.md),
      HBSegmentedTabs(labels: tabs.map((tab) => 'event_manage.tabs.$tab'.tr()).toList(), badges: badges, selectedIndex: tabs.indexOf(_tab), scrollable: true, onChanged: (index) => setState(() => _tab = tabs[index])),
      const SizedBox(height: AppSpacing.md),
      switch (_tab) {
        'overview' => EventManageOverview(event: event, summary: summary, onPublish: () => _setStatus(event, 'published')),
        'participants' => EventParticipantsPanel(event: event, mode: EventParticipantMode.participants, onChanged: _refresh),
        'waitlist' => EventParticipantsPanel(event: event, mode: EventParticipantMode.waitlist, onChanged: _refresh),
        'checkin' => EventCheckinPanel(event: event, summary: summary),
        _ => EventPaymentsPanel(event: event, summary: summary, onChanged: _refresh),
      },
      if (MediaQuery.sizeOf(context).width < 900) const SizedBox(height: 88),
    ]))]));
  }
}

class EventManageDenied extends StatelessWidget {
  final String eventId;
  const EventManageDenied({super.key, required this.eventId});
  @override
  Widget build(BuildContext context) => HBCard(child: HBEmptyState(icon: Icons.admin_panel_settings_outlined, title: 'event_manage.denied_title'.tr(), message: 'event_manage.denied_message'.tr(), action: HBButton.primary(label: 'event_manage.back_to_event'.tr(), onPressed: () => context.go(AppRoutes.eventDetailPath(eventId)))));
}

class EventManageHeader extends StatelessWidget {
  final HuntingEvent event;
  final ValueChanged<String> onStatus;
  const EventManageHeader({super.key, required this.event, required this.onStatus});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(event.title, style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.xs), Text('${DateFormat.yMMMMd(context.locale.toLanguageTag()).add_jm().format(event.startsAt.toLocal())} · ${event.location ?? event.address ?? 'common.unavailable'.tr()}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis)])), const SizedBox(width: AppSpacing.sm), HBStatusChip(kind: event.status == 'published' ? HBStatusKind.approved : event.status == 'cancelled' ? HBStatusKind.rejected : HBStatusKind.neutral, label: 'events.status.${event.status}'.tr())]),
    const SizedBox(height: AppSpacing.md),
    Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBButton.secondary(label: 'event_manage.edit'.tr(), icon: Icons.edit_outlined, onPressed: () => context.push(AppRoutes.eventEditPath(event.id))), if (event.status == 'draft') HBButton.primary(label: 'event_manage.publish'.tr(), icon: Icons.publish_outlined, onPressed: () => onStatus('published')), if (event.status != 'cancelled') HBButton.soft(label: 'event_manage.cancel_event'.tr(), icon: Icons.event_busy_outlined, onPressed: () => onStatus('cancelled')), HBButton.ghost(label: 'event_manage.view_event'.tr(), onPressed: () => context.go(AppRoutes.eventDetailPath(event.id)))]),
  ]);
}

class EventManageOverview extends StatelessWidget {
  final HuntingEvent event;
  final EventOrganizerSummary summary;
  final VoidCallback onPublish;
  const EventManageOverview({super.key, required this.event, required this.summary, required this.onPublish});
  bool get _isToday { final now = DateTime.now(); final date = event.startsAt.toLocal(); return now.year == date.year && now.month == date.month && now.day == date.day; }
  @override
  Widget build(BuildContext context) => Column(children: [
    HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('event_manage.summary_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), EventKpiGrid(items: [('going', summary.confirmed), ('interested', summary.interested), ('waitlist', summary.waitlist), ('checked_in', summary.checkedIn)]), if (summary.capacity != null) ...[const SizedBox(height: AppSpacing.md), Text('event_manage.capacity_progress'.tr(namedArgs: {'capacity': '${summary.capacity}'})), const SizedBox(height: AppSpacing.sm), LinearProgressIndicator(value: summary.capacity == 0 ? 0 : (summary.confirmed / summary.capacity!).clamp(0, 1), minHeight: 8, borderRadius: BorderRadius.circular(AppRadius.pill), backgroundColor: LightModeColors.lightBackgroundSoft)] ])),
    if (summary.isPaidEvent) ...[const SizedBox(height: AppSpacing.md), HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('event_manage.cash_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), EventKpiGrid(items: [('paid', summary.paid), ('pending_payment', summary.pendingPayment), ('revenue', summary.paid * event.priceMinor)], money: true, event: event)]))],
    if (event.status == 'draft' || _isToday) ...[const SizedBox(height: AppSpacing.md), HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('event_manage.next_steps'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), if (event.status == 'draft') HBButton.primary(label: 'event_manage.publish'.tr(), icon: Icons.publish_outlined, onPressed: onPublish), if (_isToday) HBButton.primary(label: 'event_manage.open_scanner'.tr(), icon: Icons.qr_code_scanner_rounded, onPressed: () => context.push(AppRoutes.eventScanPath(event.id)))]))],
  ]);
}

class EventKpiGrid extends StatelessWidget {
  final List<(String, int)> items;
  final bool money;
  final HuntingEvent? event;
  const EventKpiGrid({super.key, required this.items, this.money = false, this.event});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) { final width = constraints.maxWidth >= 640 ? (constraints.maxWidth - AppSpacing.md) / 2 : constraints.maxWidth; return Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [for (final item in items) SizedBox(width: width, child: HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('event_manage.kpi.${item.$1}'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), const SizedBox(height: AppSpacing.xs), Text(money && item.$1 == 'revenue' ? MoneyFormatter.format(amountMinor: item.$2, currencyCode: event!.currencyCode, locale: context.locale) : '${item.$2}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.headlineSmall)]))) ]); });
}

enum EventParticipantMode { participants, waitlist }

class EventParticipantsPanel extends ConsumerStatefulWidget {
  final HuntingEvent event;
  final EventParticipantMode mode;
  final VoidCallback onChanged;
  const EventParticipantsPanel({super.key, required this.event, required this.mode, required this.onChanged});
  @override
  ConsumerState<EventParticipantsPanel> createState() => _EventParticipantsPanelState();
}

class _EventParticipantsPanelState extends ConsumerState<EventParticipantsPanel> {
  final _search = TextEditingController();
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  Future<bool> _confirm(String title, String message, String action) async => await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text(title.tr()), content: Text(message.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: action.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
  Future<void> _action(EventParticipant participant, String action) async {
    try {
      final repository = ref.read(eventRepositoryProvider);
      if (action == 'profile') { context.push(AppRoutes.publicProfilePath(participant.profile.username)); return; }
      if (!await _confirm('event_manage.confirm_title', 'event_manage.confirm_message', 'common.continue')) return;
      if (action == 'checkin') await repository.checkinParticipant(participant.id);
      if (action == 'undo') await repository.undoCheckin(participant.id);
      if (action == 'paid') await repository.markEventPaid(participant.id, paid: true);
      if (action == 'unpaid') await repository.markEventPaid(participant.id, paid: false);
      widget.onChanged();
    } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }
  Future<void> _export(List<EventParticipant> participants) async {
    String csv(String value) => '"${value.replaceAll('"', '""')}"';
    final rows = [
      ['name', 'username', 'status', 'payment'].map(csv).join(','),
      for (final participant in participants) [participant.profile.displayName, participant.profile.username, participant.status, participant.paymentStatus].map(csv).join(','),
    ];
    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('event_manage.export_copied'.tr())));
  }
  @override
  Widget build(BuildContext context) => ref.watch(eventParticipantsProvider(widget.event.id)).when(
    loading: () => const HBCard(child: HBListSkeleton(count: 5)),
    error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'event_manage.list_error_title'.tr(), message: 'event_manage.load_error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(eventParticipantsProvider(widget.event.id))))),
    data: (all) {
      final query = _search.text.trim().toLowerCase();
      final source = widget.mode == EventParticipantMode.waitlist
          ? (all.where((item) => item.status == 'waitlist').toList()..sort((a, b) => (a.waitlistedAt ?? a.createdAt).compareTo(b.waitlistedAt ?? b.createdAt)))
          : all.where((item) => const {'going', 'checked_in'}.contains(item.status)).toList();
      final participants = source.where((item) => query.isEmpty || item.profile.displayName.toLowerCase().contains(query) || item.profile.username.toLowerCase().contains(query)).toList();
      final interested = widget.mode == EventParticipantMode.participants ? all.where((item) => item.status == 'interested').toList() : const <EventParticipant>[];
      return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(widget.mode == EventParticipantMode.waitlist ? 'event_manage.waitlist_title'.tr() : 'event_manage.participants_title'.tr(), style: context.textStyles.titleLarge)), if (widget.mode == EventParticipantMode.participants) HBButton.secondary(label: 'event_manage.export'.tr(), icon: Icons.copy_all_outlined, onPressed: () => _export(source))]),
        const SizedBox(height: AppSpacing.md), HBInput(controller: _search, hint: 'event_manage.search'.tr(), prefixIcon: const Icon(Icons.search_rounded), onChanged: (_) => setState(() {})),
        if (widget.mode == EventParticipantMode.waitlist) Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: Text('event_manage.waitlist_help'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))),
        const SizedBox(height: AppSpacing.md),
        if (participants.isEmpty) HBEmptyState(icon: widget.mode == EventParticipantMode.waitlist ? Icons.hourglass_empty_rounded : Icons.people_outline_rounded, title: widget.mode == EventParticipantMode.waitlist ? 'event_manage.waitlist_empty'.tr() : 'event_manage.participants_empty'.tr(), message: 'event_manage.list_empty_message'.tr()) else for (var index = 0; index < participants.length; index++) EventParticipantRow(participant: participants[index], event: widget.event, waitlistPosition: widget.mode == EventParticipantMode.waitlist ? index + 1 : null, onAction: (action) => _action(participants[index], action)),
        if (interested.isNotEmpty) ...[const Divider(height: AppSpacing.xl), Text('event_manage.interested_title'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), for (final item in interested) ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: item.profile.displayName, imageUrl: item.profile.avatarUrl, size: 38), title: Text(item.profile.displayName), subtitle: Text('@${item.profile.username}'), onTap: () => context.push(AppRoutes.publicProfilePath(item.profile.username)))],
      ]));
    },
  );
}

class EventParticipantRow extends StatelessWidget {
  final EventParticipant participant;
  final HuntingEvent event;
  final int? waitlistPosition;
  final ValueChanged<String> onAction;
  const EventParticipantRow({super.key, required this.participant, required this.event, this.waitlistPosition, required this.onAction});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Row(children: [
    if (waitlistPosition != null) ...[SizedBox(width: 30, child: Text('$waitlistPosition.', style: context.textStyles.titleMedium)), const SizedBox(width: AppSpacing.xs)],
    HBAvatar(name: participant.profile.displayName, imageUrl: participant.profile.avatarUrl, size: 42), const SizedBox(width: AppSpacing.sm),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(participant.profile.displayName, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis), Text('@${participant.profile.username} · ${waitlistPosition == null ? 'event_manage.registered'.tr(namedArgs: {'time': relativeTime(context, participant.createdAt)}) : 'event_manage.waiting_since'.tr(namedArgs: {'time': relativeTime(context, participant.waitlistedAt ?? participant.createdAt)})}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant), overflow: TextOverflow.ellipsis), const SizedBox(height: AppSpacing.xs), Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [if (waitlistPosition == null) HBStatusChip(kind: participant.status == 'checked_in' ? HBStatusKind.approved : HBStatusKind.info, label: participant.status == 'checked_in' ? 'event_manage.checked_at'.tr(namedArgs: {'time': DateFormat.Hm().format(participant.checkedInAt!.toLocal())}) : 'event_manage.going'.tr()), if (event.priceMinor > 0) PaymentStatusChip(status: participant.paymentStatus)])])),
    PopupMenuButton<String>(onSelected: onAction, itemBuilder: (_) => [if (participant.status == 'going') PopupMenuItem(value: 'checkin', child: Text('event_manage.manual_checkin'.tr())), if (participant.status == 'checked_in') PopupMenuItem(value: 'undo', child: Text('event_manage.undo_checkin'.tr())), if (event.priceMinor > 0 && participant.paymentStatus == 'pending') PopupMenuItem(value: 'paid', child: Text('event_manage.mark_paid'.tr())), if (event.priceMinor > 0 && participant.paymentStatus == 'paid' && participant.paymentMethod != 'stripe') PopupMenuItem(value: 'unpaid', child: Text('event_manage.cancel_payment'.tr())), PopupMenuItem(value: 'profile', child: Text('event_manage.open_profile'.tr()))]),
  ]));
}

class PaymentStatusChip extends StatelessWidget {
  final String status;
  const PaymentStatusChip({super.key, required this.status});
  @override
  Widget build(BuildContext context) => HBStatusChip(kind: status == 'paid' ? HBStatusKind.approved : status == 'refunded' ? HBStatusKind.rejected : HBStatusKind.pending, label: 'event_manage.payment_status.$status'.tr());
}

class EventCheckinPanel extends StatelessWidget {
  final HuntingEvent event;
  final EventOrganizerSummary summary;
  const EventCheckinPanel({super.key, required this.event, required this.summary});
  @override
  Widget build(BuildContext context) => HBCard(child: Column(children: [Icon(Icons.qr_code_scanner_rounded, size: 56, color: LightModeColors.lightPrimary), const SizedBox(height: AppSpacing.md), Text('event_manage.checkin_count'.tr(namedArgs: {'checked': '${summary.checkedIn}', 'total': '${summary.confirmed}'}), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), HBButton.primary(label: 'event_manage.scan_qr'.tr(), icon: Icons.qr_code_scanner_rounded, onPressed: () => context.push(AppRoutes.eventScanPath(event.id))), const SizedBox(height: AppSpacing.sm), HBButton.ghost(label: 'event_manage.manual_list'.tr(), onPressed: () => context.go(AppRoutes.eventManagePath(event.id)))]));
}

class EventPaymentsPanel extends ConsumerStatefulWidget {
  final HuntingEvent event;
  final EventOrganizerSummary summary;
  final VoidCallback onChanged;
  const EventPaymentsPanel({super.key, required this.event, required this.summary, required this.onChanged});
  @override
  ConsumerState<EventPaymentsPanel> createState() => _EventPaymentsPanelState();
}

class _EventPaymentsPanelState extends ConsumerState<EventPaymentsPanel> {
  String _filter = 'pending';
  Future<void> _paid(EventParticipant participant) async {
    final price = MoneyFormatter.format(amountMinor: widget.event.priceMinor, currencyCode: widget.event.currencyCode, locale: context.locale);
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('event_manage.mark_paid_title'.tr()), content: Text('event_manage.mark_paid_message'.tr(namedArgs: {'price': price})), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'event_manage.mark_paid'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
    if (!confirmed) return;
    try { await ref.read(eventRepositoryProvider).markEventPaid(participant.id, paid: true); widget.onChanged(); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }
  @override
  Widget build(BuildContext context) => ref.watch(eventParticipantsProvider(widget.event.id)).when(loading: () => const HBCard(child: HBListSkeleton()), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'event_manage.list_error_title'.tr(), message: 'event_manage.load_error_message'.tr())), data: (all) {
    final status = _filter == 'refunds' ? 'refunded' : _filter;
    final items = all.where((item) => item.paymentStatus == status).toList()..sort((a, b) => a.paymentStatus == 'pending' ? -1 : 1);
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('event_manage.payments_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.xs), Text('event_manage.revenue_total'.tr(namedArgs: {'total': MoneyFormatter.format(amountMinor: widget.summary.paid * widget.event.priceMinor, currencyCode: widget.event.currencyCode, locale: context.locale)})), Text('p34b.ticket_payout'.tr(namedArgs: {'amount': MoneyFormatter.format(amountMinor: widget.event.priceMinor, currencyCode: widget.event.currencyCode, locale: context.locale)})), const SizedBox(height: AppSpacing.md), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final value in const ['pending', 'paid', 'refunds']) HBChip(label: 'event_manage.payment_filters.$value'.tr(), selected: _filter == value, onTap: () => setState(() => _filter = value))]), const SizedBox(height: AppSpacing.md), if (items.isEmpty) HBEmptyState(icon: Icons.payments_outlined, title: 'event_manage.payments_empty'.tr(), message: 'event_manage.list_empty_message'.tr()) else for (final item in items) ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: item.profile.displayName, imageUrl: item.profile.avatarUrl, size: 40), title: Text(item.profile.displayName), subtitle: Text('@${item.profile.username} · ${item.paymentMethod == 'stripe' ? 'p34b.method.stripe'.tr() : 'p34b.method.cash'.tr()}'), trailing: item.paymentStatus == 'pending' ? HBButton.soft(label: 'event_manage.mark_paid'.tr(), onPressed: () => _paid(item), size: HBButtonSize.sm) : PaymentStatusChip(status: item.paymentStatus))]));
  });
}