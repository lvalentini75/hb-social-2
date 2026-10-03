import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/features/profile/providers/public_profile_providers.dart';

/// Public profile at `/u/:username`, living inside the shell as part of the
/// Profile branch (no own Scaffold/AppBar). There is no profiles backend
/// yet, so every lookup resolves to "not found" rather than any sample
/// profile. [debugPreview] (only reachable from `/dev/design-system` in
/// debug mode) renders the full layout with every field null, shown as "—".
class PublicProfilePage extends ConsumerStatefulWidget {
  final String username;
  final bool debugPreview;

  const PublicProfilePage({super.key, required this.username, this.debugPreview = false});

  @override
  ConsumerState<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends ConsumerState<PublicProfilePage> {
  int _tabIndex = 0;

  void _onTabChanged(int index) => setState(() => _tabIndex = index);

  @override
  Widget build(BuildContext context) {
    if (widget.debugPreview) {
      return _ProfileBody(username: widget.username, user: null, tabIndex: _tabIndex, onTabChanged: _onTabChanged);
    }

    final profile = ref.watch(publicProfileProvider(widget.username));
    return profile.when(
      loading: () => const PageColumns(center: Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: CircularProgressIndicator()))),
      error: (error, stackTrace) => PageColumns(
        center: HBCard(
          child: HBEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'profile.error_title'.tr(),
            message: 'profile.error_message'.tr(),
            action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(publicProfileProvider(widget.username))),
          ),
        ),
      ),
      data: (user) {
        if (user == null) {
          return PageColumns(
            center: HBCard(
              child: HBEmptyState(icon: Icons.person_search_rounded, title: 'profile.not_found_title'.tr(), message: 'profile.not_found_message'.tr()),
            ),
          );
        }
        return _ProfileBody(username: widget.username, user: user, tabIndex: _tabIndex, onTabChanged: _onTabChanged);
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final String username;
  final UserProfile? user;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  const _ProfileBody({required this.username, required this.user, required this.tabIndex, required this.onTabChanged});

  void _showSoon(BuildContext context, String sectionKey) => showComingSoonInfo(
    context,
    icon: Icons.person_outline_rounded,
    title: 'common.coming_soon_title'.tr(),
    message: 'common.coming_soon_message'.tr(namedArgs: {'section': sectionKey.tr()}),
  );

  @override
  Widget build(BuildContext context) {
    final secondaryStyle = context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant);
    final displayName = user?.displayName;
    final memberSince = user?.createdAt;

    return PageColumns(
      rail: Column(
        children: [
          PageRailCard(
            label: 'profile.rail_info_title'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'profile.rail_info_country'.tr(), value: '—'),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(label: 'profile.rail_info_species'.tr(), value: '—'),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                  label: 'profile.rail_info_since'.tr(),
                  value: memberSince == null ? '—' : '${memberSince.day.toString().padLeft(2, '0')}/${memberSince.month.toString().padLeft(2, '0')}/${memberSince.year}',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PageRailCard(
            label: 'profile.rail_photos_title'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.xs,
                  crossAxisSpacing: AppSpacing.xs,
                  children: List.generate(
                    6,
                    (index) => DecoratedBox(decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.xs))),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('profile.rail_photos_empty'.tr(), style: secondaryStyle),
              ],
            ),
          ),
        ],
      ),
      center: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            sliver: SliverList.list(
              children: [
                HBCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(height: 200, width: double.infinity, color: LightModeColors.lightBackgroundSoft),
                          Positioned(
                            left: AppSpacing.lg,
                            bottom: -48,
                            child: HBAvatar(name: displayName, size: 96, ringColor: Colors.white),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 56, AppSpacing.lg, AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    (displayName == null || displayName.isEmpty) ? '—' : displayName,
                                    style: context.textStyles.headlineSmall?.copyWith(fontSize: 26, fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (user?.isVerified ?? false) ...[const SizedBox(width: AppSpacing.xs), const HBBadge(kind: HBBadgeKind.verified)],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('@$username', style: secondaryStyle),
                            if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(user!.bio!, style: context.textStyles.bodyMedium),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                _StatItem(label: 'profile.stat_posts'.tr(), value: user?.postCount),
                                const SizedBox(width: AppSpacing.lg),
                                _StatItem(label: 'profile.stat_followers'.tr(), value: user?.followerCount),
                                const SizedBox(width: AppSpacing.lg),
                                _StatItem(label: 'profile.stat_following'.tr(), value: user?.followingCount),
                                const SizedBox(width: AppSpacing.lg),
                                _StatItem(label: 'profile.stat_outings'.tr(), value: user?.outingsCount),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                HBButton.primary(label: 'profile.follow_cta'.tr(), onPressed: () => _showSoon(context, 'profile.follow_cta')),
                                const SizedBox(width: AppSpacing.sm),
                                HBButton.secondary(label: 'profile.message_cta'.tr(), onPressed: () => _showSoon(context, 'profile.message_cta')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                HBSegmentedTabs(
                  labels: ['profile.tab_posts'.tr(), 'profile.tab_media'.tr(), 'profile.tab_info'.tr(), 'profile.tab_dogs'.tr()],
                  selectedIndex: tabIndex,
                  onChanged: onTabChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                _ProfileTabContent(tabIndex: tabIndex, username: username, user: user),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int? value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value == null ? '—' : '$value', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      ],
    );
  }
}

class _ProfileTabContent extends StatelessWidget {
  final int tabIndex;
  final String username;
  final UserProfile? user;

  const _ProfileTabContent({required this.tabIndex, required this.username, required this.user});

  @override
  Widget build(BuildContext context) {
    switch (tabIndex) {
      case 0:
        return HBCard(child: HBEmptyState(icon: Icons.grid_on_outlined, title: 'profile.posts_empty_title'.tr(), message: 'profile.posts_empty_message'.tr()));
      case 1:
        return HBCard(child: HBEmptyState(icon: Icons.photo_library_outlined, title: 'profile.media_empty_title'.tr(), message: 'profile.media_empty_message'.tr()));
      case 3:
        return HBCard(child: HBEmptyState(icon: Icons.pets_outlined, title: 'profile.dogs_empty_title'.tr(), message: 'profile.dogs_empty_message'.tr()));
      default:
        final memberSince = user?.createdAt;
        return HBCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'profile.info_username_label'.tr(), value: '@$username'),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(label: 'profile.info_bio_label'.tr(), value: (user?.bio == null || user!.bio!.isEmpty) ? '—' : user!.bio!),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(
                label: 'profile.info_member_since_label'.tr(),
                value: memberSince == null ? '—' : '${memberSince.day.toString().padLeft(2, '0')}/${memberSince.month.toString().padLeft(2, '0')}/${memberSince.year}',
              ),
            ],
          ),
        );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: context.textStyles.labelMedium?.withColor(LightModeColors.lightTextTertiary)),
        ),
        Expanded(child: Text(value, style: context.textStyles.bodyMedium)),
      ],
    );
  }
}
