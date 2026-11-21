import 'dart:async';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_source_picker.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_emoji_picker.dart';
import 'package:hb_social/core/widgets/hb_image_cropper.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/features/composer/data/composer_repository.dart';
import 'package:hb_social/features/composer/providers/composer_providers.dart';
import 'package:hb_social/features/home/providers/feed_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/hunting/domain/hunting_unit.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/groups/providers/group_providers.dart';
import 'package:hb_social/features/pages/providers/page_providers.dart';
import 'package:hb_social/features/map/providers/map_providers.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/features/dogs/domain/dog.dart';
import 'package:hb_social/features/dogs/presentation/dog_tag_selector.dart';
import 'package:hb_social/features/dogs/providers/dog_providers.dart';

class ComposerSheet extends ConsumerStatefulWidget {
  final String? groupId;
  final String? groupName;
  final String? groupVisibility;
  final String? pageId;
  final String? pageName;
  final String? pageAvatarUrl;
  final String? initialText;
  final String? initialLocationName;
  final double? initialLatitude, initialLongitude;
  final PreparedUpload? initialMedia;
  final bool initialCheckin;
  final String? locationPrivacyNoteKey;

  const ComposerSheet({super.key, this.groupId, this.groupName, this.groupVisibility, this.pageId, this.pageName, this.pageAvatarUrl, this.initialText, this.initialLocationName, this.initialLatitude, this.initialLongitude, this.initialMedia, this.initialCheckin = false, this.locationPrivacyNoteKey});

  static String publishedMessage(BuildContext context) => 'post_composer.published'.tr();

