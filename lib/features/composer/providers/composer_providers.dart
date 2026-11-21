import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/composer/data/composer_repository.dart';

final composerRepositoryProvider = Provider<ComposerRepository>((ref) => ComposerRepository(ref.watch(supabaseClientProvider)));