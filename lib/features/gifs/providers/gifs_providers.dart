import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/gifs/data/gifs_repository.dart';
import 'package:hb_social/core/services/app_exception.dart';

final gifsRepositoryProvider = Provider<GifsRepository>((ref) => GifsRepository(ref.watch(supabaseClientProvider)));
final gifsAvailableProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    await ref.watch(gifsRepositoryProvider).load(locale: 'it');
    return true;
  } on AppException catch (error) {
    return error.messageKey != 'gifs.errors.not_configured';
  }
});