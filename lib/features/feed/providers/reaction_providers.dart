import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/feed/data/reaction_repository.dart';

/// Reaction summaries are NOT exposed as a per-post provider: they travel with
/// the post model, loaded once per page via the `reactions_summary` RPC.
final reactionRepositoryProvider = Provider<ReactionRepository>((ref) => ReactionRepository(ref.watch(supabaseClientProvider)));