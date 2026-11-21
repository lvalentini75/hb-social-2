import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/diary/domain/diary_season.dart';
import 'package:hb_social/features/diary/domain/outing.dart';
import 'package:hb_social/features/diary/presentation/outing_card.dart';
import 'package:hb_social/features/diary/presentation/diary_stats_panel.dart';
import 'package:hb_social/features/diary/providers/diary_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/core/widgets/hb_page_header.dart';

class DiaryPage extends ConsumerStatefulWidget {
  final int initialTab;
  final String? initialSeason;
  const DiaryPage({super.key, this.initialTab = 0, this.initialSeason});
  @override
  ConsumerState<DiaryPage> createState() => _DiaryPageState();
}
class _DiaryPageState extends ConsumerState<DiaryPage> {
  String? _season;
  String? _unitFilter;
  int _tab = 0;
  bool _initialized = false;
  @override
  void initState() { super.initState(); _tab = widget.initialTab; _season = widget.initialSeason; _initialized = widget.initialSeason != null; }
  @override
  Widget build(BuildContext context) {
    final current = ref.watch(diaryCurrentSeasonProvider).value;
    if (!_initialized && current != null) { _season = current; _initialized = true; }
    final seasons = ref.watch(diarySeasonsProvider(null));
    final request = (userId: null as String?, season: _season);
    final outings = ref.watch(outingsProvider(request));
    final seasonRows = seasons.value ?? const <DiarySeason>[];
    final selectedIndex = seasonRows.indexWhere((item) => item.seasonLabel == _season);
    final previousSeason = selectedIndex >= 0 && selectedIndex + 1 < seasonRows.length ? seasonRows[selectedIndex + 1].seasonLabel : null;
    final profile = ref.watch(currentProfileProvider).value;
    final regionName = profile?.homeRegionId == null ? '' : (ref.watch(regionsProvider(profile!.countryCode)).value ?? const []).where((item) => item.id == profile.homeRegionId).firstOrNull?.name ?? '';
    return PageColumns(center: LayoutBuilder(builder: (context, constraints) {
      final mobile = constraints.maxWidth < 700;
      return Stack(children: [CustomScrollView(slivers: [SliverPadding(padding: EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, mobile ? 96 : AppSpacing.xxl), sliver: SliverList.list(children: [
        HBPageHeader(title: 'diary.title'.tr(), subtitle: 'diary.subtitle'.tr(), action: mobile ? null : HBButton.primary(label: 'diary.record'.tr(), icon: Icons.add_rounded, onPressed: () => context.push(AppRoutes.diaryNew))),
        const SizedBox(height: AppSpacing.lg), Row(children: [DiarySeasonSelector(value: _season, seasons: seasonRows, onChanged: (value) => setState(() { _season = value; _unitFilter = null; })), const SizedBox(width: AppSpacing.md), Expanded(child: HBSegmentedTabs(labels: ['diary.tabs.outings'.tr(), 'diary.tabs.stats'.tr()], selectedIndex: _tab, onChanged: (value) => setState(() => _tab = value)))]),
        if (_tab == 0) ...[const SizedBox(height: AppSpacing.md), DiarySummary(season: seasons.value?.where((item) => item.seasonLabel == _season).firstOrNull), if (_unitFilter != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: HBChip(label: 'diary.stats.place_filter'.tr(), selected: true, icon: Icons.close_rounded, onTap: () => setState(() => _unitFilter = null)))],
        const SizedBox(height: AppSpacing.lg),
        if (_tab == 0) outings.when(loading: () => const HBListSkeleton(count: 4), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'diary.error_title'.tr(), message: 'diary.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(outingsProvider(request))))), data: (state) => DiaryGroupedList(items: _unitFilter == null ? state.items : state.items.where((item) => item.unitId == _unitFilter).toList(), onLoadMore: state.hasMore ? () => ref.read(outingsProvider(request).notifier).loadMore() : null, loadingMore: state.loadingMore)) else DiaryStatsPanel(season: _season, previousSeason: previousSeason, owner: true, profile: profile, regionName: regionName, onPlaceSelected: (unitId) => setState(() { _unitFilter = unitId; _tab = 0; })),
      ]))]), if (mobile) Positioned(right: AppSpacing.md, bottom: AppSpacing.lg, child: HBButton.primary(label: 'diary.record'.tr(), icon: Icons.add_rounded, onPressed: () => context.push(AppRoutes.diaryNew)))]);
    }));
  }
}

class DiarySeasonSelector extends StatelessWidget {
  final String? value; final List<DiarySeason> seasons; final ValueChanged<String?> onChanged;
  const DiarySeasonSelector({super.key, required this.value, required this.seasons, required this.onChanged});
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(onSelected: (selected) => onChanged(selected == '__all__' ? null : selected), itemBuilder: (_) => [PopupMenuItem(value: '__all__', child: Text('diary.all_seasons'.tr())), for (final season in seasons) PopupMenuItem(value: season.seasonLabel, child: Text(season.seasonLabel))], child: HBChip(label: value ?? 'diary.all_seasons'.tr(), selected: true, icon: Icons.expand_more_rounded));
}

class DiarySummary extends StatelessWidget {
  final DiarySeason? season;
  const DiarySummary({super.key, this.season});
  @override
  Widget build(BuildContext context) => Text('diary.list_summary'.tr(namedArgs: {'outings': '${season?.outings ?? 0}', 'harvests': '${season?.harvests ?? 0}'}), style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600));
}

class DiaryGroupedList extends ConsumerWidget {
  final List<Outing> items; final VoidCallback? onLoadMore; final bool loadingMore;
  const DiaryGroupedList({super.key, required this.items, this.onLoadMore, required this.loadingMore});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.menu_book_outlined, title: 'diary.empty_title'.tr(), message: 'diary.empty_message'.tr(), action: HBButton.primary(label: 'diary.first_outing'.tr(), onPressed: () => context.push(AppRoutes.diaryNew))));
    final urls = ref.watch(diaryCoversProvider(items));
    String? previous;
    final children = <Widget>[];
    for (final outing in items) {
      final month = DateFormat.yMMMM(context.locale.languageCode).format(outing.startedAt.toLocal());
      if (previous != month) { previous = month; children.add(Padding(padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm), child: Text(month, style: context.textStyles.titleMedium))); }
      children.add(Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: OutingCard(outing: outing, coverUrl: urls.value?[outing.coverThumbnailPath ?? outing.coverPath])));
    }
    if (onLoadMore != null) children.add(Center(child: HBButton.secondary(label: loadingMore ? 'common.loading'.tr() : 'feed.load_more'.tr(), onPressed: loadingMore ? null : onLoadMore)));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
