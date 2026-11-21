import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IT EN FR ES DE translations have complete parity', () {
    final locales = <String, Map<String, dynamic>>{};
    for (final locale in const ['it', 'en', 'fr', 'es', 'de']) {
      locales[locale] = Map<String, dynamic>.from(jsonDecode(File('assets/translations/$locale.json').readAsStringSync()) as Map);
    }
    final flattened = {for (final entry in locales.entries) entry.key: _flatten(entry.value)};
    final reference = flattened['it']!;
    for (final entry in flattened.entries) {
      expect(entry.value.keys.toSet(), reference.keys.toSet(), reason: '${entry.key} translation keys differ from IT');
      for (final value in entry.value.entries) {
        expect(value.value.trim(), isNotEmpty, reason: '${entry.key}.${value.key} is empty');
        expect(value.value, isNot(value.key), reason: '${entry.key}.${value.key} equals its key');
        expect(value.value.toUpperCase(), isNot(contains('TODO')), reason: '${entry.key}.${value.key} contains TODO');
        expect(_placeholders(value.value), _placeholders(reference[value.key]!), reason: '${entry.key}.${value.key} placeholders differ from IT');
      }
    }
  });
}

Map<String, String> _flatten(Map<String, dynamic> source, [String prefix = '']) {
  final result = <String, String>{};
  for (final entry in source.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (entry.value is Map) { result.addAll(_flatten(Map<String, dynamic>.from(entry.value as Map), key)); }
    else { result[key] = entry.value?.toString() ?? ''; }
  }
  return result;
}

Set<String> _placeholders(String value) => RegExp(r'\{[^{}]+\}').allMatches(value).map((match) => match.group(0)!).toSet();