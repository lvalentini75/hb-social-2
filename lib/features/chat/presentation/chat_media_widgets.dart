import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/features/chat/domain/conversation.dart';
import 'package:hb_social/features/chat/providers/chat_audio_provider.dart';
import 'package:hb_social/features/chat/providers/chat_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatImageBubble extends ConsumerWidget {
  final ChatMessage message;
  const ChatImageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratio = (message.mediaWidth ?? 1) / max(1, message.mediaHeight ?? 1);
    final width = min(MediaQuery.sizeOf(context).width * .7, 320.0);
    final image = message.localBytes != null
        ? Image.memory(message.localBytes!, fit: BoxFit.cover)
        : FutureBuilder<String>(future: ref.read(chatRepositoryProvider).signedMediaUrl(message.mediaPath ?? ''), builder: (context, snapshot) => snapshot.hasData ? Image.network(snapshot.data!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined)) : const HBSkeleton(height: 220));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(onTap: message.localState == LocalMessageState.sent ? () => showChatImageViewer(context, ref, message) : null, child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SizedBox(width: width, child: AspectRatio(aspectRatio: ratio.clamp(.55, 2.0), child: image)))),
      if (message.localState == LocalMessageState.sending) Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 0), child: HBUploadProgress(progress: message.uploadProgress)),
      if (message.body.isNotEmpty) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(message.body, style: context.textStyles.bodyMedium)),
    ]);
  }
}

class ChatVoiceBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isMine;
  const ChatVoiceBubble({super.key, required this.message, required this.isMine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(chatAudioProvider);
    final active = audio.messageId == message.id;
    final duration = Duration(milliseconds: message.durationMs ?? 0);
    final position = active ? audio.position : Duration.zero;
    final listened = ref.watch(listenedVoiceIdsProvider).contains(message.id);
    final waveform = _waveform(message);
    return SizedBox(width: min(MediaQuery.sizeOf(context).width * .68, 300), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Stack(clipBehavior: Clip.none, children: [HBButton.icon(icon: active && audio.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, onPressed: () { ref.read(listenedVoiceIdsProvider.notifier).add(message.id); ref.read(chatAudioProvider.notifier).toggle(message); }), if (!isMine && !listened) const Positioned(right: -2, top: -2, child: CircleAvatar(radius: 4, backgroundColor: LightModeColors.lightPrimary))]),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(children: [SizedBox(height: 32, child: CustomPaint(painter: VoiceWaveformPainter(values: waveform, progress: duration.inMilliseconds == 0 ? 0 : position.inMilliseconds / duration.inMilliseconds))), Slider(value: duration.inMilliseconds == 0 ? 0 : position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(), max: max(1, duration.inMilliseconds).toDouble(), onChanged: (value) => ref.read(chatAudioProvider.notifier).seek(Duration(milliseconds: value.round())))])),
        InkWell(onTap: () => ref.read(chatAudioProvider.notifier).cycleSpeed(), child: Padding(padding: const EdgeInsets.all(AppSpacing.xs), child: Text('${active ? audio.speed : 1}x', style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w700)))),
      ]),
      Row(children: [Text(_duration(active ? position : duration), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary)), if (active && audio.errorKey != null) ...[const SizedBox(width: AppSpacing.sm), Expanded(child: Text(audio.errorKey!.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightError))), HBButton.icon(icon: Icons.download_outlined, onPressed: () async { if (message.mediaPath != null) { final url = await ref.read(chatRepositoryProvider).signedMediaUrl(message.mediaPath!); await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); } })]]),
      if (message.localState == LocalMessageState.sending) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: HBUploadProgress(progress: message.uploadProgress)),
    ]));
  }

  List<double> _waveform(ChatMessage item) {
    final values = item.meta['waveform'];
    if (values is List && values.isNotEmpty) return values.map((value) => (value as num).toDouble()).toList();
    final seed = item.id.codeUnits.fold<int>(0, (sum, value) => sum + value);
    return List.generate(32, (index) => .2 + (((seed + index * 17) % 70) / 100));
  }

  String _duration(Duration value) => '${value.inMinutes.toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
}

class VoiceWaveformPainter extends CustomPainter {
  final List<double> values;
  final double progress;
  const VoiceWaveformPainter({required this.values, required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.width / max(1, values.length);
    for (var index = 0; index < values.length; index++) {
      final height = max(3.0, size.height * values[index].clamp(.08, 1));
      final paint = Paint()..color = index / values.length <= progress ? LightModeColors.lightPrimary : LightModeColors.lightTextTertiary;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(index * gap + gap / 2, size.height / 2), width: 2.5, height: height), const Radius.circular(2)), paint);
    }
  }
  @override
  bool shouldRepaint(VoiceWaveformPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.values != values;
}

Future<void> showChatImageViewer(BuildContext context, WidgetRef ref, ChatMessage selected) async {
  final state = ref.read(messagesProvider(selected.conversationId)).value;
  final images = state?.items.where((item) => item.kind == 'image' && item.status != 'deleted' && item.mediaPath != null).toList() ?? [selected];
  final initial = max(0, images.indexWhere((item) => item.id == selected.id));
  await showDialog<void>(context: context, useSafeArea: false, builder: (_) => ChatImageViewer(images: images, initialIndex: initial));
}

class ChatImageViewer extends ConsumerStatefulWidget {
  final List<ChatMessage> images;
  final int initialIndex;
  const ChatImageViewer({super.key, required this.images, required this.initialIndex});
  @override
  ConsumerState<ChatImageViewer> createState() => _ChatImageViewerState();
}

class _ChatImageViewerState extends ConsumerState<ChatImageViewer> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Material(color: Colors.black, child: SafeArea(child: Stack(children: [
    PageView.builder(controller: _controller, itemCount: widget.images.length, onPageChanged: (value) => setState(() => _index = value), itemBuilder: (context, index) { final item = widget.images[index]; return FutureBuilder<String>(future: ref.read(chatRepositoryProvider).signedMediaUrl(item.mediaPath!), builder: (context, snapshot) => snapshot.hasData ? InteractiveViewer(minScale: 1, maxScale: 5, child: Center(child: Image.network(snapshot.data!))) : const Center(child: CircularProgressIndicator())); }),
    Positioned(top: AppSpacing.md, left: AppSpacing.md, child: HBButton.icon(icon: Icons.close_rounded, onPressed: context.pop)),
    Positioned(top: AppSpacing.md, right: AppSpacing.md, child: HBButton.icon(icon: Icons.download_rounded, onPressed: () async { final url = await ref.read(chatRepositoryProvider).signedMediaUrl(widget.images[_index].mediaPath!); await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); })),
  ])));
}