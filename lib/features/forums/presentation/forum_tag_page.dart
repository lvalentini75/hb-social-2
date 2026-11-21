import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/forums/domain/forum_thread.dart';
import 'package:hb_social/features/forums/presentation/forums_page.dart';
import 'package:hb_social/features/forums/providers/forums_providers.dart';

class ForumTagPage extends ConsumerStatefulWidget {
  final String tag;
  const ForumTagPage({super.key, required this.tag});
  @override
  ConsumerState<ForumTagPage> createState() => _ForumTagPageState();
}

class _ForumTagPageState extends ConsumerState<ForumTagPage> {
  String _sort = 'activity';
  int _offset = 0;
  List<ForumThread> _items = const [];
  bool _loading = true;
  bool _hasMore = false;
  @override
  void initState() { super.initState(); Future.microtask(_load); }
  Future<void> _load({bool more = false}) async {
    setState(() => _loading = true);
    final page = await ref.read(forumsRepositoryProvider).fetchRecentThreads(countryCode: ref.read(userSettingsProvider).countryCode ?? 'IT', offset: more ? _offset : 0, tag: widget.tag, sort: _sort);
    if (!mounted) return;
    setState(() { _items = more ? [..._items, ...page.items] : page.items; _offset = _items.length; _hasMore = page.nextCursor != null; _loading = false; });
  }
  @override
  Widget build(BuildContext context) => PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
    Row(children: [Expanded(child: Text('forum_advanced.tags.page_title'.tr(namedArgs: {'tag': widget.tag, 'n': '${_items.length}'}), style: context.textStyles.headlineSmall)), PopupMenuButton<String>(initialValue: _sort, onSelected: (value) { _sort = value; _load(); }, itemBuilder: (_) => [for (final sort in const ['activity', 'views', 'replies', 'newest']) PopupMenuItem(value: sort, child: Text('forum_advanced.sort.$sort'.tr()))])]),
    const SizedBox(height: AppSpacing.md),
    if (_loading && _items.isEmpty) const HBListSkeleton() else if (_items.isEmpty) HBCard(child: HBEmptyState(icon: Icons.tag_rounded, title: 'forum_advanced.tags.empty'.tr(), message: 'forum_advanced.tags.empty_message'.tr())) else for (final item in _items) ...[RecentThreadCard(thread: item), const SizedBox(height: AppSpacing.sm)],
    if (_hasMore) HBButton.secondary(label: 'feed.load_more'.tr(), onPressed: _loading ? null : () => _load(more: true)),
  ]))]));
}