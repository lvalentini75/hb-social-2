import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every literal translation key used in lib exists in all locales', () {
    final keyPattern = RegExp(r'''['"]([A-Za-z0-9_.-]+)['"]\.(?:tr|plural)\(''');
    final functionPattern = RegExp(r'''\btr\(\s*['"]([A-Za-z0-9_.-]+)['"]''');
    final keys = <String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart') || entity.path.endsWith('catalog.hologram.dart')) continue;
      final source = entity.readAsStringSync();
      for (final match in keyPattern.allMatches(source)) keys.add(match.group(1)!);
      for (final match in functionPattern.allMatches(source)) keys.add(match.group(1)!);
    }

    for (final locale in ['it', 'en', 'fr', 'es', 'de']) {
      final json = jsonDecode(File('assets/translations/$locale.json').readAsStringSync()) as Map<String, dynamic>;
      final missing = keys.where((key) => !_containsText(json, key)).toList()..sort();
      expect(missing, isEmpty, reason: '$locale is missing: ${missing.join(', ')}');
      for (final namespace in ['story_composer', 'story_editor', 'story_tray', 'story_viewer', 'story_highlights', 'friendship', 'connections', 'people', 'safety', 'sensitive', 'suspended', 'strikes', 'group_studio', 'forums', 'forum_studio', 'albums', 'weather']) {
        expect(json[namespace], isA<Map<String, dynamic>>(), reason: '$locale.$namespace must be a group, not a simple key');
      }
      for (final key in ['errors.file_unreadable', 'errors.image_processing_failed', 'errors.video_unreadable', 'errors.video_too_long', 'story_composer.duration_unavailable', 'story_composer.analyzing_video', 'story_composer.published', 'story_composer.video_limits', 'story_editor.sticker_hunting', 'story_editor.category_location', 'story_editor.category_weather', 'story_editor.category_prey', 'story_editor.category_milestones', 'story_editor.mention']) {
        expect(_containsText(json, key), isTrue, reason: '$locale is missing required story upload key $key');
      }
      for (final key in ['common.remove', 'common.select', 'common.search', 'studio_overview.no_period_data', 'forum_studio.analytics.metrics.members', 'group_analytics.metrics.members', 'page_analytics.metrics.followers']) {
        expect(_containsText(json, key), isTrue, reason: '$locale is missing nested translation key $key');
      }
    }
  });
}

bool _containsText(Map<String, dynamic> json, String key) {
  dynamic value = json;
  for (final segment in key.split('.')) {
    if (value is! Map<String, dynamic> || !value.containsKey(segment)) return false;
    value = value[segment];
  }
  return value is String && value.trim().isNotEmpty || value is Map<String, dynamic> && value.isNotEmpty;
}