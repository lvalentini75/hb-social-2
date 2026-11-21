import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/features/feed/presentation/widgets/post_media_grid.dart';
import 'package:hb_social/features/forums/domain/forum_attachment.dart';
import 'package:url_launcher/url_launcher.dart';

class ForumAttachmentPicker extends StatelessWidget {
  final List<PreparedUpload> files;
  final VoidCallback? onPick;
  final ValueChanged<int> onRemove;

  const ForumAttachmentPicker({super.key, required this.files, required this.onPick, required this.onRemove});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    HBButton.soft(label: 'forum_advanced.attachments.add'.tr(), icon: Icons.attach_file_rounded, onPressed: onPick, size: HBButtonSize.sm),
    if (files.isNotEmpty) ...[
      const SizedBox(height: AppSpacing.sm),
      SizedBox(height: 104, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: files.length, separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm), itemBuilder: (context, index) => ForumPendingAttachmentTile(file: files[index], onRemove: () => onRemove(index)))),
    ],
  ]);
}

class ForumPendingAttachmentTile extends StatelessWidget {
  final PreparedUpload file;
  final VoidCallback onRemove;
  const ForumPendingAttachmentTile({super.key, required this.file, required this.onRemove});

  String get _size => '${(file.bytes.length / 1024 / 1024).toStringAsFixed(1)} MB';
  String get _duration { final value = file.durationMs; if (value == null) return ''; final duration = Duration(milliseconds: value); return '${duration.inMinutes}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}'; }

  @override
  Widget build(BuildContext context) => SizedBox(width: 150, child: Stack(children: [
    Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: file.mediaKind == 'document'
      ? ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.picture_as_pdf_rounded, color: LightModeColors.lightError), Text(file.fileName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis), Text(_size, style: context.textStyles.labelSmall)])))
      : Image.memory(file.mediaKind == 'video' ? file.poster?.bytes ?? Uint8List(0) : file.bytes, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.videocam_outlined))))),
    if (_duration.isNotEmpty) Positioned(right: 6, bottom: 6, child: Text(_duration, style: context.textStyles.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700))),
    Positioned(right: 2, top: 2, child: IconButton.filled(onPressed: onRemove, icon: const Icon(Icons.close_rounded, size: 16), visualDensity: VisualDensity.compact)),
  ]));
}

class ForumAttachmentsView extends ConsumerWidget {
  final List<ForumAttachment> attachments;
  const ForumAttachmentsView({super.key, required this.attachments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    final client = ref.watch(supabaseClientProvider);
    final media = attachments.where((item) => item.kind != 'document').map((item) => item.toPostMedia(client)).toList();
    final documents = attachments.where((item) => item.kind == 'document').toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (media.isNotEmpty) PostMediaGrid(media: media),
      for (final document in documents) ...[const SizedBox(height: AppSpacing.sm), ForumDocumentCard(attachment: document)],
    ]);
  }
}

class ForumDocumentCard extends ConsumerWidget {
  final ForumAttachment attachment;
  const ForumDocumentCard({super.key, required this.attachment});

  @override
  Widget build(BuildContext context, WidgetRef ref) => HBCard(padding: const EdgeInsets.all(AppSpacing.sm), child: Row(children: [
    const Icon(Icons.picture_as_pdf_rounded, color: LightModeColors.lightError),
    const SizedBox(width: AppSpacing.sm),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(attachment.fileName, maxLines: 1, overflow: TextOverflow.ellipsis), Text('${(attachment.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB', style: context.textStyles.labelSmall)])),
    HBButton.ghost(label: 'forum_advanced.attachments.open'.tr(), onPressed: () async {
      final url = attachment.toPostMedia(ref.read(supabaseClientProvider)).url;
      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication) && context.mounted) throw const AppException('forum_advanced.errors.attachment_open');
    }, size: HBButtonSize.sm),
  ]));
}