import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/features/calls/providers/calls_providers.dart';
import 'package:hb_social/features/live/presentation/live_widgets.dart';

class CallPage extends ConsumerWidget {
  final String callId;
  final bool incoming;
  const CallPage({super.key, required this.callId, this.incoming = false});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(callProvider(callId));
    return ListenableBuilder(listenable: controller, builder: (context, _) {
      if (controller.loading) return const ColoredBox(color: LightModeColors.night, child: Center(child: CircularProgressIndicator(color: Colors.white)));
      if (controller.call == null) return ColoredBox(color: LightModeColors.night, child: Center(child: Text('calls.unavailable'.tr(), style: const TextStyle(color: Colors.white))));
      return CallRoomView(controller: controller, incoming: incoming);
    });
  }
}

class CallRoomView extends StatefulWidget {
  final CallController controller;
  final bool incoming;
  const CallRoomView({super.key, required this.controller, required this.incoming});
  @override State<CallRoomView> createState() => _CallRoomViewState();
}

class _CallRoomViewState extends State<CallRoomView> {
  Timer? timer;
  Duration elapsed = Duration.zero;
  @override void initState() { super.initState(); timer = Timer.periodic(const Duration(seconds: 1), (_) { final answered = widget.controller.call?.answeredAt; if (answered != null && mounted) setState(() => elapsed = DateTime.now().toUtc().difference(answered)); }); }
  @override void dispose() { timer?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final call = widget.controller.call!;
    final ringingIncoming = call.status == 'ringing' && call.direction == 'incoming';
    final terminal = call.terminal;
    return ColoredBox(color: LightModeColors.night, child: SafeArea(child: Stack(children: [
      if (call.kind == 'video' && call.status == 'accepted') Positioned.fill(child: LiveVideoStage(room: widget.controller.room)) else Positioned.fill(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [HBAvatar(name: call.peer.displayName, imageUrl: call.peer.avatarUrl, size: 120), const SizedBox(height: 20), Text(call.peer.displayName, style: AppText.heading.copyWith(color: Colors.white)), const SizedBox(height: 8), Text(_status(call.status, ringingIncoming), style: AppText.body.copyWith(color: Colors.white70))]))),
      if (call.kind == 'video' && call.status == 'accepted') Positioned(right: 16, top: 72, width: 120, height: 170, child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.inner), child: LiveVideoStage(room: widget.controller.room, local: true))),
      Positioned(left: 16, right: 16, bottom: 28, child: ringingIncoming ? Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [CallAction(icon: Icons.call_end, color: LightModeColors.danger, label: 'calls.decline'.tr(), onTap: () async { await widget.controller.decline(); if (context.mounted) context.go(AppRoutes.calls); }), CallAction(icon: Icons.call, color: LightModeColors.success, label: 'calls.answer'.tr(), onTap: widget.controller.answer)]) : Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [CallAction(icon: widget.controller.microphone ? Icons.mic : Icons.mic_off, label: 'calls.microphone'.tr(), onTap: widget.controller.toggleMicrophone), if (call.kind == 'video') CallAction(icon: widget.controller.camera ? Icons.videocam : Icons.videocam_off, label: 'calls.camera'.tr(), onTap: widget.controller.toggleCamera), CallAction(icon: Icons.volume_up, label: 'calls.speaker'.tr(), onTap: widget.controller.toggleSpeaker), CallAction(icon: Icons.call_end, color: LightModeColors.danger, label: 'calls.end'.tr(), onTap: () async { if (call.status == 'ringing') { await widget.controller.cancel(); } else if (!terminal) { await widget.controller.end(); } if (context.mounted) context.go(AppRoutes.calls); })])),
      if (call.status == 'accepted') Positioned(top: 24, left: 0, right: 0, child: Text(_duration(elapsed), textAlign: TextAlign.center, style: AppText.label.copyWith(color: Colors.white))),
    ])));
  }
  String _status(String status, bool incoming) { if (incoming) return (widget.controller.call!.kind == 'video' ? 'calls.incoming_video' : 'calls.incoming_audio').tr(); return 'calls.status.$status'.tr(); }
  String _duration(Duration value) => '${value.inMinutes.toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
}

class CallAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const CallAction({super.key, required this.icon, required this.label, this.color, required this.onTap});
  @override Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [HBButton.icon(icon: icon, backgroundColor: color ?? Colors.white, foregroundColor: color == null ? LightModeColors.text : Colors.white, size: HBButtonSize.lg, onPressed: onTap), const SizedBox(height: 6), Text(label, style: AppText.small.copyWith(color: Colors.white))]);
}