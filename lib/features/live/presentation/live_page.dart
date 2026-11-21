import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/live/domain/live_models.dart';
import 'package:hb_social/features/live/presentation/live_widgets.dart';
import 'package:hb_social/features/live/providers/live_providers.dart';

class LivePage extends ConsumerWidget {
  final String streamId;
  const LivePage({super.key, required this.streamId});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(liveRoomProvider(streamId));
    return ListenableBuilder(listenable: controller, builder: (context, _) {
      if (controller.loading) return const ColoredBox(color: LightModeColors.night, child: Center(child: CircularProgressIndicator(color: Colors.white)));
      if (controller.error != null || controller.stream == null) return ColoredBox(color: LightModeColors.night, child: HBEmptyState(icon: Icons.videocam_off_outlined, title: 'live.unavailable'.tr(), message: 'live.unavailable_message'.tr(), action: HBButton.secondary(label: 'common.back'.tr(), onPressed: () => context.pop())));
      final stream = controller.stream!;
      if (stream.status == 'scheduled') return LiveWaitingView(stream: stream);
      return LiveRoomView(controller: controller);
    });
  }
}

class LiveWaitingView extends StatelessWidget {
  final LiveStream stream;
  const LiveWaitingView({super.key, required this.stream});
  @override Widget build(BuildContext context) => ColoredBox(color: LightModeColors.night, child: SafeArea(child: Stack(children: [Positioned(left: 16, top: 12, child: HBButton.icon(icon: Icons.close, onPressed: () => context.pop())), Center(child: Column(mainAxisSize: MainAxisSize.min, children: [HBAvatar(name: stream.host.displayName, imageUrl: stream.host.avatarUrl, size: 96), const SizedBox(height: 16), Text(stream.title, textAlign: TextAlign.center, style: AppText.heading.copyWith(color: Colors.white)), const SizedBox(height: 8), Text('live.waiting'.tr(namedArgs: {'time': stream.scheduledAt == null ? '' : DateFormat.yMd().add_Hm().format(stream.scheduledAt!.toLocal())}), style: AppText.body.copyWith(color: Colors.white70))]))])));
}

class LiveRoomView extends StatefulWidget {
  final LiveRoomController controller;
  const LiveRoomView({super.key, required this.controller});
  @override State<LiveRoomView> createState() => _LiveRoomViewState();
}

