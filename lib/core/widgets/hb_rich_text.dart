import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders the same hashtags and mentions extracted by the database triggers.
class HBRichText extends StatelessWidget {
  static final RegExp _tokenPattern = RegExp(r'(?<![A-Za-z0-9_])#[A-Za-z0-9_]{2,60}|(?<![A-Za-z0-9_])@[A-Za-z0-9_]{3,30}|https?://[^\s<]+|/albums/[A-Za-z0-9-]+', caseSensitive: false);
  final String text;
  final TextStyle? style;
  final String? prefix;
  final TextStyle? prefixStyle;
  final int? maxLines;
  final TextOverflow overflow;

  const HBRichText({super.key, required this.text, this.style, this.prefix, this.prefixStyle, this.maxLines, this.overflow = TextOverflow.clip});

  Future<void> _openUrl(BuildContext context, String value) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('rich_text.open_link_title'.tr()),
        content: Text('rich_text.open_link_message'.tr(namedArgs: {'url': value})),
        actions: [
          HBButton.ghost(label: 'rich_text.cancel'.tr(), onPressed: () => dialogContext.pop(false), size: HBButtonSize.sm),
          HBButton.primary(label: 'rich_text.open'.tr(), onPressed: () => dialogContext.pop(true), size: HBButtonSize.sm),
        ],
      ),
    );
    if (confirmed == true) await launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? context.textStyles.bodyMedium;
    final spans = <InlineSpan>[if (prefix != null) TextSpan(text: prefix, style: prefixStyle)];
    var offset = 0;
    for (final match in _tokenPattern.allMatches(text)) {
      if (match.start > offset) spans.add(TextSpan(text: text.substring(offset, match.start)));
      final value = match.group(0)!;
      final isUrl = value.toLowerCase().startsWith('http');
      final isAlbum = value.toLowerCase().startsWith('/albums/');
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: InkWell(
          onTap: () {
            if (value.startsWith('#')) context.push(AppRoutes.tagPath(value.substring(1).toLowerCase()));
            if (value.startsWith('@')) context.push(AppRoutes.publicProfilePath(value.substring(1)));
            if (isAlbum) context.push(value);
            if (isUrl) _openUrl(context, value);
          },
          child: Text(value, style: baseStyle?.copyWith(color: LightModeColors.link, fontWeight: FontWeight.w500)),
        ),
      ));
      offset = match.end;
    }
    if (offset < text.length) spans.add(TextSpan(text: text.substring(offset)));
    return Text.rich(TextSpan(style: baseStyle, children: spans), maxLines: maxLines, overflow: overflow, softWrap: true);
  }
}