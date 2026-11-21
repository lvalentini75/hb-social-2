import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/features/onboarding/providers/onboarding_providers.dart';
import 'package:hb_social/features/social_graph/presentation/widgets/follow_button.dart';

/// Onboarding step 3: people and groups to follow. There is no backend yet,
/// so this always shows the explicit empty state rather than fake
/// suggestions.
class StepFollow extends ConsumerWidget {
  const StepFollow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(suggestedProfilesProvider);
    final groups = ref.watch(suggestedGroupsProvider);
    if (profiles.isLoading || groups.isLoading) return const LinearProgressIndicator();
    if (profiles.hasError || groups.hasError) return HBEmptyState(icon: Icons.error_outline, title: 'onboarding.suggestions_error_title'.tr(), message: 'onboarding.suggestions_error_message'.tr());
    final profileItems = profiles.value ?? const [];
    final groupItems = groups.value ?? const [];
    if (profileItems.isEmpty && groupItems.isEmpty) return HBEmptyState(icon: Icons.group_add_outlined, title: 'onboarding.follow_empty_title'.tr(), message: 'onboarding.follow_empty_subtitle'.tr());
    return Column(
      children: [
        for (final profile in profileItems)
          HBCard(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [HBAvatar(name: profile.displayName, imageUrl: profile.avatarUrl, size: 44), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(profile.displayName, style: context.textStyles.titleSmall), Text(profile.sharedInterests > 0 ? 'onboarding.shared_interests'.tr(namedArgs: {'n': '${profile.sharedInterests}'}) : 'onboarding.same_region'.tr(), style: context.textStyles.bodySmall)])), FollowButton(userId: profile.id, username: profile.username, size: HBButtonSize.sm)])),
        if (profileItems.isNotEmpty && groupItems.isNotEmpty) const SizedBox(height: AppSpacing.md),
        for (final group in groupItems)
          HBCard(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [HBAvatar(name: group.name, imageUrl: group.avatarUrl, size: 44), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(group.name, style: context.textStyles.titleSmall), Text('groups.member_count'.plural(group.memberCount), style: context.textStyles.bodySmall)])), HBButton.soft(label: 'onboarding.view_group'.tr(), size: HBButtonSize.sm, onPressed: () => context.push(AppRoutes.groupDetailPath(group.slug)))])),
      ],
    );
  }
}
