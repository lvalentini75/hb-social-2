import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/features/onboarding/domain/suggestion.dart';
import 'package:hb_social/features/social_graph/presentation/widgets/follow_button.dart';
import 'package:hb_social/features/social_graph/providers/social_graph_providers.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/core/services/realtime_service.dart';

class PeopleSuggestionsPage extends ConsumerStatefulWidget {
  const PeopleSuggestionsPage({super.key});

  @override
  ConsumerState<PeopleSuggestionsPage> createState() => _PeopleSuggestionsPageState();
}

class _PeopleSuggestionsPageState extends ConsumerState<PeopleSuggestionsPage> {
  final Set<String> _hidden = {};

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(peopleSuggestionsProvider);
    return CustomScrollView(slivers: [
      SliverPadding(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md), sliver: SliverToBoxAdapter(child: Text('people.title'.tr(), style: context.textStyles.headlineSmall))),
      value.when(
        loading: () => const SliverPadding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg), sliver: SliverToBoxAdapter(child: HBListSkeleton(count: 4))),
        error: (_, __) => SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'people.error'.tr(), message: 'connections.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(peopleSuggestionsProvider))))),
        ),
        data: (allItems) {
          final items = allItems.where((item) => !_hidden.contains(item.id)).toList();
          if (items.isEmpty) return SliverPadding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), sliver: SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.people_outline, title: 'people.empty_title'.tr(), message: 'people.empty_message'.tr(), action: HBButton.soft(label: 'people.interests_cta'.tr(), onPressed: () => context.go('${AppRoutes.onboarding}?edit=interests'))))));
          return SliverPadding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), sliver: SliverLayoutBuilder(builder: (context, constraints) {
            final columns = MediaQuery.sizeOf(context).width >= 900 ? 3 : 1;
            return SliverGrid.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, mainAxisExtent: columns == 1 ? 190 : 280), itemCount: items.length, itemBuilder: (_, index) => SuggestedPersonCard(profile: items[index], onHide: () => setState(() => _hidden.add(items[index].id))));
          }));
        },
      ),
      const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
    ]);
  }
}

class SuggestedPersonCard extends ConsumerStatefulWidget {
  final SuggestedProfile profile;
  final VoidCallback onHide;

  const SuggestedPersonCard({super.key, required this.profile, required this.onHide});

  @override
  ConsumerState<SuggestedPersonCard> createState() => _SuggestedPersonCardState();
}

class _SuggestedPersonCardState extends ConsumerState<SuggestedPersonCard> {
  bool _sent = false;
  bool _loading = false;

  Future<void> _send() async {
    setState(() => _loading = true);
    try {
      await ref.read(socialGraphRepositoryProvider).sendRequest(widget.profile.id, null);
      ref.invalidate(peopleSuggestionsProvider);
      setState(() => _sent = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final authenticated = ref.watch(authSessionProvider).value != null;
    final online = authenticated && (ref.watch(onlineUsersProvider).value?.contains(profile.id) ?? false);
    final reasons = <String>[
      if (profile.mutualFriends > 0) 'people.mutual_friends'.tr(namedArgs: {'n': '${profile.mutualFriends}'}),
      if (profile.sharedInterests > 0) 'people.shared_interests'.tr(namedArgs: {'n': '${profile.sharedInterests}'}),
      if (profile.sameRegion) 'people.same_region'.tr(),
    ].take(2).toList();
    return HBCard(child: Stack(children: [
      Positioned(right: -8, top: -8, child: HBButton.icon(icon: Icons.close_rounded, size: HBButtonSize.sm, onPressed: widget.onHide)),
      InkWell(onTap: () => context.push(AppRoutes.publicProfilePath(profile.username)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        HBAvatar(name: profile.displayName, imageUrl: profile.avatarUrl, size: 64, showPresence: online), const SizedBox(height: AppSpacing.sm),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Flexible(child: Text(profile.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium)), if (profile.verificationLevel != 'none') ...[const SizedBox(width: 4), HBBadge.verification(level: profile.verificationLevel, verifiedAt: profile.verifiedAt)]]),
        Text('@${profile.username}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
        if (reasons.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 4, children: [for (final reason in reasons) HBChip(label: reason, selected: false)])],
        const SizedBox(height: AppSpacing.md),
        Wrap(alignment: WrapAlignment.center, spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [FollowButton(userId: profile.id, username: profile.username, size: HBButtonSize.sm), HBButton.soft(label: (_sent ? 'friendship.sent' : 'friendship.add').tr(), size: HBButtonSize.sm, isLoading: _loading, onPressed: _sent || _loading ? null : _send)]),
      ])),
    ]));
  }
}