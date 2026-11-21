import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_highlight_text.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';
import 'package:hb_social/features/search/domain/search_result.dart';
import 'package:hb_social/features/search/providers/search_providers.dart';
import 'package:hb_social/features/notifications/providers/notification_providers.dart';
import 'package:hb_social/features/chat/providers/chat_providers.dart';
import 'package:hb_social/shell/widgets/account_menu_button.dart';

/// PD4 web top bar: 64 px tall, page-coloured, wordmark on the left, the
/// 520×44 search pill in the middle and the notification/chat/account cluster
/// on the right.
class AppHeader extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppHeader({super.key, required this.currentIndex, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    height: AppBreakpoints.headerHeight,
    color: LightModeColors.pageWeb,
    padding: const EdgeInsets.symmetric(horizontal: AppBreakpoints.pageGutter),
    child: Row(children: [
      const SizedBox(width: AppBreakpoints.sidebarWidth, child: HeaderWordmark()),
      Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: const GlobalSearchBar()))),
      const SizedBox(width: AppSpacing.lg),
      HeaderIconButton(icon: Icons.notifications_none_rounded, badgeCount: ref.watch(unreadNotificationCountProvider).value ?? 0, onTap: () => onDestinationSelected(AppRoutes.branchIndexOf(AppRoutes.notifications)!)),
      const SizedBox(width: AppSpacing.sm),
      HeaderIconButton(icon: Icons.chat_bubble_outline_rounded, badgeCount: ref.watch(unreadConversationsCountProvider).value ?? 0, onTap: () => onDestinationSelected(AppRoutes.branchIndexOf(AppRoutes.messages)!)),
      const SizedBox(width: AppSpacing.md),
      const AccountMenuButton(showName: true),
    ]),
  );
}

/// Bosco square + "Social" wordmark + tagline, used by the web top bar.
class HeaderWordmark extends StatelessWidget {
  const HeaderWordmark({super.key});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    const HbLogo(size: 44),
    const SizedBox(width: AppSpacing.sm),
    Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('app.wordmark'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.heading.withColor(LightModeColors.text)),
      Text('app.tagline'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.small.withColor(LightModeColors.textSecondary)),
    ])),
  ]);
}

/// Round 40 px white button with an optional danger counter badge.
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const HeaderIconButton({super.key, required this.icon, required this.onTap, this.badgeCount = 0});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40, height: 40,
    child: Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(child: Material(color: LightModeColors.surface, shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Icon(icon, size: 20, color: LightModeColors.text)))),
      if (badgeCount > 0) Positioned(right: -4, top: -4, child: Container(
        width: 18, height: 18, alignment: Alignment.center,
        decoration: const BoxDecoration(color: LightModeColors.danger, shape: BoxShape.circle),
        child: Text(badgeCount > 99 ? '99+' : '$badgeCount', style: appFont(11, FontWeight.w700, color: Colors.white)),
      )),
    ]),
  );
}

class GlobalSearchBar extends ConsumerStatefulWidget {
  const GlobalSearchBar({super.key});

  @override
  ConsumerState<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends ConsumerState<GlobalSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _link = LayerLink();
  final _fieldKey = GlobalKey();
  Timer? _debounce;
  OverlayEntry? _overlay;
  SearchOverview? _overview;
  bool _loading = false;
  int _selected = -1;