  @override
  ConsumerState<ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends ConsumerState<ComposerSheet> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialText);
  final _pollQuestionController = TextEditingController();
  final _locationController = TextEditingController();
  final List<TextEditingController> _pollOptions = [TextEditingController(), TextEditingController()];
  final List<PreparedUpload> _media = [];
  String _visibility = 'public';
  ComposerKind _kind = ComposerKind.standard;
  bool _allowMultiple = false;
  int? _pollDurationDays = 1;
  double? _latitude;
  double? _longitude;
  HuntingUnit? _huntingUnit;
  bool _unitFromPosition = false;
  bool _locating = false;
  bool _sending = false;
  String? _errorKey;
  Map<String, String> _errorArgs = const {};
  int _activeUpload = -1;
  List<double> _uploadProgress = const [];
  bool _publishing = false;
  bool _isSensitive = false;
  final Set<String> _dogIds = {};
  DateTime? _scheduledAt;

  @override void initState() { super.initState(); if (widget.initialCheckin) _kind = ComposerKind.checkin; _locationController.text = widget.initialLocationName ?? ''; _latitude = widget.initialLatitude; _longitude = widget.initialLongitude; if (widget.initialMedia != null) _media.add(widget.initialMedia!); }

  bool get _canPublish {
    if (_sending) return false;
    if (_kind == ComposerKind.poll) {
      final options = _pollOptions.map((item) => item.text.trim()).where((item) => item.isNotEmpty).toList();
      return options.length >= 2 && options.toSet().length == options.length && (_pollQuestionController.text.trim().isNotEmpty || _controller.text.trim().isNotEmpty);
    }
    if (_kind == ComposerKind.checkin) return _locationController.text.trim().isNotEmpty;
    return _controller.text.trim().isNotEmpty || _media.isNotEmpty;
  }
  bool get _hasVideo => _media.any((item) => item.contentType.startsWith('video/'));

  @override
  void dispose() {
    _controller.dispose();
    _pollQuestionController.dispose();
    _locationController.dispose();
    for (final controller in _pollOptions) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_hasVideo || _kind == ComposerKind.poll) return _showError('post_composer.media_exclusive');
    try {
      final maxImages = _kind == ComposerKind.checkin ? 4 : 10;
      final selected = await MediaSourcePicker.postImages(context, ref.read(mediaUploadServiceProvider), remaining: maxImages - _media.length);
      if (mounted) setState(() => _media.addAll(selected));
    } on AppException catch (error) {
      _showError(error.messageKey);
    } catch (error) {
      final failure = AppException.from(error);
      if (mounted) setState(() { _errorKey = failure.messageKey; _errorArgs = failure.namedArgs; });
    }
  }

  Future<void> _pickVideo() async {
    if (_media.isNotEmpty || _kind != ComposerKind.standard) return _showError('post_composer.media_exclusive');
    try {
      final selected = await MediaSourcePicker.video(context, ref.read(mediaUploadServiceProvider));
      if (selected != null && mounted) setState(() => _media.add(selected));
    } on AppException catch (error) {
      _showError(error.messageKey);
    } catch (error) {
      final failure = AppException.from(error);
      if (mounted) setState(() { _errorKey = failure.messageKey; _errorArgs = failure.namedArgs; });
    }
  }

  Future<void> _cropMedia(int index) async {
    final current = _media[index];
    if (current.contentType.startsWith('video/')) return;
    final width = current.width ?? 1600;
    final height = current.height ?? 1600;
    final cropped = await HBImageCropper.show(context, bytes: current.bytes, aspectRatio: width / height, outputWidth: width, outputHeight: height);
    if (cropped != null && mounted) setState(() => _media[index] = ref.read(mediaUploadServiceProvider).prepareJpeg(cropped));
  }

  void _showError(String key) => setState(() { _errorKey = key; _errorArgs = const {}; });

  void _togglePoll() {
    if (_media.isNotEmpty || _kind == ComposerKind.checkin) return;
    setState(() {
      _kind = _kind == ComposerKind.poll ? ComposerKind.standard : ComposerKind.poll;
      _errorKey = null;
    });
  }

  void _toggleCheckin() {
    if (_hasVideo || _kind == ComposerKind.poll || _media.length > 4) return;
    setState(() {
      _kind = _kind == ComposerKind.checkin ? ComposerKind.standard : ComposerKind.checkin;
      _errorKey = null;
    });
  }

  Future<void> _useLocation() async {
    setState(() { _locating = true; _errorKey = null; });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw const AppException('post_composer.location_denied');
      final position = await Geolocator.getCurrentPosition();
      final unit = await ref.read(mapRepositoryProvider).unitAt(position.latitude, position.longitude);
      if (mounted) setState(() { _latitude = position.latitude; _longitude = position.longitude; _huntingUnit = unit == null ? null : HuntingUnit(id: unit.id, name: unit.name, unitType: unit.unitType, code: unit.code); _unitFromPosition = unit != null; _locating = false; });
    } on AppException catch (error) {
      if (mounted) setState(() { _locating = false; _errorKey = error.messageKey; });
    } catch (_) {
      if (mounted) setState(() { _locating = false; _errorKey = 'post_composer.location_error'; });
    }
  }

  Future<void> _publish() async {
    if (!_canPublish) return;
    setState(() { _sending = true; _publishing = false; _uploadProgress = List.filled(_media.length, 0); _errorKey = null; _errorArgs = const {}; });
    final progressVisibleSince = DateTime.now();
    final uploads = <UploadedMedia>[];
    final posterUploads = <UploadedMedia?>[];
    final mediaService = ref.read(mediaUploadServiceProvider);
    try {
      final repository = ref.read(composerRepositoryProvider);
      final userId = repository.requireUserId();
      for (var index = 0; index < _media.length; index++) {
        setState(() => _activeUpload = index);
        final source = _media[index];
        final posterBytes = source.poster?.bytes;
        final totalBytes = source.bytes.length + (posterBytes?.length ?? 0);
        try {
          UploadedMedia? posterUpload;
          if (posterBytes != null) {
            final posterProgress = UploadProgress();
            final posterSubscription = posterProgress.stream.listen((value) { if (mounted) setState(() => _uploadProgress[index] = value * posterBytes.length / totalBytes); });
            try {
              posterUpload = await mediaService.uploadPoster(bucket: 'post-media', bytes: posterBytes, progress: posterProgress);
            } finally {
              await posterSubscription.cancel();
              await posterProgress.close();
            }
          }
          posterUploads.add(posterUpload);
          final progress = UploadProgress();
          final subscription = progress.stream.listen((value) { if (mounted) setState(() => _uploadProgress[index] = ((posterBytes?.length ?? 0) + value * source.bytes.length) / totalBytes); });
          try {
            uploads.add(await mediaService.uploadToBucket(bucket: 'post-media', userId: userId, upload: source, isPublic: true, progress: progress));
          } finally {
            await subscription.cancel();
            await progress.close();
          }
          if (mounted) setState(() => _uploadProgress[index] = 1);
        } catch (_) {
          if (posterUploads.length > index && posterUploads[index] != null) await mediaService.delete('post-media', posterUploads[index]!.path).catchError((_) {});
          rethrow;
        }
      }
      final remaining = const Duration(milliseconds: 800) - DateTime.now().difference(progressVisibleSince);
      if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      if (mounted) setState(() { _activeUpload = _media.length; _publishing = true; });
      final payload = <Map<String, dynamic>>[];
      for (var index = 0; index < uploads.length; index++) {
        final source = _media[index];
        payload.add({'path': uploads[index].path, 'kind': source.contentType.startsWith('video/') ? 'video' : 'image', 'width': source.width, 'height': source.height, 'duration_ms': source.durationMs, if (posterUploads[index] != null) 'thumbnail_path': posterUploads[index]!.path});
      }
      final kind = _kind == ComposerKind.poll ? 'poll' : (_kind == ComposerKind.checkin ? 'checkin' : (_hasVideo ? 'video' : (_media.isNotEmpty ? 'photo' : 'text')));
      final poll = _kind == ComposerKind.poll ? {
        'question': _pollQuestionController.text.trim().isEmpty ? null : _pollQuestionController.text.trim(),
        'allow_multiple': _allowMultiple,
        'ends_at': _pollDurationDays == null ? null : DateTime.now().toUtc().add(Duration(days: _pollDurationDays!)).toIso8601String(),
        'options': _pollOptions.map((item) => item.text.trim()).where((item) => item.isNotEmpty).toList(),
      } : null;
      final id = _scheduledAt == null
          ? await repository.createPost(kind: kind, content: _controller.text.trim().isEmpty ? null : _controller.text.trim(), visibility: widget.pageId == null ? _visibility : 'public', media: payload, isSensitive: _isSensitive, poll: poll, locationName: _kind == ComposerKind.checkin ? _locationController.text.trim() : null, latitude: _latitude, longitude: _longitude, huntingUnitId: _huntingUnit?.id, groupId: widget.groupId, pageId: widget.pageId)
          : await repository.createScheduledPost(scheduledAt: _scheduledAt!, kind: kind, content: _controller.text.trim().isEmpty ? null : _controller.text.trim(), visibility: widget.pageId == null ? _visibility : 'public', media: payload, isSensitive: _isSensitive, poll: poll, locationName: _kind == ComposerKind.checkin ? _locationController.text.trim() : null, latitude: _latitude, longitude: _longitude, huntingUnitId: _huntingUnit?.id, groupId: widget.groupId, pageId: widget.pageId);
      if (widget.pageId == null && widget.groupId == null) await ref.read(dogsRepositoryProvider).tagPostDogs(id, _dogIds.toList());
      if (_scheduledAt != null) {
        ref.invalidate(currentProfileProvider);
        if (mounted) context.pop(_scheduledAt);
        return;
      }
      final post = await ref.read(feedRepositoryProvider).getById(id);
      if (post == null) throw const AppException('errors.not_found');
      if (widget.pageId != null) {
        ref.read(pagePostsProvider(widget.pageId!).notifier).insertFirst(post);
        ref.read(feedPostsProvider.notifier).insertFirst(post);
        ref.read(followingFeedProvider.notifier).insertFirst(post);
      } else if (widget.groupId == null) {
        insertPublishedPost(ref, post, hasHomeRegion: ref.read(currentProfileProvider).value?.homeRegionId != null);
      } else {
        ref.read(groupPostsProvider(widget.groupId!).notifier).insertFirst(post);
        if (widget.groupVisibility == 'public') {
          ref.read(feedPostsProvider.notifier).insertFirst(post);
          ref.read(followingFeedProvider.notifier).insertFirst(post);
        }
      }
      ref.invalidate(currentProfileProvider);
      if (mounted) context.pop(true);
    } on AppException catch (error) {
      for (final upload in uploads) {
        try {
          await mediaService.delete('post-media', upload.path);
        } catch (_) {}
      }
      for (final upload in posterUploads.whereType<UploadedMedia>()) {
        try { await mediaService.delete('post-media', upload.path); } catch (_) {}
      }
      if (mounted) setState(() { _sending = false; _publishing = false; _activeUpload = -1; _errorKey = error.messageKey; _errorArgs = error.namedArgs; });
    } catch (error) {
      for (final upload in uploads) {
        try {
          await mediaService.delete('post-media', upload.path);
        } catch (_) {}
      }
      for (final upload in posterUploads.whereType<UploadedMedia>()) {
        try { await mediaService.delete('post-media', upload.path); } catch (_) {}
      }
      final failure = AppException.from(error);
      if (mounted) setState(() { _sending = false; _publishing = false; _activeUpload = -1; _errorKey = failure.messageKey; _errorArgs = failure.namedArgs; });
    }
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final minimum = now.add(const Duration(minutes: 5));
    final maximum = now.add(const Duration(days: 30));
    final date = await showDatePicker(context: context, initialDate: _scheduledAt ?? minimum, firstDate: DateTime(minimum.year, minimum.month, minimum.day), lastDate: maximum);
    if (date == null || !mounted) return;
    final initial = _scheduledAt ?? minimum;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay(hour: initial.hour, minute: ((initial.minute + 4) ~/ 5 * 5) % 60));
    if (time == null || !mounted) return;
    var selected = DateTime(date.year, date.month, date.day, time.hour, (time.minute ~/ 5) * 5);
    if (selected.isBefore(minimum)) selected = DateTime(minimum.year, minimum.month, minimum.day, minimum.hour, ((minimum.minute + 4) ~/ 5 * 5) % 60);
    if (selected.isAfter(maximum)) { _showError('composer.schedule.invalid'); return; }
    setState(() => _scheduledAt = selected);
  }

  Future<void> _selectDogs() async {
    final dogs = (ref.read(myDogsProvider).value ?? const <Dog>[]).where((dog) => dog.status == DogStatus.active).toList();
    if (dogs.isEmpty) { final router = GoRouter.of(context); context.pop(false); router.push(AppRoutes.dogsNew); return; }
    final value = await showModalBottomSheet<Set<String>>(context: context, useSafeArea: true, showDragHandle: true, builder: (_) => DogTagSelector(dogs: dogs, selectedIds: _dogIds));
    if (value != null && mounted) setState(() { _dogIds.clear(); _dogIds.addAll(value); });
  }

  Future<void> _insertEmoji() async {
    final emoji = await HBEmojiPicker.show(context);
    if (emoji == null || !mounted || _controller.text.length + emoji.length > 5000) return;
    final selection = _controller.selection;
    final start = selection.isValid ? selection.start : _controller.text.length;
    final end = selection.isValid ? selection.end : _controller.text.length;
    final updated = _controller.text.replaceRange(start, end, emoji);
    _controller.value = TextEditingValue(text: updated, selection: TextSelection.collapsed(offset: start + emoji.length));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: !_sending,
      child: Material(
        color: LightModeColors.lightSurface,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: keyboardInset),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.md, AppSpacing.sm), child: Row(children: [
              HBButton.icon(icon: Icons.close_rounded, onPressed: _sending ? null : () => context.pop(false)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('post_composer.title'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              const SizedBox(width: AppSpacing.sm),
               HBButton.primary(label: _scheduledAt == null ? 'post_composer.publish'.tr() : 'composer.schedule.for'.tr(namedArgs: {'date': DateFormat.yMd(context.locale.toString()).add_Hm().format(_scheduledAt!)}), onPressed: _canPublish ? _publish : null, isLoading: _sending, size: HBButtonSize.sm),
               if (!_sending) PopupMenuButton<String>(tooltip: 'composer.schedule.menu'.tr(), icon: const Icon(Icons.keyboard_arrow_down_rounded), onSelected: (value) { if (value == 'schedule') _pickSchedule(); if (value == 'clear') setState(() => _scheduledAt = null); }, itemBuilder: (_) => [PopupMenuItem(value: 'schedule', child: Text('composer.schedule.action'.tr())), if (_scheduledAt != null) PopupMenuItem(value: 'clear', child: Text('composer.schedule.clear'.tr()))]),
            ])),
            const Divider(height: 1),
            Flexible(child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(AppSpacing.md), children: [
              Row(children: [
                HBAvatar(name: widget.pageName ?? profile?.displayName ?? '', imageUrl: widget.pageId == null ? profile?.avatarUrl : widget.pageAvatarUrl, size: 40),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.pageName ?? profile?.displayName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                   const SizedBox(height: AppSpacing.xs),
                   if (widget.groupId != null) Align(alignment: Alignment.centerLeft, child: HBChip(label: 'group_form.composer_context'.tr(namedArgs: {'name': widget.groupName ?? '', 'privacy': 'groups.visibility.${widget.groupVisibility ?? 'private'}'.tr()}), selected: false, icon: Icons.arrow_forward_rounded)) else if (widget.pageId != null) Align(alignment: Alignment.centerLeft, child: HBChip(label: 'pages.composer_public'.tr(), selected: false, icon: Icons.public_rounded)) else Row(children: [Expanded(child: HBChip(label: 'post_composer.visibility_public'.tr(), selected: _visibility == 'public', onTap: _sending ? null : () => setState(() => _visibility = 'public'))), const SizedBox(width: AppSpacing.xs), Expanded(child: HBChip(label: 'post_composer.visibility_followers'.tr(), selected: _visibility == 'followers', onTap: _sending ? null : () => setState(() => _visibility = 'followers')))]),
                ])),
              ]),
              const SizedBox(height: AppSpacing.md),
              HBInput(controller: _controller, hint: 'post_composer.hint'.tr(), minLines: 4, maxLines: 12, maxLength: 5000, enabled: !_sending, autofocus: true, suffixIcon: HBButton.icon(icon: Icons.emoji_emotions_outlined, tooltip: 'post_composer.emoji'.tr(), onPressed: _sending ? null : _insertEmoji, size: HBButtonSize.sm), onChanged: (_) => setState(() {})),
              if (widget.pageId == null && widget.groupId == null) ...[const SizedBox(height: AppSpacing.sm), Align(alignment: Alignment.centerLeft, child: HBChip(label: _dogIds.isEmpty ? 'dogs.tags.action'.tr() : 'dogs.tags.selected'.tr(namedArgs: {'count': '${_dogIds.length}'}), selected: _dogIds.isNotEmpty, icon: Icons.pets_outlined, onTap: _sending ? null : _selectDogs))],
              if (_controller.text.length > 4500) Align(alignment: Alignment.centerRight, child: Text('${_controller.text.length}/5000', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))),
              if (_kind == ComposerKind.poll) ...[const SizedBox(height: AppSpacing.md), PollEditor(questionController: _pollQuestionController, optionControllers: _pollOptions, allowMultiple: _allowMultiple, durationDays: _pollDurationDays, enabled: !_sending, onChanged: () => setState(() {}), onAllowMultipleChanged: (value) => setState(() => _allowMultiple = value), onDurationChanged: (value) => setState(() => _pollDurationDays = value), onAddOption: () => setState(() => _pollOptions.add(TextEditingController())), onRemoveOption: (index) => setState(() => _pollOptions.removeAt(index).dispose()))],
              if (_kind == ComposerKind.checkin) ...[const SizedBox(height: AppSpacing.md), CheckinEditor(locationController: _locationController, latitude: _latitude, longitude: _longitude, selectedUnit: _huntingUnit, unitFromPosition: _unitFromPosition, locating: _locating, enabled: !_sending, regionId: profile?.homeRegionId, onChanged: () => setState(() {}), onUseLocation: _useLocation, onClearLocation: () => setState(() { _latitude = null; _longitude = null; _unitFromPosition = false; }), onUnitChanged: (value) => setState(() { _huntingUnit = value; _unitFromPosition = false; }))],
              if (_kind == ComposerKind.checkin && widget.locationPrivacyNoteKey != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Row(children: [const Icon(Icons.shield_outlined, size: 18, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.xs), Expanded(child: Text(widget.locationPrivacyNoteKey!.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightForest)))])),
              if (_media.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                ComposerMediaGrid(media: _media, uploadProgress: _uploadProgress, sending: _sending, onRemove: (index) => setState(() { _media.removeAt(index); if (_media.isEmpty) _isSensitive = false; }), onCrop: _cropMedia, onMove: (from, to) => setState(() { final item = _media.removeAt(from); _media.insert(to, item); })),
              ],
              if (_sending || _errorKey != null) ...[
                const SizedBox(height: AppSpacing.md),
                HBUploadProgress(progress: _media.isEmpty ? 0 : _uploadProgress.fold<double>(0, (sum, value) => sum + value) / _media.length, publishing: _publishing, fileIndex: _media.isEmpty || _activeUpload < 0 ? null : (_activeUpload + 1).clamp(1, _media.length), fileCount: _media.isEmpty ? null : _media.length, errorKey: _sending ? null : _errorKey, errorArgs: _errorArgs),
              ],
            ])),
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm), child: Row(children: [
              Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                Tooltip(message: _kind == ComposerKind.poll ? 'post_composer.poll_media_exclusive'.tr() : '', child: HBButton.ghost(label: 'post_composer.photo'.tr(), icon: Icons.photo_outlined, onPressed: _sending || _kind == ComposerKind.poll || _media.length >= (_kind == ComposerKind.checkin ? 4 : 10) ? null : _pickImages, size: HBButtonSize.sm)),
                Tooltip(message: _kind != ComposerKind.standard ? 'post_composer.video_exclusive'.tr() : '', child: HBButton.ghost(label: 'post_composer.video'.tr(), icon: Icons.videocam_outlined, onPressed: _sending || _kind != ComposerKind.standard ? null : _pickVideo, size: HBButtonSize.sm)),
                Tooltip(message: _media.isNotEmpty || _kind == ComposerKind.checkin ? 'post_composer.poll_media_exclusive'.tr() : '', child: HBButton.ghost(label: 'post_composer.poll'.tr(), icon: Icons.poll_outlined, onPressed: _sending || _media.isNotEmpty || _kind == ComposerKind.checkin ? null : _togglePoll, size: HBButtonSize.sm)),
                Tooltip(message: _hasVideo || _kind == ComposerKind.poll || _media.length > 4 ? 'post_composer.checkin_media_exclusive'.tr() : '', child: HBButton.ghost(label: 'post_composer.checkin'.tr(), icon: Icons.place_outlined, onPressed: _sending || _hasVideo || _kind == ComposerKind.poll || _media.length > 4 ? null : _toggleCheckin, size: HBButtonSize.sm)),
                if (_media.isNotEmpty) HBChip(label: 'sensitive.composer_label'.tr(), selected: _isSensitive, onTap: _sending ? null : () => setState(() => _isSensitive = !_isSensitive)),
              ]))),
            ])),
            ]),
          ),
        ),
      ),
    );
  }
}

