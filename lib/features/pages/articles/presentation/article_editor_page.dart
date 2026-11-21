import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_source_picker.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/pages/articles/domain/article.dart';
import 'package:hb_social/features/pages/articles/providers/articles_providers.dart';
import 'package:hb_social/features/pages/providers/page_providers.dart';
import 'package:intl/intl.dart';

class ArticleEditorPage extends ConsumerWidget {
  final String pageSlug;
  final String? articleId;
  const ArticleEditorPage({super.key, required this.pageSlug, this.articleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(pageBySlugProvider(pageSlug));
    final article = articleId == null ? const AsyncValue<PageArticle?>.data(null) : ref.watch(articleByIdProvider(articleId!));
    if (page.isLoading || article.isLoading) return const PageColumns(center: HBListSkeleton(count: 5));
    if (page.hasError || article.hasError || page.value == null) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'articles.errors.load_title'.tr(), message: 'articles.errors.load_message'.tr())));
    if (page.value!.myRole == null || article.value?.canEdit == false) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.lock_outline_rounded, title: 'articles.errors.denied_title'.tr(), message: 'articles.errors.denied_message'.tr())));
    return ArticleEditor(pageId: page.value!.id, pageSlug: pageSlug, initial: article.value);
  }
}

class ArticleEditor extends ConsumerStatefulWidget {
  final String pageId;
  final String pageSlug;
  final PageArticle? initial;
  const ArticleEditor({super.key, required this.pageId, required this.pageSlug, this.initial});
  @override ConsumerState<ArticleEditor> createState() => _ArticleEditorState();
}

class _ArticleEditorState extends ConsumerState<ArticleEditor> {
  late final TextEditingController _title = TextEditingController(text: widget.initial?.title);
  late final TextEditingController _subtitle = TextEditingController(text: widget.initial?.subtitle);
  late final TextEditingController _slug = TextEditingController(text: widget.initial?.slug);
  late final TextEditingController _body = TextEditingController(text: widget.initial?.body);
  Timer? _autosave;
  String? _id;
  String? _coverPath;
  PreparedUpload? _cover;
  bool _dirty = false;
  bool _saving = false;
  bool _uploading = false;
  double _progress = 0;
  int _tab = 0;
  String? _error;

  @override void initState() { super.initState(); _id = widget.initial?.id; _coverPath = widget.initial?.coverPath; for (final controller in [_title, _subtitle, _slug, _body]) { controller.addListener(_changed); } }
  @override void dispose() { _autosave?.cancel(); for (final controller in [_title, _subtitle, _slug, _body]) { controller.removeListener(_changed); controller.dispose(); } super.dispose(); }

  void _changed() {
    if (!mounted) return;
    setState(() { _dirty = true; _error = null; });
    _autosave?.cancel();
    _autosave = Timer(const Duration(seconds: 30), () => _save(silent: true));
  }

  int get _wordCount => RegExp(r'\S+').allMatches(_body.text).length;
  int get _readingMinutes => (_wordCount / 220).ceil().clamp(1, 999);

  Future<void> _pickCover() async {
    try {
      final selected = await MediaSourcePicker.postImages(context, ref.read(mediaUploadServiceProvider), remaining: 1);
      if (selected.isNotEmpty && mounted) setState(() { _cover = selected.first; _dirty = true; });
    } on AppException catch (error) { if (mounted) setState(() => _error = error.messageKey); }
  }

  Future<String?> _upload(PreparedUpload upload) async {
    final userId = ref.read(authSessionProvider).value?.user.id;
    if (userId == null) return null;
    final progress = UploadProgress();
    final subscription = progress.stream.listen((value) { if (mounted) setState(() => _progress = value); });
    try { return (await ref.read(mediaUploadServiceProvider).uploadToBucket(bucket: 'page-media', userId: userId, upload: upload, isPublic: true, progress: progress)).path; }
    finally { await subscription.cancel(); await progress.close(); }
  }

