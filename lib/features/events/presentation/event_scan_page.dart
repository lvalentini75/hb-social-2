import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/events/domain/hunting_event.dart';
import 'package:hb_social/features/events/providers/event_providers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum EventScanOutcome { success, alreadyUsed, invalid, unpaid, notGoing, error }

class EventScanPage extends ConsumerStatefulWidget {
  final String eventId;
  const EventScanPage({super.key, required this.eventId});
  @override
  ConsumerState<EventScanPage> createState() => _EventScanPageState();
}

class _EventScanPageState extends ConsumerState<EventScanPage> {
  final _manual = TextEditingController();
  final _scanner = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  final Map<String, DateTime> _recentCodes = {};
  final List<EventCheckinResult> _recentCheckins = [];
  EventScanOutcome? _outcome;
  EventCheckinResult? _result;
  EventParticipant? _matchedParticipant;
  bool _working = false;
  Timer? _resetTimer;

  @override
  void dispose() { _resetTimer?.cancel(); _manual.dispose(); _scanner.dispose(); super.dispose(); }

  void _refresh() {
    ref.invalidate(eventOrganizerSummaryProvider(widget.eventId));
    ref.invalidate(eventParticipantsProvider(widget.eventId));
  }

  Future<void> _scan(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty || _working) return;
    final lastRead = _recentCodes[code];
    if (lastRead != null && DateTime.now().difference(lastRead) < const Duration(seconds: 5)) return;
    _recentCodes[code] = DateTime.now();
    setState(() { _working = true; _outcome = null; _result = null; _matchedParticipant = null; });
    try {
      final result = await ref.read(eventRepositoryProvider).checkinTicket(code);
      if (!mounted) return;
      if (result.eventId != widget.eventId) { _show(EventScanOutcome.invalid); return; }
      _recentCheckins.insert(0, result);
      if (_recentCheckins.length > 5) _recentCheckins.removeLast();
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.mediumImpact();
      _refresh();
      _show(EventScanOutcome.success, result: result);
    } on AppException catch (error) {
      if (!mounted) return;
      final participants = ref.read(eventParticipantsProvider(widget.eventId)).value ?? const <EventParticipant>[];
      final normalized = code.replaceFirst('hb:ticket:', '');
      _matchedParticipant = participants.where((item) => item.ticketCode == normalized || item.ticketCode == code).firstOrNull;
      _show(switch (error.messageKey) {
        'event_manage.errors.ticket_already_used' => EventScanOutcome.alreadyUsed,
        'event_manage.errors.ticket_not_found' => EventScanOutcome.invalid,
        'event_manage.errors.ticket_unpaid' => EventScanOutcome.unpaid,
        'event_manage.errors.ticket_not_going' => EventScanOutcome.notGoing,
        _ => EventScanOutcome.error,
      });
    } finally { if (mounted) setState(() => _working = false); }
  }

  void _show(EventScanOutcome outcome, {EventCheckinResult? result}) {
    _resetTimer?.cancel();
    setState(() { _outcome = outcome; _result = result; });
    _resetTimer = Timer(const Duration(milliseconds: 2500), () { if (mounted) setState(() { _outcome = null; _result = null; _matchedParticipant = null; }); });
  }

  Future<void> _payAndCheckin() async {
    final participant = _matchedParticipant;
    if (participant == null) return;
    _resetTimer?.cancel();
    setState(() => _working = true);
    try {
      await ref.read(eventRepositoryProvider).markEventPaid(participant.id, paid: true);
      await ref.read(eventRepositoryProvider).checkinParticipant(participant.id);
      _refresh();
      final refreshed = EventCheckinResult(participantId: participant.id, userId: participant.profile.id, username: participant.profile.username, displayName: participant.profile.displayName, avatarUrl: participant.profile.avatarUrl, status: 'checked_in', checkedInAt: DateTime.now().toUtc(), eventId: widget.eventId, eventTitle: '');
      _recentCheckins.insert(0, refreshed);
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.mediumImpact();
      _show(EventScanOutcome.success, result: refreshed);
    } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
    finally { if (mounted) setState(() => _working = false); }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(eventOrganizerSummaryProvider(widget.eventId));
    if (summary.isLoading) return const PageColumns(center: HBListSkeleton(count: 4));
    if (summary.value == null) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.admin_panel_settings_outlined, title: 'event_manage.denied_title'.tr(), message: 'event_manage.denied_message'.tr(), action: HBButton.primary(label: 'event_manage.back_to_event'.tr(), onPressed: () => context.go(AppRoutes.eventDetailPath(widget.eventId))))));
    final value = summary.value!;
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), sliver: SliverList.list(children: [
      Row(children: [HBButton.icon(icon: Icons.arrow_back_rounded, onPressed: () => context.pop()), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('event_manage.scanner_title'.tr(), style: context.textStyles.titleLarge)), Text('event_manage.checkin_count'.tr(namedArgs: {'checked': '${value.checkedIn}', 'total': '${value.confirmed}'}), style: context.textStyles.titleMedium)]),
      const SizedBox(height: AppSpacing.md),
      EventScannerCamera(scanner: _scanner, enabled: _outcome == null, onCode: (code) { if (code.startsWith('hb:ticket:')) _scan(code); }),
      const SizedBox(height: AppSpacing.md),
      if (_outcome != null) EventScanResultPanel(outcome: _outcome!, result: _result, participant: _matchedParticipant, working: _working, onPayAndCheckin: _payAndCheckin),
      if (_outcome != null) const SizedBox(height: AppSpacing.md),
      HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('event_manage.manual_code_title'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), HBInput(controller: _manual, hint: 'event_manage.manual_code_hint'.tr(), onSubmitted: _scan), const SizedBox(height: AppSpacing.sm), HBButton.secondary(label: 'event_manage.verify'.tr(), onPressed: _working ? null : () => _scan(_manual.text))])),
      const SizedBox(height: AppSpacing.md),
      HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('event_manage.latest_checkins'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), if (_recentCheckins.isEmpty) Text('event_manage.latest_empty'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)) else for (final item in _recentCheckins) ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: item.displayName, imageUrl: item.avatarUrl, size: 38), title: Text(item.displayName), trailing: Text(DateFormat.Hm().format(item.checkedInAt.toLocal()))), const Divider(), HBButton.ghost(label: 'event_manage.manual_list'.tr(), onPressed: () => context.go(AppRoutes.eventManagePath(widget.eventId)))])),
      if (MediaQuery.sizeOf(context).width < 900) const SizedBox(height: 88),
    ]))]));
  }
}