class _LiveRoomViewState extends State<LiveRoomView> {
  final message = TextEditingController();
  Timer? timer;
  Duration elapsed = Duration.zero;
  @override void initState() { super.initState(); _tick(); timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick()); }
  void _tick() { final start = widget.controller.stream?.startedAt; if (start != null && mounted) setState(() => elapsed = DateTime.now().toUtc().difference(start)); }
  @override void dispose() { timer?.cancel(); message.dispose(); super.dispose(); }
  Future<void> _send() async { final value = message.text; message.clear(); try { await widget.controller.send(value); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
  Future<void> _end() async { final result = await widget.controller.repository.end(widget.controller.streamId); if (!mounted) return; await showModalBottomSheet(context: context, builder: (_) => Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('live.summary_title'.tr(), style: AppText.title), Text('live.summary'.tr(namedArgs: {'duration': '${result['duration_s'] ?? 0}', 'peak': '${result['peak_viewers'] ?? 0}', 'total': '${result['total_viewers'] ?? 0}', 'messages': '${result['message_count'] ?? 0}'}))]))); if (mounted) context.go(AppRoutes.home); }
  @override Widget build(BuildContext context) {
    final stream = widget.controller.stream!;
    final ended = stream.status == 'ended';
    return ColoredBox(color: LightModeColors.night, child: SafeArea(child: Stack(children: [
      Positioned.fill(child: LiveVideoStage(room: widget.controller.room, local: stream.isHost)),
      Positioned(left: 12, right: 12, top: 8, child: Row(children: [HBButton.icon(icon: Icons.close, onPressed: () => context.pop()), const SizedBox(width: 8), DecoratedBox(decoration: BoxDecoration(color: LightModeColors.danger, borderRadius: BorderRadius.circular(AppRadius.pill)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Text('LIVE · ${_duration(elapsed)}', style: AppText.small.copyWith(color: Colors.white, fontWeight: FontWeight.w700)))), const Spacer(), Text('live.viewers'.tr(namedArgs: {'count': '${stream.viewerCount}'}), style: AppText.label.copyWith(color: Colors.white))])),
      Positioned(left: 12, right: 12, bottom: 84, child: LiveChatOverlay(messages: widget.controller.messages, stream: stream, controller: widget.controller)),
      if (stream.chatEnabled && !stream.muted) Positioned(left: 12, right: 12, bottom: 16, child: Row(children: [Expanded(child: HBInput(controller: message, hint: 'live.chat_hint'.tr(), onSubmitted: (_) => _send())), const SizedBox(width: 8), HBButton.icon(icon: Icons.send_rounded, onPressed: _send)])),
      if (stream.isHost) Positioned(right: 12, top: 58, child: Column(children: [HBButton.icon(icon: Icons.mic_rounded, onPressed: () => widget.controller.liveKit.toggleMicrophone(false)), const SizedBox(height: 8), HBButton.icon(icon: Icons.cameraswitch_rounded, onPressed: widget.controller.liveKit.switchCamera), const SizedBox(height: 8), HBButton.icon(icon: Icons.people_outline, onPressed: () => showModalBottomSheet(context: context, builder: (_) => LiveViewersSheet(controller: widget.controller))), const SizedBox(height: 8), HBButton.icon(icon: Icons.stop_circle_outlined, backgroundColor: LightModeColors.danger, foregroundColor: Colors.white, onPressed: _end)])),
      if (ended) Positioned.fill(child: ColoredBox(color: const Color.fromRGBO(15, 34, 25, .9), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('live.ended'.tr(), style: AppText.heading.copyWith(color: Colors.white)), Text('live.public_summary'.tr(namedArgs: {'peak': '${stream.peakViewers}'}), style: AppText.body.copyWith(color: Colors.white70)), const SizedBox(height: 16), HBButton.primary(label: 'live.back_home'.tr(), onPressed: () => context.go(AppRoutes.home))])))),
    ])));
  }
  String _duration(Duration value) => '${value.inMinutes.toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
}

class LiveChatOverlay extends StatelessWidget {
  final List<LiveMessage> messages;
  final LiveStream stream;
  final LiveRoomController controller;
  const LiveChatOverlay({super.key, required this.messages, required this.stream, required this.controller});
  @override Widget build(BuildContext context) => SizedBox(height: 190, child: ListView(children: [if (stream.pinnedMessage != null) ListTile(tileColor: LightModeColors.bosco, title: Text(stream.pinnedMessage!.body, style: const TextStyle(color: Colors.white)), leading: const Icon(Icons.push_pin, color: Colors.white)), for (final item in messages.where((item) => item.status != 'hidden').take(60)) ListTile(dense: true, leading: HBAvatar(name: item.displayName, imageUrl: item.avatarUrl, size: 28), title: Text(item.displayName, style: AppText.small.copyWith(color: item.isHost ? LightModeColors.boscoSoft : Colors.white, fontWeight: FontWeight.w700)), subtitle: Text(item.body, style: AppText.label.copyWith(color: Colors.white)), trailing: stream.isHost ? PopupMenuButton<String>(iconColor: Colors.white, onSelected: (value) { if (value == 'pin') controller.repository.pinMessage(item.id, true); if (value == 'hide') controller.repository.hideMessage(item.id, true); }, itemBuilder: (_) => [PopupMenuItem(value: 'pin', child: Text('live.pin'.tr())), PopupMenuItem(value: 'hide', child: Text('live.hide'.tr()))]) : null)]));
}

class LiveViewersSheet extends StatelessWidget {
  final LiveRoomController controller;
  const LiveViewersSheet({super.key, required this.controller});
  @override Widget build(BuildContext context) => SafeArea(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('live.viewers_title'.tr(), style: AppText.title), for (final row in controller.viewers) ListTile(title: Text((row['user'] as Map?)?['display_name']?.toString() ?? ''), trailing: PopupMenuButton<String>(onSelected: (value) => controller.moderate(row['user_id'].toString(), value), itemBuilder: (_) => [PopupMenuItem(value: 'mute', child: Text('live.mute'.tr())), PopupMenuItem(value: 'unmute', child: Text('live.unmute'.tr())), PopupMenuItem(value: 'remove', child: Text('live.remove'.tr()))]))])));
}