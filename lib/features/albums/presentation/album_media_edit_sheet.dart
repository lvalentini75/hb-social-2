import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/albums/domain/album_media.dart';
import 'package:intl/intl.dart';

class AlbumMediaEditResult {
  final String? caption;
  final DateTime? takenAt;
  const AlbumMediaEditResult({this.caption, this.takenAt});
}

Future<AlbumMediaEditResult?> showAlbumMediaEditSheet(BuildContext context, AlbumMedia media) async {
  final wide = MediaQuery.sizeOf(context).width >= 700;
  if (wide) return showDialog<AlbumMediaEditResult>(context: context, builder: (_) => Dialog(child: SizedBox(width: 500, child: AlbumMediaEditSheet(media: media))));
  return showModalBottomSheet<AlbumMediaEditResult>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: (_) => AlbumMediaEditSheet(media: media));
}

/// Edits the optional caption and capture timestamp of one album item.
class AlbumMediaEditSheet extends StatefulWidget {
  final AlbumMedia media;
  const AlbumMediaEditSheet({super.key, required this.media});
  @override
  State<AlbumMediaEditSheet> createState() => _AlbumMediaEditSheetState();
}

class _AlbumMediaEditSheetState extends State<AlbumMediaEditSheet> {
  late final TextEditingController _caption = TextEditingController(text: widget.media.caption);
  late DateTime? _takenAt = widget.media.takenAt?.toLocal();

  @override
  void dispose() { _caption.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _takenAt ?? now;
    final date = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(1900), lastDate: now);
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time != null && mounted) setState(() => _takenAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('albums_p23b.media_edit_title'.tr(), style: context.textStyles.titleLarge),
      const SizedBox(height: AppSpacing.md),
      HBInput(label: 'albums_p23b.caption'.tr(), controller: _caption, maxLength: 500, maxLines: 4, onChanged: (_) => setState(() {})),
      Align(alignment: Alignment.centerRight, child: Text('${_caption.text.length}/500', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))),
      const SizedBox(height: AppSpacing.md),
      Text('albums_p23b.taken_at'.tr(), style: context.textStyles.labelLarge),
      const SizedBox(height: AppSpacing.xs),
      Row(children: [Expanded(child: HBButton.secondary(label: _takenAt == null ? 'albums_p23b.add_date'.tr() : DateFormat.yMMMd(context.locale.toString()).add_Hm().format(_takenAt!), icon: Icons.calendar_today_outlined, onPressed: _pickDate)), if (_takenAt != null) ...[const SizedBox(width: AppSpacing.sm), HBButton.ghost(label: 'albums_p23b.remove_date'.tr(), onPressed: () => setState(() => _takenAt = null))]]),
      const SizedBox(height: AppSpacing.lg),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop()), const SizedBox(width: AppSpacing.sm), HBButton.primary(label: 'common.save'.tr(), onPressed: () => context.pop(AlbumMediaEditResult(caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(), takenAt: _takenAt)))]),
    ]),
  );
}