class EventScannerCamera extends StatelessWidget {
  final MobileScannerController scanner;
  final bool enabled;
  final ValueChanged<String> onCode;
  const EventScannerCamera({super.key, required this.scanner, required this.enabled, required this.onCode});
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(AppRadius.lg), child: AspectRatio(aspectRatio: MediaQuery.sizeOf(context).width < 700 ? 1 : 16 / 9, child: Stack(fit: StackFit.expand, children: [
    MobileScanner(controller: scanner, onDetect: (capture) { if (!enabled) return; for (final barcode in capture.barcodes) { final code = barcode.rawValue; if (code != null) { onCode(code); break; } } }, errorBuilder: (context, _) => ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.no_photography_outlined, size: 48), const SizedBox(height: AppSpacing.sm), Text('event_manage.camera_unavailable'.tr())])))),
    Center(child: IgnorePointer(child: Container(width: 230, height: 230, decoration: BoxDecoration(border: Border.all(color: LightModeColors.lightOnPrimary, width: 3), borderRadius: BorderRadius.circular(AppRadius.lg))))),
  ])));
}

class EventScanResultPanel extends StatelessWidget {
  final EventScanOutcome outcome;
  final EventCheckinResult? result;
  final EventParticipant? participant;
  final bool working;
  final VoidCallback onPayAndCheckin;
  const EventScanResultPanel({super.key, required this.outcome, this.result, this.participant, required this.working, required this.onPayAndCheckin});
  @override
  Widget build(BuildContext context) {
    final color = outcome == EventScanOutcome.success ? LightModeColors.lightSuccess : outcome == EventScanOutcome.alreadyUsed || outcome == EventScanOutcome.unpaid ? LightModeColors.lightWarning : LightModeColors.lightError;
    final key = switch (outcome) { EventScanOutcome.success => 'welcome', EventScanOutcome.alreadyUsed => 'already_used', EventScanOutcome.invalid => 'invalid', EventScanOutcome.unpaid => 'unpaid', EventScanOutcome.notGoing => 'not_going', EventScanOutcome.error => 'error' };
    final checkedAt = participant?.checkedInAt;
    final text = key == 'welcome' ? 'event_manage.scan_result.welcome'.tr(namedArgs: {'name': result?.displayName ?? ''}) : key == 'already_used' && checkedAt != null ? 'event_manage.scan_result.already_used_at'.tr(namedArgs: {'time': DateFormat.Hm().format(checkedAt.toLocal())}) : 'event_manage.scan_result.$key'.tr();
    return Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.lg)), child: Column(children: [if (result != null || participant != null) HBAvatar(name: result?.displayName ?? participant!.profile.displayName, imageUrl: result?.avatarUrl ?? participant?.profile.avatarUrl, size: 64), if (result != null || participant != null) const SizedBox(height: AppSpacing.sm), Text(text, textAlign: TextAlign.center, style: context.textStyles.titleLarge?.withColor(color)), if (outcome == EventScanOutcome.success && result != null) Text(DateFormat.Hm().format(result!.checkedInAt.toLocal())), if (outcome == EventScanOutcome.unpaid && participant != null) ...[const SizedBox(height: AppSpacing.md), HBButton.primary(label: 'event_manage.pay_and_checkin'.tr(), onPressed: working ? null : onPayAndCheckin)]]));
  }
}