enum ComposerKind { standard, poll, checkin }

class PollEditor extends StatelessWidget {
  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  final bool allowMultiple;
  final int? durationDays;
  final bool enabled;
  final VoidCallback onChanged;
  final ValueChanged<bool> onAllowMultipleChanged;
  final void Function(int? value) onDurationChanged;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;

  const PollEditor({super.key, required this.questionController, required this.optionControllers, required this.allowMultiple, required this.durationDays, required this.enabled, required this.onChanged, required this.onAllowMultipleChanged, required this.onDurationChanged, required this.onAddOption, required this.onRemoveOption});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('post_composer.poll_editor_title'.tr(), style: context.textStyles.titleMedium),
    const SizedBox(height: AppSpacing.sm),
    HBInput(controller: questionController, label: 'post_composer.poll_question'.tr(), hint: 'post_composer.poll_question_hint'.tr(), maxLength: 200, enabled: enabled, onChanged: (_) => onChanged()),
    const SizedBox(height: AppSpacing.sm),
    for (var index = 0; index < optionControllers.length; index++) ...[
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: HBInput(controller: optionControllers[index], label: 'post_composer.poll_option'.tr(namedArgs: {'n': '${index + 1}'}), maxLength: 80, enabled: enabled, onChanged: (_) => onChanged())),
        if (index >= 2) ...[const SizedBox(width: AppSpacing.xs), HBButton.icon(icon: Icons.close_rounded, onPressed: enabled ? () => onRemoveOption(index) : null, size: HBButtonSize.sm)],
      ]),
      const SizedBox(height: AppSpacing.sm),
    ],
    if (optionControllers.length < 4) HBButton.soft(label: 'post_composer.poll_add_option'.tr(), icon: Icons.add_rounded, onPressed: enabled ? onAddOption : null, size: HBButtonSize.sm),
    const SizedBox(height: AppSpacing.sm),
    Row(children: [Expanded(child: Text('post_composer.poll_multiple'.tr(), style: context.textStyles.bodyMedium)), Switch(value: allowMultiple, onChanged: enabled ? onAllowMultipleChanged : null, activeColor: LightModeColors.lightPrimary)]),
    const SizedBox(height: AppSpacing.xs),
    Text('post_composer.poll_duration'.tr(), style: context.textStyles.labelLarge),
    const SizedBox(height: AppSpacing.xs),
    Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
      HBChip(label: 'post_composer.poll_1_day'.tr(), selected: durationDays == 1, onTap: enabled ? () => onDurationChanged(1) : null),
      HBChip(label: 'post_composer.poll_3_days'.tr(), selected: durationDays == 3, onTap: enabled ? () => onDurationChanged(3) : null),
      HBChip(label: 'post_composer.poll_7_days'.tr(), selected: durationDays == 7, onTap: enabled ? () => onDurationChanged(7) : null),
      HBChip(label: 'post_composer.poll_no_end'.tr(), selected: durationDays == null, onTap: enabled ? () => onDurationChanged(null) : null),
    ]),
  ]);
}

