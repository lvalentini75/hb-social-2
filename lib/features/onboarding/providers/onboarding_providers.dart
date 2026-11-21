import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/onboarding/data/onboarding_repository.dart';
import 'package:hb_social/features/onboarding/domain/suggestion.dart';

/// In-memory state for the 3-step onboarding flow.
class OnboardingState {
  final int step;
  final String? countryCode;
  final String? regionCode;
  final Set<String> interestIds;

  const OnboardingState({this.step = 0, this.countryCode, this.regionCode, this.interestIds = const {}});

  OnboardingState copyWith({int? step, String? countryCode, String? regionCode, Set<String>? interestIds, bool clearRegion = false}) {
    return OnboardingState(
      step: step ?? this.step,
      countryCode: countryCode ?? this.countryCode,
      regionCode: clearRegion ? null : (regionCode ?? this.regionCode),
      interestIds: interestIds ?? this.interestIds,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void selectCountry(String code) => state = state.copyWith(countryCode: code, clearRegion: true);

  void selectRegion(String code) => state = state.copyWith(regionCode: code);

  void toggleInterest(String id) {
    final updated = {...state.interestIds};
    if (!updated.add(id)) updated.remove(id);
    state = state.copyWith(interestIds: updated);
  }

  void nextStep() => state = state.copyWith(step: state.step + 1);

  void previousStep() => state = state.copyWith(step: state.step - 1);

  void reset() => state = const OnboardingState();
}

final onboardingProvider = NotifierProvider.autoDispose<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);

final interestsRepositoryProvider = Provider<InterestsRepository>((ref) => InterestsRepository(ref.watch(supabaseClientProvider)));
final suggestionsRepositoryProvider = Provider<SuggestionsRepository>((ref) => SuggestionsRepository(ref.watch(supabaseClientProvider)));
final suggestedProfilesProvider = FutureProvider.autoDispose<List<SuggestedProfile>>((ref) => ref.watch(suggestionsRepositoryProvider).profiles());
final suggestedGroupsProvider = FutureProvider.autoDispose<List<SuggestedGroup>>((ref) => ref.watch(suggestionsRepositoryProvider).groups());
