import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/camera_capture.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/widgets/media_source_sheet.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_image_cropper.dart';
import 'package:hb_social/features/chat/data/chat_voice_service.dart';
import 'package:hb_social/features/chat/domain/conversation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';

typedef SendChatMedia = Future<void> Function(PreparedChatMedia media, String kind, String body, String clientId);

class ChatMediaComposerControls extends ConsumerStatefulWidget {
  final bool textEmpty;
  final VoidCallback onTextSend;
  final SendChatMedia onMediaSend;
  const ChatMediaComposerControls({super.key, required this.textEmpty, required this.onTextSend, required this.onMediaSend});
  @override
  ConsumerState<ChatMediaComposerControls> createState() => _ChatMediaComposerControlsState();
}

class _ChatMediaComposerControlsState extends ConsumerState<ChatMediaComposerControls> {
  final ChatVoiceRecorder _recorder = ChatVoiceRecorder();
  Timer? _timer;
  RecordedVoice? _draft;
  bool _recording = false;
  int _elapsedMs = 0;
  double _amplitude = 0;

  @override
  void dispose() { _timer?.cancel(); _recorder.dispose(); super.dispose(); }

  Future<void> _pickPhotos() async {
    try {
      final source = await showMediaSourceSheet(context);
      if (source == null || !mounted) return;
      final service = ref.read(mediaUploadServiceProvider);
      final List<PreparedUpload> uploads;
      if (source == MediaSourceOption.library) {
        uploads = await service.pickChatImages();
      } else {
        final captured = await captureFromCamera(context);
        if (captured == null) return;
        uploads = [service.prepareCapturedImage(captured, maxDimension: 1600, quality: 82)];
      }
      if (uploads.isEmpty || !mounted) return;
      final result = await showModalBottomSheet<ChatPhotoDraft>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => ChatPhotoPreviewSheet(uploads: uploads));
      if (result == null) return;
      for (final upload in result.uploads) {
        await widget.onMediaSend(PreparedChatMedia(bytes: upload.bytes, extension: upload.extension, mime: upload.contentType, width: upload.width, height: upload.height), 'image', result.caption, const Uuid().v4());
      }
    } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  Future<void> _start() async {
    if (_recording) return;
    if (!await _recorder.hasPermission()) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('chat_b.microphone_denied'.tr()))); return; }
    try {
      await _recorder.start((value) { if (mounted) setState(() => _amplitude = value); });
      setState(() { _recording = true; _elapsedMs = 0; _draft = null; });
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) { if (!mounted) return; setState(() => _elapsedMs += 100); if (_elapsedMs >= 180000) _stop(); });
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('chat_b.microphone_denied'.tr()))); }
  }

  Future<void> _stop() async {
    if (!_recording) return;
    _timer?.cancel();
    final voice = await _recorder.stop();
    if (!mounted) return;
    setState(() { _recording = false; _draft = voice != null && voice.durationMs >= 300 ? voice : null; });
    if (voice != null && voice.durationMs < 300) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('chat_b.voice_too_short'.tr())));
  }

  Future<void> _cancel() async { _timer?.cancel(); await _recorder.cancel(); if (mounted) setState(() { _recording = false; _draft = null; }); }
  Future<void> _sendVoice() async { final voice = _draft; if (voice == null) return; setState(() => _draft = null); await widget.onMediaSend(PreparedChatMedia(bytes: voice.bytes, extension: voice.extension, mime: voice.mime, durationMs: voice.durationMs, waveform: voice.waveform), 'voice', '', const Uuid().v4()); }

  @override
  Widget build(BuildContext context) {
    if (_recording) return Expanded(child: Row(children: [const Icon(Icons.circle, color: LightModeColors.lightError, size: 12), const SizedBox(width: AppSpacing.sm), Text(_time(_elapsedMs)), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [LinearProgressIndicator(value: _amplitude, minHeight: 5, color: LightModeColors.lightError, backgroundColor: LightModeColors.lightBackgroundSoft), if (!kIsWeb) Text('chat_media_actions.slide_cancel'.tr(), style: context.textStyles.labelSmall)])), const SizedBox(width: AppSpacing.sm), if (kIsWeb) HBButton.icon(icon: Icons.close_rounded, onPressed: _cancel), if (kIsWeb) const SizedBox(width: AppSpacing.xs), GestureDetector(onHorizontalDragEnd: kIsWeb ? null : (details) { if ((details.primaryVelocity ?? 0) < -150) _cancel(); }, onTap: kIsWeb ? _stop : null, onLongPressEnd: kIsWeb ? null : (_) => _stop(), child: const Padding(padding: EdgeInsets.all(AppSpacing.sm), child: Icon(Icons.mic_rounded, color: LightModeColors.lightError)))]));
    if (_draft != null) return Expanded(child: VoiceDraftPreview(voice: _draft!, onRemove: () => setState(() => _draft = null), onSend: _sendVoice));
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Tooltip(message: 'chat_b.photo_action'.tr(), child: HBButton.icon(icon: Icons.photo_outlined, onPressed: _pickPhotos)),
      const SizedBox(width: AppSpacing.xs),
      if (!widget.textEmpty) HBButton.icon(icon: Icons.send_rounded, backgroundColor: LightModeColors.lightPrimary, foregroundColor: Colors.white, onPressed: widget.onTextSend)
      else GestureDetector(onTap: kIsWeb ? _start : null, onLongPressStart: kIsWeb ? null : (_) => _start(), onLongPressEnd: kIsWeb ? null : (_) => _stop(), child: const Padding(padding: EdgeInsets.all(AppSpacing.sm), child: Icon(Icons.mic_rounded, color: LightModeColors.lightPrimary))),
    ]);
  }

  String _time(int ms) => '${(ms ~/ 60000).toString().padLeft(2, '0')}:${((ms ~/ 1000) % 60).toString().padLeft(2, '0')}';
}