class CheckinEditor extends ConsumerStatefulWidget {
  final TextEditingController locationController;
  final double? latitude;
  final double? longitude;
  final HuntingUnit? selectedUnit;
  final bool unitFromPosition;
  final bool locating;
  final bool enabled;
  final String? regionId;
  final VoidCallback onChanged;
  final VoidCallback onUseLocation;
  final VoidCallback onClearLocation;
  final ValueChanged<HuntingUnit?> onUnitChanged;

  const CheckinEditor({super.key, required this.locationController, required this.latitude, required this.longitude, required this.selectedUnit, required this.unitFromPosition, required this.locating, required this.enabled, required this.regionId, required this.onChanged, required this.onUseLocation, required this.onClearLocation, required this.onUnitChanged});

  @override
  ConsumerState<CheckinEditor> createState() => _CheckinEditorState();
}

class _CheckinEditorState extends ConsumerState<CheckinEditor> {
  final _unitController = TextEditingController();

  @override
  void didUpdateWidget(covariant CheckinEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unitController.text = widget.selectedUnit?.name ?? '';
  }

  @override
  void dispose() {
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final units = widget.regionId == null ? const AsyncData<List<HuntingUnit>>([]) : ref.watch(huntingUnitsByRegionProvider(widget.regionId!));
    final values = units.value ?? const <HuntingUnit>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('post_composer.checkin_editor_title'.tr(), style: context.textStyles.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      HBInput(controller: widget.locationController, label: 'post_composer.checkin_where'.tr(), hint: 'post_composer.checkin_where_hint'.tr(), maxLength: 120, enabled: widget.enabled, onChanged: (_) => widget.onChanged()),
      const SizedBox(height: AppSpacing.sm),
      HBButton.soft(label: 'post_composer.use_location'.tr(), icon: Icons.my_location_rounded, onPressed: widget.enabled && !widget.locating ? widget.onUseLocation : null, isLoading: widget.locating),
      if (widget.latitude != null && widget.longitude != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Row(children: [Expanded(child: Text('post_composer.location_acquired'.tr(namedArgs: {'lat': widget.latitude!.toStringAsFixed(3), 'lng': widget.longitude!.toStringAsFixed(3)}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightForest))), HBButton.icon(icon: Icons.close_rounded, onPressed: widget.enabled ? widget.onClearLocation : null, size: HBButtonSize.sm)]),
        if (widget.selectedUnit != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text((widget.unitFromPosition ? 'map.unit_from_position' : 'map.composer_unit').tr(namedArgs: {'name': widget.selectedUnit!.name}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightForest))),
      ],
      if (widget.regionId != null && values.isEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        HBEmptyState(icon: Icons.location_on_outlined, title: 'hunting.units_empty'.tr(namedArgs: {'region': widget.regionId!}), message: 'hunting.units_empty_forum'.tr()),
      ] else if (values.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        HBSelect<HuntingUnit>(value: widget.selectedUnit, placeholder: 'post_composer.hunting_unit_hint'.tr(), options: [for (final unit in values) HBSelectOption(value: unit, label: unit.name, groupLabel: 'hunting.unit_type.${unit.unitType}'.tr())], onChanged: widget.enabled ? widget.onUnitChanged : null),
      ],
    ]);
  }
}