  Future<bool> _save({bool silent = false}) async {
    if (_saving || !_dirty && _id != null) return true;
    setState(() { _saving = true; _error = null; });
    try {
      if (_cover != null) { setState(() => _uploading = true); _coverPath = await _upload(_cover!); }
      _id = await ref.read(articlesRepositoryProvider).upsert(id: _id, pageId: widget.pageId, title: _title.text, subtitle: _subtitle.text, coverPath: _coverPath, body: _body.text, slug: _slug.text);
      if (mounted) setState(() { _saving = false; _uploading = false; _dirty = false; _cover = null; });
      ref.invalidate(articlesByPageProvider((pageId: widget.pageId, status: 'all')));
      if (!silent && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('articles.editor.saved'.tr())));
      return true;
    } on AppException catch (error) {
      if (mounted) setState(() { _saving = false; _uploading = false; _error = error.messageKey; });
      return false;
    }
  }

  Future<void> _publish({bool schedule = false}) async {
    if (!await _save() || _id == null || !mounted) return;
    DateTime? scheduledAt;
    if (schedule) scheduledAt = await showDialog<DateTime>(context: context, builder: (_) => const ArticleScheduleDialog());
    if (schedule && scheduledAt == null) return;
    final confirmed = schedule || await showDialog<bool>(context: context, builder: (_) => const ArticlePublishDialog()) == true;
    if (!confirmed) return;
    try {
      await ref.read(articlesRepositoryProvider).publish(_id!, scheduledAt: scheduledAt);
      ref.invalidate(articleByIdProvider(_id!));
      ref.invalidate(articlesByPageProvider((pageId: widget.pageId, status: 'all')));
      if (mounted) context.go(AppRoutes.pageStudioPath(widget.pageSlug));
    } on AppException catch (error) { if (mounted) setState(() => _error = error.messageKey); }
  }

  Future<void> _lifecycle(String action) async {
    if (_id == null) return;
    try {
      if (action == 'draft') await ref.read(articlesRepositoryProvider).unpublish(_id!, archive: false);
      if (action == 'archive') await ref.read(articlesRepositoryProvider).unpublish(_id!, archive: true);
      if (action == 'delete') {
        final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text('articles_editor_delete_confirm_title'.tr()), content: Text('articles_editor_delete_confirm_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop(false)), HBButton.primary(label: 'articles.editor.delete'.tr(), onPressed: () => context.pop(true))])) == true;
        if (!confirmed) return;
        await ref.read(articlesRepositoryProvider).delete(_id!);
      }
      ref.invalidate(articlesByPageProvider((pageId: widget.pageId, status: 'all')));
      if (mounted) context.go(AppRoutes.pageStudioPath(widget.pageSlug));
    } on AppException catch (error) { if (mounted) setState(() => _error = error.messageKey); }
  }

  void _wrap(String before, [String after = '']) {
    final selection = _body.selection;
    final start = selection.start < 0 ? _body.text.length : selection.start;
    final end = selection.end < 0 ? start : selection.end;
    final selected = _body.text.substring(start, end);
    _body.value = TextEditingValue(text: '${_body.text.substring(0, start)}$before$selected$after${_body.text.substring(end)}', selection: TextSelection.collapsed(offset: end + before.length + after.length));
  }

  Future<void> _insertImage() async {
    final selected = await MediaSourcePicker.postImages(context, ref.read(mediaUploadServiceProvider), remaining: 1);
    if (selected.isEmpty) return;
    setState(() { _uploading = true; _progress = 0; });
    final path = await _upload(selected.first);
    if (path != null) {
      final url = storagePublicUrl(ref.read(supabaseClientProvider), 'page-media', path);
      _wrap('![]($url)');
    }
    if (mounted) setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final published = widget.initial?.status == 'published';
    return PageColumns(centerMaxWidth: 1100, center: Column(children: [
      Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [HBButton.icon(icon: Icons.arrow_back_rounded, onPressed: () => context.go(AppRoutes.pageStudioPath(widget.pageSlug))), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(_id == null ? 'articles.editor.new_title'.tr() : 'articles.editor.edit_title'.tr(), style: context.textStyles.titleLarge)), HBButton.secondary(label: 'articles.editor.save'.tr(), onPressed: _saving ? null : _save, isLoading: _saving), const SizedBox(width: AppSpacing.sm), HBButton.primary(label: 'articles.editor.publish'.tr(), onPressed: _saving ? null : _publish), PopupMenuButton<String>(onSelected: (value) { if (value == 'schedule') _publish(schedule: true); else _lifecycle(value); }, itemBuilder: (_) => [PopupMenuItem(value: 'schedule', child: Text('articles.editor.schedule'.tr())), if (published) PopupMenuItem(value: 'draft', child: Text('articles.editor.to_draft'.tr())), PopupMenuItem(value: 'archive', child: Text('articles.editor.archive'.tr())), if (_id != null) PopupMenuItem(value: 'delete', child: Text('articles.editor.delete'.tr()))])])),
      const Divider(height: 1),
      Expanded(child: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.all(AppSpacing.lg), sliver: SliverList.list(children: [
        HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          HBInput(controller: _title, label: 'articles.editor.title'.tr(), maxLength: 160), const SizedBox(height: AppSpacing.md),
          HBInput(controller: _subtitle, label: 'articles.editor.subtitle'.tr(), maxLength: 300), const SizedBox(height: AppSpacing.md),
          HBInput(controller: _slug, label: 'articles.editor.slug'.tr(), enabled: !published, maxLength: 160), const SizedBox(height: AppSpacing.xs), Text('articles.editor.url_preview'.tr(namedArgs: {'url': 'huntingbook.app/p/${widget.pageSlug}/articoli/${_slug.text}'}), style: context.textStyles.bodySmall?.withColor(LightModeColors.textSecondary)),
          const SizedBox(height: AppSpacing.md), HBImageField(kind: HBImageFieldKind.cover, imageUrl: widget.initial?.coverUrl, imageBytes: _cover?.bytes, onPick: _pickCover, onRemove: _cover == null ? null : () => setState(() => _cover = null), changeLabel: 'articles.editor.cover'.tr(), removeLabel: 'form.remove_image'.tr()),
        ])),
        const SizedBox(height: AppSpacing.md),
        HBSegmentedTabs(labels: ['articles.editor.write'.tr(), 'articles.editor.preview'.tr()], selectedIndex: _tab, onChanged: (value) => setState(() => _tab = value)),
        const SizedBox(height: AppSpacing.sm),
        if (_tab == 0) ArticleMarkdownEditor(controller: _body, onFormat: _wrap, onImage: _insertImage) else HBCard(child: ArticleMarkdownBody(data: _body.text)),
        const SizedBox(height: AppSpacing.sm), Text('articles.editor.stats'.tr(namedArgs: {'words': '$_wordCount', 'minutes': '$_readingMinutes'}), textAlign: TextAlign.end, style: context.textStyles.bodySmall?.withColor(LightModeColors.textSecondary)),
        if (_saving || _uploading || _error != null) ...[const SizedBox(height: AppSpacing.md), HBUploadProgress(progress: _progress, publishing: _saving && !_uploading, errorKey: _error)],
      ]))])),
    ]));
  }
}

