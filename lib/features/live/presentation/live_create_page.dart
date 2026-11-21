import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_source_picker.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/live/providers/live_providers.dart';

class LiveCreatePage extends ConsumerStatefulWidget {
  const LiveCreatePage({super.key});
  @override ConsumerState<LiveCreatePage> createState() => _LiveCreatePageState();
}

class _LiveCreatePageState extends ConsumerState<LiveCreatePage> {
  final title = TextEditingController();
  final description = TextEditingController();
  String visibility = 'public';
  bool chat = true;
  DateTime? scheduledAt;
  String? coverPath;
  bool saving = false;

  @override void dispose() { title.dispose(); description.dispose(); super.dispose(); }
  Future<void> _pickCover() async {
    final userId = ref.read(authSessionProvider).value?.user.id;
    if (userId == null) return;
    final service = ref.read(mediaUploadServiceProvider);
    final upload = await MediaSourcePicker.singleImage(context, service, maxDimension: 1600);
    if (upload == null) return;
    final result = await service.uploadToBucket(bucket: 'story-media', userId: userId, upload: upload, isPublic: true);
    setState(() => coverPath = result.path);
  }
  Future<void> _chooseDate() async {
    final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: scheduledAt ?? DateTime.now());
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(scheduledAt ?? DateTime.now().add(const Duration(hours: 1))));
    if (time != null) setState(() => scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
  Future<void> _save(bool start) async {
    setState(() => saving = true);
    try {
      final id = await ref.read(liveRepositoryProvider).create(title: title.text, description: description.text, visibility: visibility, scheduledAt: start ? null : scheduledAt, coverPath: coverPath, chatEnabled: chat);
      if (start) await ref.read(liveRepositoryProvider).start(id);
      ref.invalidate(myLiveStreamsProvider); ref.invalidate(liveActiveProvider);
      if (mounted) context.go(AppRoutes.livePath(id));
    } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override Widget build(BuildContext context) => CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.all(AppSpacing.lg), sliver: SliverList.list(children: [
    Row(children: [HBButton.icon(icon: Icons.arrow_back_rounded, onPressed: () => context.pop()), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('live.create_title'.tr(), style: AppText.heading))]),
    const SizedBox(height: AppSpacing.lg), HBCard(child: Column(children: [
      HBFormField(label: 'live.fields.title'.tr(), child: HBInput(controller: title, maxLength: 120)),
      HBFormField(label: 'live.fields.description'.tr(), child: HBInput(controller: description, maxLines: 4)),
      HBFormField(label: 'live.fields.visibility'.tr(), child: HBSelect(value: visibility, items: [HBSelectItem(value: 'public', label: 'live.visibility.public'.tr()), HBSelectItem(value: 'followers', label: 'live.visibility.followers'.tr())], onChanged: (value) => setState(() => visibility = value ?? 'public'))),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('live.fields.chat'.tr()), value: chat, onChanged: (value) => setState(() => chat = value)),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBButton.secondary(label: coverPath == null ? 'live.cover_add'.tr() : 'live.cover_change'.tr(), icon: Icons.image_outlined, onPressed: _pickCover), HBButton.secondary(label: scheduledAt == null ? 'live.schedule_add'.tr() : DateFormat.yMd().add_Hm().format(scheduledAt!), icon: Icons.schedule_rounded, onPressed: _chooseDate)]),
      const SizedBox(height: AppSpacing.lg), Wrap(spacing: AppSpacing.sm, children: [HBButton.primary(label: 'live.start_now'.tr(), icon: Icons.videocam_rounded, isLoading: saving, onPressed: saving ? null : () => _save(true)), HBButton.secondary(label: 'live.save_later'.tr(), isLoading: saving, onPressed: saving ? null : () => _save(false))]),
    ])),
  ]))]);
}