class ComposerMediaGrid extends StatelessWidget {
  final List<PreparedUpload> media;
  final List<double> uploadProgress;
  final bool sending;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onCrop;
  final void Function(int from, int to) onMove;

  const ComposerMediaGrid({super.key, required this.media, required this.uploadProgress, required this.sending, required this.onRemove, required this.onCrop, required this.onMove});

  Widget _tile(BuildContext context, int index) => ComposerMediaTile(
    bytes: media[index].bytes,
    posterBytes: media[index].poster?.bytes,
    isVideo: media[index].contentType.startsWith('video/'),
    progress: index < uploadProgress.length ? uploadProgress[index] : null,
    canMoveLeft: index > 0,
    canMoveRight: index < media.length - 1,
    showReorder: media.length > 1,
    onRemove: sending ? null : () => onRemove(index),
    onCrop: sending || media[index].contentType.startsWith('video/') ? null : () => onCrop(index),
    onLeft: () => onMove(index, index - 1),
    onRight: () => onMove(index, index + 1),
  );

  @override
  Widget build(BuildContext context) {
    if (media.length == 1) {
      final item = media.first;
      final raw = item.width != null && item.height != null && item.height! > 0 ? item.width! / item.height! : 4 / 5;
      return AspectRatio(aspectRatio: raw.clamp(3 / 4, 16 / 9).toDouble(), child: _tile(context, 0));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: media.length <= 4 ? 2 : 3, crossAxisSpacing: AppSpacing.xs, mainAxisSpacing: AppSpacing.xs),
      itemCount: media.length,
      itemBuilder: (context, index) => _tile(context, index),
    );
  }
}

