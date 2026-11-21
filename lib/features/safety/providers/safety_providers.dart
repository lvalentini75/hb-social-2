import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/safety/data/safety_repository.dart';
import 'package:hb_social/features/safety/domain/safety_user.dart';
import 'package:hb_social/features/safety/domain/country_safety_policy.dart';
import 'package:hb_social/features/safety/domain/user_strike.dart';
import 'package:hb_social/features/settings/providers/settings_providers.dart';

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) => SafetyRepository(ref.watch(supabaseClientProvider)));
final blockedUsersProvider = FutureProvider<List<SafetyUser>>((ref) => ref.watch(userSettingsRepositoryProvider).listBlocked());
final mutedUsersProvider = FutureProvider<List<SafetyUser>>((ref) => ref.watch(userSettingsRepositoryProvider).listMuted());
final countryPolicyProvider = FutureProvider.family<CountrySafetyPolicy, String>((ref, countryCode) => ref.watch(safetyRepositoryProvider).countryPolicy(countryCode));
final myStrikesProvider = FutureProvider<List<UserStrike>>((ref) => ref.watch(safetyRepositoryProvider).myStrikes());

/// Makes block removal immediate while RLS-backed providers reload.
final locallyBlockedUserIdsProvider = StateProvider<Set<String>>((ref) => const {});
final revealedSensitivePostsProvider = StateProvider<Set<String>>((ref) => const {});