import 'package:supabase_flutter/supabase_flutter.dart';

/// A safe, localized application error exposed to presentation code.
class AppException implements Exception {
  final String messageKey;
  final Map<String, String> namedArgs;

  const AppException(this.messageKey, {this.namedArgs = const {}});

  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (message.contains('account_suspended')) return const AppException('suspended.write_blocked');
      if (message.contains('content_blocked')) return const AppException('sensitive.content_blocked');
      if (message.contains('post_sensitive_not_allowed')) return const AppException('sensitive.not_allowed');
      const postErrors = {'post_kind_invalid', 'post_visibility_invalid', 'post_content_required', 'post_content_too_long', 'post_media_required', 'post_media_too_many', 'post_media_kind_invalid', 'post_media_path_invalid', 'not_authenticated'};
      for (final key in postErrors) {
        if (message.contains(key)) return AppException('errors.$key');
      }
      if (message.contains('age_below_minimum')) return AppException('errors.age_below_minimum', namedArgs: {'n': error.hint ?? '18'});
      if (message.contains('birth_date_invalid')) return const AppException('errors.birth_date_invalid');
    }
    return const AppException('auth.errors.generic');
  }

  @override
  String toString() => messageKey;
}