class ChatPhotoDraft {
  final List<PreparedUpload> uploads;
  final String caption;
  const ChatPhotoDraft(this.uploads, this.caption);
}

class ChatPhotoPreviewSheet extends StatefulWidget {
  final List<PreparedUpload> uploads;
  const ChatPhotoPreviewSheet({super.key, required this.uploads});
  @override
  State<ChatPhotoPreviewSheet> createState() => _ChatPhotoPreviewSheetState();
}

class _ChatPhotoPreviewSheetState extends State<ChatPhotoPreviewSheet> {
  late final List<PreparedUpload> _uploads = [...widget.uploads];
  final _caption = TextEditingController();
  @override
  void dispose() { _caption.dispose(); super.dispose(); }
  Future<void> _crop(int index) async {
    final source = _uploads[index];
    final width = source.width ?? 1600;
    final height = source.height ?? 1600;
    final cropped = await HBImageCropper.show(context, bytes: source.bytes, aspectRatio: width / height, outputWidth: width, outputHeight: height);
    if (cropped != null && mounted) setState(() => _uploads[index] = PreparedUpload(bytes: cropped, extension: 'jpg', contentType: 'image/jpeg', width: width, height: height, mediaKind: 'image'));
  }
  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('chat_b.photo_preview'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md),
    SizedBox(height: 160, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _uploads.length, separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm), itemBuilder: (context, index) => Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: Image.memory(_uploads[index].bytes, width: 130, height: 160, fit: BoxFit.cover)), Positioned(top: 4, right: 4, child: HBButton.icon(icon: Icons.close_rounded, onPressed: () => setState(() => _uploads.removeAt(index)))), Positioned(top: 4, left: 4, child: Tooltip(message: 'media_crop.action'.tr(), child: HBButton.icon(icon: Icons.crop_rounded, onPressed: () => _crop(index))))]))),
    const SizedBox(height: AppSpacing.md), HBInput(controller: _caption, label: 'chat_b.caption'.tr(), hint: 'chat_b.caption_hint'.tr(), maxLength: 4000), const SizedBox(height: AppSpacing.md),
    SizedBox(width: double.infinity, child: HBButton.primary(label: 'chat_b.send_photos'.tr(namedArgs: {'n': '${_uploads.length}'}), onPressed: _uploads.isEmpty ? null : () => context.pop(ChatPhotoDraft(_uploads, _caption.text)))),
  ]));
}

class VoiceDraftPreview extends StatefulWidget {
  final RecordedVoice voice;
  final VoidCallback onRemove;
  final VoidCallback onSend;
  const VoiceDraftPreview({super.key, required this.voice, required this.onRemove, required this.onSend});
  @override
  State<VoiceDraftPreview> createState() => _VoiceDraftPreviewState();
}

class _VoiceDraftPreviewState extends State<VoiceDraftPreview> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  @override
  void dispose() { _player.dispose(); super.dispose(); }
  Future<void> _toggle() async {
    if (_playing) { await _player.pause(); setState(() => _playing = false); return; }
    if (_player.audioSource == null) await _player.setAudioSource(AudioSource.uri(Uri.dataFromBytes(widget.voice.bytes, mimeType: widget.voice.mime)));
    setState(() => _playing = true); await _player.play(); if (mounted) setState(() => _playing = false);
  }
  @override
  Widget build(BuildContext context) => Row(children: [HBButton.icon(icon: _playing ? Icons.pause_rounded : Icons.play_arrow_rounded, onPressed: _toggle), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('chat_b.voice_preview'.tr(namedArgs: {'time': '${(widget.voice.durationMs / 1000).toStringAsFixed(1)}'}))), HBButton.icon(icon: Icons.close_rounded, onPressed: widget.onRemove), const SizedBox(width: AppSpacing.xs), HBButton.icon(icon: Icons.send_rounded, backgroundColor: LightModeColors.lightPrimary, foregroundColor: Colors.white, onPressed: widget.onSend)]);
}