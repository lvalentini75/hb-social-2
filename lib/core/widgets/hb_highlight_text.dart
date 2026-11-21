import 'package:flutter/material.dart';

/// Highlights words whose normalized value starts with a searched prefix.
class HBHighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;

  const HBHighlightText({super.key, required this.text, required this.query, this.style, this.maxLines, this.overflow = TextOverflow.clip});

  @override
  Widget build(BuildContext context) {
    final prefixes = RegExp(r'[\p{L}\p{N}_]+', unicode: true).allMatches(query).map((match) => _normalize(match.group(0)!)).where((word) => word.length >= 2).toSet();
    if (prefixes.isEmpty) return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in RegExp(r'[\p{L}\p{N}_]+', unicode: true).allMatches(text)) {
      if (match.start > cursor) spans.add(TextSpan(text: text.substring(cursor, match.start)));
      final word = match.group(0)!;
      final highlighted = prefixes.any(_normalize(word).startsWith);
      spans.add(TextSpan(text: word, style: highlighted ? const TextStyle(fontWeight: FontWeight.w700) : null));
      cursor = match.end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return Text.rich(TextSpan(style: style, children: spans), maxLines: maxLines, overflow: overflow);
  }
}

String _normalize(String value) {
  const accented = 'àáâäãåèéêëìíîïòóôöõùúûüýÿçñšž';
  const plain = 'aaaaaaeeeeiiiiooooouuuuyycnsz';
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final character = String.fromCharCode(rune);
    final index = accented.indexOf(character);
    buffer.write(index < 0 ? character : plain[index]);
  }
  return buffer.toString();
}