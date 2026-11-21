import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/onboarding/presentation/widgets/onboarding_step_header.dart';
import 'package:hb_social/features/onboarding/presentation/widgets/step_age.dart';
import 'package:hb_social/features/onboarding/presentation/widgets/step_follow.dart';
import 'package:hb_social/features/onboarding/presentation/widgets/step_interests.dart';
import 'package:hb_social/features/onboarding/presentation/widgets/step_region.dart';
import 'package:hb_social/features/onboarding/providers/onboarding_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/settings/providers/settings_providers.dart';
import 'package:hb_social/features/social_graph/providers/social_graph_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  final bool interestsOnly;
  const OnboardingPage({super.key, this.interestsOnly = false});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0;
  DateTime? _birthDate;
  String? _regionId;
  String _countryCode = 'IT';
  Set<String> _interests = {};
  bool _loading = true;
  bool _saving = false;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initialize);
  }

  Future<void> _initialize() async {
    try {
      final settings = await ref.read(privateUserSettingsProvider.future);
      final profile = await ref.read(currentProfileProvider.future);
      final interests = await ref.read(interestsRepositoryProvider).getMine();
      if (profile == null) {
        if (mounted) context.go(AppRoutes.login);
        return;
      }
      _birthDate = settings?.birthDate;
      _regionId = profile.homeRegionId;
      _countryCode = profile.countryCode;
      _interests = interests.toSet();
      _step = widget.interestsOnly ? 2 : (_birthDate == null ? 0 : (_regionId == null ? 1 : (_interests.isEmpty ? 2 : 3)));
    } on AppException catch (error) {
      _error = error;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continue() async {
    setState(() { _saving = true; _error = null; });
    try {
      if (_step == 0) {
        if (_birthDate == null) return;
        await ref.read(userSettingsRepositoryProvider).updateMine(birthDate: _birthDate);
        ref.invalidate(privateUserSettingsProvider);
        _step = 1;
      } else if (_step == 1) {
        if (_regionId == null) return;
        await ref.read(settingsSaveProvider.notifier).save({'home_region_id': _regionId});
        _step = 2;
      } else if (_step == 2) {
        if (_interests.isEmpty) return;
        await ref.read(interestsRepositoryProvider).replaceMine(_interests.toList()..sort());
        ref.invalidate(peopleSuggestionsProvider);
        if (widget.interestsOnly) {
          if (mounted) context.go(AppRoutes.settings);
          return;
        }
        ref.invalidate(suggestedProfilesProvider);
        ref.invalidate(suggestedGroupsProvider);
        _step = 3;
      } else {
        await ref.read(userSettingsRepositoryProvider).updateMine(onboardingCompletedAt: DateTime.now().toUtc());
        ref.invalidate(privateUserSettingsProvider);
        if (mounted) context.go(AppRoutes.home);
        return;
      }
    } on AppException catch (error) {
      if (_step == 0 && (error.messageKey == 'errors.age_below_minimum' || error.messageKey == 'errors.birth_date_invalid')) {
        if (mounted) await showDialog<void>(context: context, barrierDismissible: false, builder: (dialogContext) => AlertDialog(content: Text(error.messageKey.tr(namedArgs: error.namedArgs)), actions: [HBButton.primary(label: 'common.back'.tr(), onPressed: () => dialogContext.pop())]));
        await ref.read(authRepositoryProvider).signOut();
        if (mounted) context.go(AppRoutes.welcome);
        return;
      }
      _error = error;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleInterest(String slug) {
    final updated = {..._interests};
    if (updated.contains(slug)) {
      updated.remove(slug);
    } else if (updated.length < 8) {
      updated.add(slug);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('onboarding.interests_max'.tr())));
    }
    setState(() => _interests = updated);
  }

  bool get _canContinue => !_saving && switch (_step) { 0 => _birthDate != null, 1 => _regionId != null, 2 => _interests.isNotEmpty, _ => true };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null && _step == 0 && _birthDate == null) return Scaffold(body: HBEmptyState(icon: Icons.error_outline, title: 'onboarding.load_error_title'.tr(), message: _error!.messageKey.tr(namedArgs: _error!.namedArgs), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () { setState(() => _loading = true); _initialize(); })));
    final titleKey = switch (_step) { 0 => 'onboarding.age_title', 1 => 'onboarding.region_title', 2 => 'onboarding.interests_title', _ => 'onboarding.follow_title' };
    final subtitleKey = switch (_step) { 0 => 'onboarding.age_subtitle', 1 => 'onboarding.region_subtitle', 2 => 'onboarding.interests_subtitle', _ => 'onboarding.follow_subtitle' };
    final content = switch (_step) {
      0 => StepAge(birthDate: _birthDate, onChanged: (value) => setState(() => _birthDate = value)),
      1 => StepRegion(countryCode: _countryCode, regionId: _regionId, onChanged: (value) => setState(() => _regionId = value)),
      2 => StepInterests(selected: _interests, onToggle: _toggleInterest),
      _ => const StepFollow(),
    };
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(AppSpacing.sm), child: Center(child: HbLogo(size: 32))),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            OnboardingStepHeader(step: widget.interestsOnly ? 0 : _step, total: widget.interestsOnly ? 1 : 4, title: titleKey.tr(), subtitle: subtitleKey.tr()),
                            const SizedBox(height: AppSpacing.xl),
                            content,
                            if (_error != null) ...[const SizedBox(height: AppSpacing.md), Text(_error!.messageKey.tr(namedArgs: _error!.namedArgs), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))],
                            const SizedBox(height: AppSpacing.xxl),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: HBButton.primary(label: (_step == 3 || widget.interestsOnly) ? 'common.finish'.tr() : 'common.next'.tr(), onPressed: _canContinue ? _continue : null, isLoading: _saving))),
          ],
        ),
      ),
    );
  }
}