import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/groups/domain/group.dart';
import 'package:hb_social/features/groups/providers/group_providers.dart';

/// Group detail screen: cover, avatar, name, public/private status, member
/// count, join/share actions and a Discussione/Membri/Eventi/Info segmented
/// view. [debugPreview] (only reachable from `/dev/design-system`) renders
/// the full layout with every field null, shown as "—", instead of calling
/// the repository.
class GroupDetailPage extends ConsumerStatefulWidget {
  final String groupId;
  final bool debugPreview;

  const GroupDetailPage({super.key, required this.groupId, this.debugPreview = false});

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  int _tabIndex = 0;

  void _onTabChanged(int index) => setState(() => _tabIndex = index);

  @override
  Widget build(BuildContext context) {
    if (widget.debugPreview) {
      return _GroupDetailBody(group: null, tabIndex: _tabIndex, onTabChanged: _onTabChanged);
    }

    final groupAsync = ref.watch(groupByIdProvider(widget.groupId));
    return groupAsync.when(
      loading: () => const PageColumns(center: Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: CircularProgressIndicator()))),
      error: (error, stackTrace) => PageColumns(
        center: HBCard(
          child: HBEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'groups.error_title'.tr(),
            message: 'groups.error_message'.tr(),
            action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(groupByIdProvider(widget.groupId))),
          ),
        ),
      ),
      data: (group) {
        if (group == null) {
          return PageColumns(
            center: HBCard(
              child: HBEmptyState(icon: Icons.groups_2_outlined, title: 'groups.not_found_title'.tr(), message: 'groups.not_found_message'.tr()),
            ),
          );
        }
        return _GroupDetailBody(group: group, tabIndex: _tabIndex, onTabChanged: _onTabChanged);
      },
    );
  }
}

class _GroupDetailBody extends StatelessWidget {
  final Group? group;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  const _GroupDetailBody({required this.group, required this.tabIndex, required this.onTabChanged});

  void _showSoon(BuildContext context, String sectionKey) => showComingSoonInfo(
    context,
    icon: Icons.groups_2_outlined,
    title: 'common.coming_soon_title'.tr(),
    message: 'common.coming_soon_message'.tr(namedArgs: {'section': sectionKey.tr()}),
  );

  @override
  Widget build(BuildContext context) {
    final secondaryStyle = context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant);

    return PageColumns(
      rail: Column(
        children: [
          PageRailCard(label: 'groups.rail_why_title'.tr(), child: Text('groups.rail_why_message'.tr(), style: secondaryStyle)),
          const SizedBox(height: AppSpacing.md),
          PageRailCard(label: 'groups.rail_activity_title'.tr(), child: Text('groups.rail_activity_empty'.tr(), style: secondaryStyle)),
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
                          Container(height: 220, width: double.infinity, color: LightModeColors.lightBackgroundSoft),
                          Positioned(
                            left: AppSpacing.lg,
                            bottom: -36,
                            child: HBAvatar(name: group?.name, size: 72, ringColor: Colors.white),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 44, AppSpacing.lg, AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group?.name ?? '—',
                              style: context.textStyles.headlineSmall?.copyWith(fontSize: 26, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                HBStatusChip(
                                  kind: group == null ? HBStatusKind.neutral : (group!.isPublic ? HBStatusKind.info : HBStatusKind.neutral),
                                  label: group == null ? '—' : (group!.isPublic ? 'groups.badge_public'.tr() : 'groups.badge_private'.tr()),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  group == null ? '—' : 'groups.member_count'.tr(namedArgs: {'count': '${group!.memberCount}'}),
                                  style: secondaryStyle,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                HBButton.primary(label: 'groups.join'.tr(), onPressed: () => _showSoon(context, 'groups.join')),
                                const SizedBox(width: AppSpacing.sm),
                                HBButton.secondary(label: 'groups.share'.tr(), onPressed: () => _showSoon(context, 'groups.share')),
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
                  labels: ['groups.tab_discussion'.tr(), 'groups.tab_members'.tr(), 'groups.tab_events'.tr(), 'groups.tab_info'.tr()],
                  selectedIndex: tabIndex,
                  onChanged: onTabChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                _GroupTabContent(tabIndex: tabIndex, group: group, secondaryStyle: secondaryStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTabContent extends StatelessWidget {
  final int tabIndex;
  final Group? group;
  final TextStyle? secondaryStyle;

  const _GroupTabContent({required this.tabIndex, required this.group, required this.secondaryStyle});

  @override
  Widget build(BuildContext context) {
    switch (tabIndex) {
      case 0:
        return HBCard(
          child: HBEmptyState(icon: Icons.forum_outlined, title: 'groups.tab_discussion_empty_title'.tr(), message: 'groups.tab_discussion_empty_message'.tr()),
        );
      case 1:
        return HBCard(
          child: HBEmptyState(icon: Icons.people_outline_rounded, title: 'groups.tab_members_empty_title'.tr(), message: 'groups.tab_members_empty_message'.tr()),
        );
      case 2:
        return HBCard(
          child: HBEmptyState(icon: Icons.event_outlined, title: 'groups.tab_events_empty_title'.tr(), message: 'groups.tab_events_empty_message'.tr()),
        );
      default:
        final createdAt = group?.createdAt;
        return HBCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'groups.info_description'.tr(), value: group?.description ?? '—'),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(label: 'groups.info_country'.tr(), value: group?.countryCode ?? '—'),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(
                label: 'groups.info_created'.tr(),
                value: createdAt == null ? '—' : '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}',
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
          width: 140,
          child: Text(label, style: context.textStyles.labelMedium?.withColor(LightModeColors.lightTextTertiary)),
        ),
        Expanded(child: Text(value, style: context.textStyles.bodyMedium)),
      ],
    );
  }
}