  List<SearchPreview> get _items => [for (final category in SearchCategory.values) ...?_overview?.sections[category]];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) return;
      if (_controller.text.trim().length >= 2) _showOverlay();
    });
  }

  @override
  void dispose() {
    _overlay?.remove();
    _debounce?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _selected = -1;
    if (value.trim().length < 2) {
      _overview = null;
      _closeOverlay(unfocus: false);
      return;
    }
    _loading = true;
    _showOverlay();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final result = await ref.read(searchRepositoryProvider).searchAll(value, limit: 3);
        if (!mounted || value != _controller.text) return;
        _overview = result;
      } catch (_) {
        if (!mounted || value != _controller.text) return;
        _overview = const SearchOverview({});
      } finally {
        if (mounted && value == _controller.text) {
          _loading = false;
          _overlay?.markNeedsBuild();
        }
      }
    });
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _closeOverlay();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown && _items.isNotEmpty) {
      _selected = (_selected + 1).clamp(0, _items.length - 1);
      _overlay?.markNeedsBuild();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp && _items.isNotEmpty) {
      _selected = (_selected - 1).clamp(-1, _items.length - 1);
      _overlay?.markNeedsBuild();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_selected >= 0 && _selected < _items.length) {
        _open(_items[_selected]);
      } else {
        _openAll();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _showOverlay() {
    if (_overlay != null || !_focusNode.hasFocus) return;
    _overlay = OverlayEntry(builder: (context) {
      final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
      final width = box?.size.width ?? 560;
      return Stack(children: [
        Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _closeOverlay)),
        CompositedTransformFollower(
          link: _link, showWhenUnlinked: false, targetAnchor: Alignment.bottomLeft, followerAnchor: Alignment.topLeft, offset: const Offset(0, AppSpacing.xs),
          child: SizedBox(width: width, child: Material(color: Colors.transparent, child: HBCard(shadow: AppShadows.card, radius: AppRadius.inner, child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 420), child: _panel(context))))),
        ),
      ]);
    });
    Overlay.of(context).insert(_overlay!);
  }

  Widget _panel(BuildContext context) {
    if (_loading) return const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: LinearProgressIndicator(minHeight: 2));
    final overview = _overview;
    if (overview == null || overview.isEmpty) return Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text('search.empty_title'.tr(), style: AppText.label.withColor(LightModeColors.textSecondary)));
    var flatIndex = 0;
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final category in SearchCategory.values.where((item) => item != SearchCategory.all && overview.total(item) > 0)) ...[
          Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs), child: Text('${_categoryLabel(category)} · ${overview.total(category)}', style: AppText.caption.withColor(LightModeColors.textSecondary))),
          for (final item in overview.sections[category] ?? const []) _HeaderResultRow(query: _controller.text, item: item, selected: _selected == flatIndex++, onTap: () => _open(item)),
        ],
        const Divider(height: 1, color: LightModeColors.divider),
        InkWell(onTap: _openAll, child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Text('search.see_all_query'.tr(namedArgs: {'query': _controller.text.trim()}), textAlign: TextAlign.center, style: AppText.buttonLg.withColor(LightModeColors.bosco)))),
      ]),
    );
  }

  void _openAll() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    _closeOverlay();
    context.go('${AppRoutes.search}?q=${Uri.encodeQueryComponent(query)}');
    if (query.length >= 2) ref.read(recentSearchesProvider.notifier).add(query);
  }

  void _open(SearchPreview item) {
    final path = _previewPath(item);
    _closeOverlay();
    if (path != null) context.push(path);
  }

  void _closeOverlay({bool unfocus = true}) {
    _overlay?.remove();
    _overlay = null;
    if (unfocus) _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
    link: _link,
    child: Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): const _FocusSearchIntent(),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): const _FocusSearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{_FocusSearchIntent: CallbackAction<_FocusSearchIntent>(onInvoke: (_) { _focusNode.requestFocus(); return null; })},
        child: Focus(
          onKeyEvent: _key,
          child: SizedBox(
            height: 44,
            child: TextField(
              key: _fieldKey, controller: _controller, focusNode: _focusNode, onChanged: _changed, onSubmitted: (_) => _openAll(), style: AppText.body.withColor(LightModeColors.text),
              decoration: InputDecoration(
                hintText: 'common.search_hint'.tr(), hintStyle: AppText.body.withColor(LightModeColors.textSecondary),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: LightModeColors.textSecondary),
                suffixIcon: Padding(padding: const EdgeInsets.only(right: AppSpacing.sm), child: Center(widthFactor: 1, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(color: LightModeColors.surfaceSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Text('common.shortcut_search'.tr(), style: AppText.small.withColor(LightModeColors.textSecondary)),
                ))),
                filled: true, fillColor: LightModeColors.surface, isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _HeaderResultRow extends StatelessWidget {
  final String query;
  final SearchPreview item;
  final bool selected;
  final VoidCallback onTap;

  const _HeaderResultRow({required this.query, required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? LightModeColors.boscoTint : Colors.transparent,
    child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm), child: Row(children: [
      HBAvatar(name: item.title, imageUrl: item.imageUrl, size: 32), const SizedBox(width: AppSpacing.sm),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HBHighlightText(text: item.title, query: query, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.copyWith(fontWeight: FontWeight.w600, color: LightModeColors.text)),
        if (item.subtitle?.isNotEmpty == true) HBHighlightText(text: item.subtitle!, query: query, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.withColor(LightModeColors.textSecondary)),
      ])),
    ]))),
  );
}

String _categoryLabel(SearchCategory category) => switch (category) {
  SearchCategory.people => 'search.category_people'.tr(), SearchCategory.posts => 'search.category_posts'.tr(), SearchCategory.hashtags => 'search.category_hashtags'.tr(),
  SearchCategory.groups => 'search.category_groups'.tr(), SearchCategory.pages => 'search.category_pages'.tr(), SearchCategory.listings => 'search.category_listings'.tr(),
  SearchCategory.events => 'search.category_events'.tr(), SearchCategory.forum => 'search.category_forum'.tr(), SearchCategory.all => 'search.category_all'.tr(),
};

String? _previewPath(SearchPreview item) => switch (item.category) {
  SearchCategory.people when item.slug != null => AppRoutes.publicProfilePath(item.slug!), SearchCategory.posts => AppRoutes.postPath(item.id),
  SearchCategory.hashtags => AppRoutes.tagPath((item.slug ?? item.title).replaceFirst('#', '')), SearchCategory.groups => AppRoutes.groupDetailPath(item.id),
  SearchCategory.pages when item.slug != null => AppRoutes.pageDetailPath(item.slug!), SearchCategory.listings => AppRoutes.marketplaceDetailPath(item.id),
  SearchCategory.events => AppRoutes.eventDetailPath(item.id), SearchCategory.forum when item.extra['forum_slug'] != null => AppRoutes.threadPath(item.extra['forum_slug'] as String, item.id), _ => null,
};
