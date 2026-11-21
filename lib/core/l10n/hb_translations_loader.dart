import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HBTranslationsLoader extends AssetLoader {
  const HBTranslationsLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final source = await rootBundle.loadString('$path/${locale.languageCode}.json');
    final translations = Map<String, dynamic>.from(jsonDecode(source) as Map);
    for (final entry in translations.entries.where((entry) => entry.key.contains('.')).toList()) {
      _setNested(translations, entry.key, entry.value);
      translations.remove(entry.key);
    }
    try {
      final rows = await Supabase.instance.client.from('translation_overrides').select('key,value').eq('locale', locale.languageCode);
      for (final row in rows as List) {
        _setNested(translations, row['key'].toString(), row['value'].toString());
      }
    } catch (_) {
      // Asset translations remain authoritative when the public override query is unavailable.
    }
    return translations;
  }

  void _setNested(Map<String, dynamic> target, String key, dynamic value) {
    final parts = key.split('.');
    var current = target;
    for (var index = 0; index < parts.length - 1; index++) {
      final existing = current[parts[index]];
      if (existing is Map<String, dynamic>) {
        current = existing;
      } else if (existing is Map) {
        current = Map<String, dynamic>.from(existing);
        target[parts[index]] = current;
      } else {
        final next = <String, dynamic>{};
        current[parts[index]] = next;
        current = next;
      }
    }
    current[parts.last] = value;
  }
}