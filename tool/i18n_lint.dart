import 'dart:io';

final _visibleConstructor = RegExp(r'''\b(?:Text|SelectableText)\s*\(\s*(['"])(.*?)\1''');
final _visibleProperty = RegExp(r'''\b(?:hintText|labelText|helperText|errorText|tooltip|semanticLabel|title|subtitle|label|message)\s*:\s*(['"])(.*?)\1''');
final _key = RegExp(r'^[a-z0-9_.-]+$');
final _letters = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]');

void main() {
  final violations = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart') || entity.path.contains('/supabase/') || entity.path.endsWith('catalog.hologram.dart')) continue;
    final lines = entity.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (line.contains('// i18n-ignore')) continue;
      for (final pattern in [_visibleConstructor, _visibleProperty]) {
        for (final match in pattern.allMatches(line)) {
          final text = match.group(2)!;
          if (_excluded(text, line, match.end)) continue;
          violations.add('${entity.path}:${index + 1}: "$text"');
        }
      }
    }
  }
  for (final violation in violations) { stdout.writeln(violation); }
  stdout.writeln('i18n lint: ${violations.length} violation(s)');
  if (violations.isNotEmpty) exitCode = 1;
}

bool _excluded(String text, String line, int literalEnd) {
  if (!_letters.hasMatch(text) || _key.hasMatch(text) || text.startsWith('http://') || text.startsWith('https://') || text.startsWith('assets/') || text.startsWith('package:')) return true;
  if (line.substring(literalEnd).trimLeft().startsWith('.tr(') || line.substring(literalEnd).trimLeft().startsWith('.plural(')) return true;
  if (line.contains('fontFamily:') || line.contains('Color(') || line.contains('RegExp(') || line.contains('DateFormat(')) return true;
  if (line.contains('const ') && !RegExp(r'\b(?:Text|SelectableText|SnackBar|AlertDialog|AppBar|HB[A-Z])\b').hasMatch(line)) return true;
  return false;
}