class ComposerMediaTile extends StatelessWidget {
  final Uint8List bytes;
  final Uint8List? posterBytes;
  final bool isVideo;
  final double? progress;
  final bool canMoveLeft;
  final bool canMoveRight;
  final bool showReorder;
  final VoidCallback? onRemove;
  final VoidCallback? onCrop;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const ComposerMediaTile({super.key, required this.bytes, this.posterBytes, required this.isVideo, required this.progress, required this.canMoveLeft, required this.canMoveRight, this.showReorder = true, required this.onRemove, required this.onCrop, required this.onLeft, required this.onRight});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Stack(fit: StackFit.expand, children: [
      isVideo && posterBytes != null ? Image.memory(posterBytes!, fit: BoxFit.cover) : isVideo ? const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.play_circle_outline_rounded, size: 48)) : Image.memory(bytes, fit: BoxFit.cover),
      if (isVideo) const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 48)),
      Positioned(top: AppSpacing.xs, right: AppSpacing.xs, child: HBButton.icon(icon: Icons.close_rounded, onPressed: onRemove, size: HBButtonSize.sm, backgroundColor: Colors.black54, foregroundColor: Colors.white)),
      if (onCrop != null) Positioned(top: AppSpacing.xs, left: AppSpacing.xs, child: Tooltip(message: 'media_crop.action'.tr(), child: HBButton.icon(icon: Icons.crop_rounded, onPressed: onCrop, size: HBButtonSize.sm, backgroundColor: Colors.black54, foregroundColor: Colors.white))),
      if (showReorder) Positioned(left: AppSpacing.xs, bottom: AppSpacing.xs, child: Row(children: [HBButton.icon(icon: Icons.arrow_back_rounded, onPressed: canMoveLeft && onRemove != null ? onLeft : null, size: HBButtonSize.sm, backgroundColor: Colors.black54, foregroundColor: Colors.white), const SizedBox(width: AppSpacing.xs), HBButton.icon(icon: Icons.arrow_forward_rounded, onPressed: canMoveRight && onRemove != null ? onRight : null, size: HBButtonSize.sm, backgroundColor: Colors.black54, foregroundColor: Colors.white)])),
      if (progress != null) Align(alignment: Alignment.bottomCenter, child: LinearProgressIndicator(value: progress, minHeight: 4, color: LightModeColors.lightPrimary, backgroundColor: LightModeColors.lightBackgroundSoft)),
    ]),
  );
}