class ArticleMarkdownEditor extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String before, [String after]) onFormat;
  final VoidCallback onImage;
  const ArticleMarkdownEditor({super.key, required this.controller, required this.onFormat, required this.onImage});
  @override Widget build(BuildContext context) => HBCard(child: Column(children: [
    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
      HBButton.ghost(label: 'articles_editor_h2'.tr(), onPressed: () => onFormat('## ')), HBButton.ghost(label: 'articles_editor_h3'.tr(), onPressed: () => onFormat('### ')), HBButton.icon(icon: Icons.format_bold_rounded, tooltip: 'articles_editor_bold'.tr(), onPressed: () => onFormat('**', '**')), HBButton.icon(icon: Icons.format_italic_rounded, tooltip: 'articles_editor_italic'.tr(), onPressed: () => onFormat('_', '_')), HBButton.icon(icon: Icons.format_list_bulleted_rounded, tooltip: 'articles_editor_bulleted'.tr(), onPressed: () => onFormat('- ')), HBButton.icon(icon: Icons.format_list_numbered_rounded, tooltip: 'articles_editor_numbered'.tr(), onPressed: () => onFormat('1. ')), HBButton.icon(icon: Icons.link_rounded, tooltip: 'articles_editor_link'.tr(), onPressed: () => onFormat('[', '](https://)')), HBButton.icon(icon: Icons.image_outlined, tooltip: 'articles_editor_image'.tr(), onPressed: onImage),
    ])),
    const Divider(),
    Shortcuts(shortcuts: const {SingleActivator(LogicalKeyboardKey.keyB, control: true): ActivateIntent()}, child: HBInput(controller: controller, minLines: 18, maxLines: 40, maxLength: 50000, hint: 'articles.editor.body_hint'.tr())),
  ]));
}

class ArticleMarkdownBody extends StatelessWidget {
  final String data;
  const ArticleMarkdownBody({super.key, required this.data});
  @override Widget build(BuildContext context) => MarkdownBody(data: data, softLineBreak: true, styleSheet: MarkdownStyleSheet(h2: context.textStyles.headlineSmall?.withColor(LightModeColors.bosco), h3: context.textStyles.titleLarge?.withColor(LightModeColors.bosco), p: context.textStyles.bodyLarge?.copyWith(height: 1.65), a: context.textStyles.bodyLarge?.withColor(LightModeColors.link), blockquoteDecoration: BoxDecoration(color: LightModeColors.boscoTint, borderRadius: BorderRadius.circular(AppRadius.md)), img: const TextStyle()), imageBuilder: (uri, title, alt) => ClipRRect(borderRadius: BorderRadius.circular(AppRadius.media), child: Image.network(uri.toString(), width: double.infinity, fit: BoxFit.cover)));
}

class ArticlePublishDialog extends StatelessWidget {
  const ArticlePublishDialog({super.key});
  @override Widget build(BuildContext context) => AlertDialog(title: Text('articles.editor.publish_confirm_title'.tr()), content: Text('articles.editor.publish_confirm_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop(false)), HBButton.primary(label: 'articles.editor.publish'.tr(), onPressed: () => context.pop(true))]);
}

class ArticleScheduleDialog extends StatefulWidget {
  const ArticleScheduleDialog({super.key});
  @override State<ArticleScheduleDialog> createState() => _ArticleScheduleDialogState();
}

class _ArticleScheduleDialogState extends State<ArticleScheduleDialog> {
  DateTime value = DateTime.now().add(const Duration(minutes: 10));
  Future<void> _pick() async { final date = await showDatePicker(context: context, initialDate: value, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30))); if (date == null || !mounted) return; final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value)); if (time != null) setState(() => value = DateTime(date.year, date.month, date.day, time.hour, (time.minute ~/ 5) * 5)); }
  @override Widget build(BuildContext context) => AlertDialog(title: Text('articles.editor.schedule'.tr()), content: InkWell(onTap: _pick, child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Text(DateFormat.yMd(context.locale.toString()).add_Hm().format(value)))), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop()), HBButton.primary(label: 'articles.editor.schedule'.tr(), onPressed: () => context.pop(value))]);
}