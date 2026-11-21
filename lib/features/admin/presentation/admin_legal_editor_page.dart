import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/features/admin/providers/admin_p43_providers.dart';
import 'package:hb_social/features/pages/articles/presentation/article_editor_page.dart';

const legalEditorLocales = ['it', 'en', 'fr', 'es', 'de'];

class AdminLegalEditorPage extends ConsumerStatefulWidget {
  final String kind;
  final int? version;
  const AdminLegalEditorPage({super.key, required this.kind, this.version});
  @override ConsumerState<AdminLegalEditorPage> createState() => _AdminLegalEditorPageState();
}

class _AdminLegalEditorPageState extends ConsumerState<AdminLegalEditorPage> {
  final fields = {for (final locale in legalEditorLocales) locale: LegalLocaleControllers()};
  final complete = <String>{};
  int localeIndex = 0;
  int mobileTab = 0;
  int? version;
  String status = 'draft';
  bool loading = true;
  bool saving = false;
  bool publishing = false;

  @override void initState() { super.initState(); version = widget.version; _load(); }
  @override void dispose() { for (final item in fields.values) { item.dispose(); } super.dispose(); }

  Future<void> _load() async {
    if (version == null) { if (mounted) setState(() => loading = false); return; }
    try {
      final rows = await ref.read(adminP43RepositoryProvider).legalDocuments(widget.kind, version!);
      for (final row in rows) {
        final locale = row['locale']?.toString();
        final value = fields[locale];
        if (value == null) continue;
        value.title.text = row['title']?.toString() ?? '';
        value.summary.text = row['summary']?.toString() ?? '';
        value.body.text = row['body_md']?.toString() ?? '';
        complete.add(locale!);
        status = row['status']?.toString() ?? status;
      }
    } catch (error) { _showError(error); }
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _saveLocale() async {
    final locale = legalEditorLocales[localeIndex];
    final value = fields[locale]!;
    if (value.title.text.trim().isEmpty || value.summary.text.length > 1000 || value.body.text.trim().length < 50) { _message('admin.legal.validation'); return; }
    setState(() => saving = true);
    try {
      final result = await ref.read(adminP43RepositoryProvider).legalUpsert(kind: widget.kind, locale: locale, title: value.title.text, bodyMarkdown: value.body.text, summary: value.summary.text, version: version);
      version = (result['version'] as num?)?.toInt() ?? version;
      status = result['status']?.toString() ?? status;
      complete.add(locale);
      ref.invalidate(adminLegalListProvider);
      if (mounted) { setState(() {}); _message('admin.legal.saved'); }
    } catch (error) { _showError(error); }
    finally { if (mounted) setState(() => saving = false); }
  }

  void _copyItalian() {
    final locale = legalEditorLocales[localeIndex];
    if (locale == 'it') return;
    fields[locale]!.title.text = fields['it']!.title.text;
    fields[locale]!.body.text = fields['it']!.body.text;
    fields[locale]!.summary.text = fields['it']!.summary.text;
    setState(() {});
  }

  Future<void> _publish() async {
    if (version == null || complete.length != legalEditorLocales.length) return;
    final reacceptance = const {'privacy', 'terms'}.contains(widget.kind);
    final accepted = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('admin.legal.publish_title'.tr()), content: Text((reacceptance ? 'admin.legal.publish_reacceptance' : 'admin.legal.publish_confirm').tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'admin.legal.publish'.tr(), onPressed: () => dialogContext.pop(true))]));
    if (accepted != true || !mounted) return;
    setState(() => publishing = true);
    try {
      await ref.read(adminP43RepositoryProvider).legalPublish(widget.kind, version!);
      status = 'published';
      ref.invalidate(adminLegalListProvider);
      if (mounted) { _message('admin.legal.published'); context.pop(); }
    } catch (error) { _showError(error); }
    finally { if (mounted) setState(() => publishing = false); }
  }

  void _message(String key, {Map<String, String> args = const {}}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr(namedArgs: args))));
  void _showError(Object error) { final value = AppException.from(error); if (mounted) _message(value.messageKey, args: value.namedArgs); }

  @override Widget build(BuildContext context) {
    final locale = legalEditorLocales[localeIndex];
    final value = fields[locale]!;
    final readOnly = status == 'published';
    return CustomScrollView(slivers: [
      SliverPadding(padding: const EdgeInsets.all(AppSpacing.lg), sliver: SliverList.list(children: [
        Row(children: [HBButton.icon(icon: Icons.arrow_back_rounded, tooltip: 'a11y.back'.tr(), onPressed: context.pop), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('legal.kind.${widget.kind}'.tr(), style: context.textStyles.headlineSmall), Text('admin.legal.editor_meta'.tr(namedArgs: {'version': version?.toString() ?? '-', 'status': 'admin.legal.status_value.$status'.tr()}))])), HBChip(label: 'admin.legal.languages_count'.tr(namedArgs: {'count': '${complete.length}'}), selected: complete.length == 5)]),
        const SizedBox(height: AppSpacing.lg),
        if (loading) const LinearProgressIndicator() else ...[
          HBSegmentedTabs(labels: [for (final item in legalEditorLocales) 'admin.legal.locale.$item'.tr()], selectedIndex: localeIndex, onChanged: (index) => setState(() { localeIndex = index; mobileTab = 0; })),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(builder: (context, constraints) {
            final editor = LegalLocaleEditor(controllers: value, enabled: !readOnly, onChanged: () => setState(() {}));
            final preview = HBCard(child: ArticleMarkdownBody(data: value.body.text));
            if (constraints.maxWidth >= 900) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: editor), const SizedBox(width: AppSpacing.lg), Expanded(child: preview)]);
            return Column(children: [HBSegmentedTabs(labels: ['admin.legal.write'.tr(), 'admin.legal.preview'.tr()], selectedIndex: mobileTab, onChanged: (index) => setState(() => mobileTab = index)), const SizedBox(height: AppSpacing.sm), mobileTab == 0 ? editor : preview]);
          }),
          const SizedBox(height: AppSpacing.md),
          Wrap(alignment: WrapAlignment.end, spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [if (locale != 'it' && !readOnly) HBButton.soft(label: 'admin.legal.copy_italian'.tr(), onPressed: _copyItalian), if (!readOnly) HBButton.secondary(label: 'admin.legal.save_locale'.tr(), isLoading: saving, onPressed: _saveLocale), HBButton.primary(label: 'admin.legal.publish'.tr(), isLoading: publishing, onPressed: !readOnly && complete.length == 5 ? _publish : null)]),
        ],
      ])),
    ]);
  }
}

class LegalLocaleControllers {
  final title = TextEditingController();
  final summary = TextEditingController();
  final body = TextEditingController();
  void dispose() { title.dispose(); summary.dispose(); body.dispose(); }
}

class LegalLocaleEditor extends StatelessWidget {
  final LegalLocaleControllers controllers;
  final bool enabled;
  final VoidCallback onChanged;
  const LegalLocaleEditor({super.key, required this.controllers, required this.enabled, required this.onChanged});
  @override Widget build(BuildContext context) => HBCard(child: Column(children: [
    HBFormField(label: 'admin.legal.field_title'.tr(), required: true, child: HBInput(controller: controllers.title, enabled: enabled, maxLength: 200, onChanged: (_) => onChanged())),
    HBFormField(label: 'admin.legal.field_summary'.tr(), child: HBInput(controller: controllers.summary, enabled: enabled, maxLength: 1000, maxLines: 4, onChanged: (_) => onChanged())),
    HBFormField(label: 'admin.legal.field_body'.tr(), required: true, helper: 'admin.legal.body_help'.tr(), child: HBInput(controller: controllers.body, enabled: enabled, minLines: 18, maxLines: 40, maxLength: 50000, onChanged: (_) => onChanged())),
  ]));
}