import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/providers/translation_providers.dart';
import 'package:hb_social/core/services/translation_service.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_rich_text.dart';

/// Renders original content or its cached/DeepL translation with a per-item toggle.
class TranslatableText extends ConsumerStatefulWidget {
  final String type;
  final String id;
  final String field;
  final String text;
  final TextStyle? style;
  final bool richText;
  final int? maxLines;
  final Widget Function(String text)? builder;

  const TranslatableText({super.key, required this.type, required this.id, required this.field, required this.text, this.style, this.richText = false, this.maxLines, this.builder});
  @override ConsumerState<TranslatableText> createState() => _TranslatableTextState();
}

class _TranslatableTextState extends ConsumerState<TranslatableText> {
  ContentTranslation? result;
  bool original = false;
  bool loading = false;

  @override void initState() { super.initState(); Future.microtask(_loadCached); }

  Future<void> _loadCached() async {
    final service = ref.read(translationServiceProvider);
    await service.prefetch(widget.type, [widget.id]);
    if (!mounted) return;
    final cached = service.cached(widget.type, widget.id);
    final usage = await ref.read(translationUsageProvider.future);
    if (!mounted) return;
    setState(() => result = cached);
    if (cached == null && usage.enabled && usage.autoTranslate) await _translate(userInitiated: false);
  }

  Future<void> _translate({required bool userInitiated}) async {
    setState(() => loading = true);
    try {
      final value = await ref.read(translationServiceProvider).translate(widget.type, widget.id);
      if (!mounted) return;
      setState(() { result = value; original = false; });
      if (userInitiated && (value.status == TranslationStatus.denied || value.status == TranslationStatus.error)) _showError(value);
    } catch (_) {
      if (mounted && userInitiated) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('translate.error'.tr())));
    } finally { if (mounted) setState(() => loading = false); }
  }

  void _showError(ContentTranslation value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translationReasonKey(value.reason).tr())));

  @override Widget build(BuildContext context) {
    final usage = ref.watch(translationUsageProvider).value;
    final translated = result?.status == TranslationStatus.cached ? result?.field(widget.field) : null;
    final shown = !original && translated?.isNotEmpty == true ? translated! : widget.text;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.builder != null) widget.builder!(shown) else if (widget.richText) HBRichText(text: shown, style: widget.style, maxLines: widget.maxLines) else Text(shown, style: widget.style, maxLines: widget.maxLines, overflow: widget.maxLines == null ? null : TextOverflow.ellipsis),
      if (translated != null) Padding(padding: const EdgeInsets.only(top: 4), child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [Text('translate.attribution'.tr(namedArgs: {'language': _language(result!.sourceLanguage)}), style: context.textStyles.labelSmall?.withColor(LightModeColors.textTertiary)), HBButton.ghost(label: original ? 'translate.show_translation'.tr() : 'translate.show_original'.tr(), onPressed: () => setState(() => original = !original), size: HBButtonSize.sm)]))
      else if (result?.status != TranslationStatus.sameLanguage && usage?.enabled == true && usage?.autoTranslate != true)
        HBButton.ghost(label: 'translate.action'.tr(), isLoading: loading, onPressed: () => _translate(userInitiated: true), size: HBButtonSize.sm),
    ]);
  }

  String _language(String code) { final key = 'i18n.lang.$code'; final value = key.tr(); return value == key ? code.toUpperCase() : value; }
}