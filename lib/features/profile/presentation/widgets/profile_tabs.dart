import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/empty_state.dart';
import 'package:hb_social/features/auth/domain/app_user.dart';
import 'package:hb_social/features/onboarding/domain/hunting_country.dart';
import 'package:hb_social/features/onboarding/domain/hunting_interest.dart';

/// Post / Media / Info tabs at the bottom of the Profile screen. Post and
/// Media are always empty (no posting flow exists yet); Info shows the real
/// onboarding selections, or an empty state if onboarding was never
/// completed.
class ProfileTabs extends StatelessWidget {
  final AppUser user;

  const ProfileTabs({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            indicatorColor: colors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            tabs: [
              Tab(text: 'profile.tab_posts'.tr()),
              Tab(text: 'profile.tab_media'.tr()),
              Tab(text: 'profile.tab_info'.tr()),
            ],
          ),
          const Divider(height: 1),
          SizedBox(
            height: 320,
            child: TabBarView(
              children: [
                EmptyState(icon: Icons.article_outlined, title: 'profile.posts_empty_title'.tr(), message: 'profile.posts_empty_subtitle'.tr()),
                EmptyState(icon: Icons.photo_library_outlined, title: 'profile.media_empty_title'.tr(), message: 'profile.media_empty_subtitle'.tr()),
                _InfoTab(user: user),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final AppUser user;

  const _InfoTab({required this.user});

  @override
  Widget build(BuildContext context) {
    if (!user.onboardingCompleted || user.countryCode == null) {
      return EmptyState(icon: Icons.info_outline_rounded, title: 'profile.info_empty_title'.tr(), message: 'profile.info_empty_subtitle'.tr());
    }
    final colors = Theme.of(context).colorScheme;
    final country = huntingCountries.where((c) => c.code == user.countryCode).toList();
    final countryLabel = country.isNotEmpty ? country.first.translationKey.tr() : user.countryCode!;
    final regionLabel = user.regionCode != null ? regionTranslationKey(user.regionCode!).tr() : null;
    final interestLabels = huntingInterests.where((i) => user.interestIds.contains(i.id)).map((i) => i.translationKey.tr()).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _InfoRow(label: 'profile.info_country'.tr(), value: countryLabel),
          if (regionLabel != null) ...[const SizedBox(height: AppSpacing.md), _InfoRow(label: 'profile.info_region'.tr(), value: regionLabel)],
          const SizedBox(height: AppSpacing.md),
          Text('profile.info_interests'.tr(), style: context.textStyles.labelLarge?.withColor(colors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xs),
          interestLabels.isEmpty
              ? Text('—', style: context.textStyles.bodyMedium)
              : Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: interestLabels
                      .map((label) => Chip(
                            label: Text(label),
                            backgroundColor: colors.primaryContainer,
                            labelStyle: context.textStyles.labelMedium?.withColor(colors.primary),
                            side: BorderSide.none,
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.textStyles.labelLarge?.withColor(colors.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: context.textStyles.bodyMedium),
      ],
    );
  }
}
