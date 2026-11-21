import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/features/feed/domain/reaction.dart';
import 'package:hb_social/features/feed/providers/reaction_providers.dart';

Future<void> showReactionsSheet(BuildContext context, String postId) {
  final content = ReactionsSheet(postId: postId);
  if (MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile) return showDialog(context: context, builder: (_) => Dialog(child: SizedBox(width: 520, height: 600, child: content)));
  return showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => SizedBox(height: MediaQuery.sizeOf(context).height * .8, child: content));
}

class ReactionsSheet extends ConsumerStatefulWidget {
  final String postId;

  const ReactionsSheet({super.key, required this.postId});

  @override
  ConsumerState<ReactionsSheet> createState() => _ReactionsSheetState();
}

class _ReactionsSheetState extends ConsumerState<ReactionsSheet> {
  int _tab = 0;
  bool _loading = true;
  List<PostReaction> _items = [];
  PageCursor? _cursor;

  ReactionType? get _type => _tab == 0 ? null : ReactionType.values[_tab - 1];

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    setState(() => _loading = true);
    final page = await ref.read(reactionRepositoryProvider).fetch(postId: widget.postId, type: _type, cursor: reset ? null : _cursor);
    if (!mounted) return;
    setState(() { _items = reset ? page.items : [..._items, ...page.items]; _cursor = page.nextCursor; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('reactions.title'.tr(), style: context.textStyles.titleLarge),
      const SizedBox(height: AppSpacing.md),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: 700, child: HBSegmentedTabs(labels: ['reactions.all'.tr(), ...ReactionType.values.map((type) => type.labelKey.tr())], selectedIndex: _tab, onChanged: (index) { setState(() => _tab = index); _load(reset: true); }))),
      const SizedBox(height: AppSpacing.md),
      Expanded(
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? HBEmptyState(icon: Icons.thumb_up_alt_outlined, title: 'reactions.empty'.tr(), message: 'reactions.empty_message'.tr())
                : ListView(children: [
                    for (final item in _items) ListTile(
                      leading: HBAvatar(name: item.user.displayName, imageUrl: item.user.avatarUrl, size: 40),
                      title: Text(item.user.displayName),
                      subtitle: Text(item.type.labelKey.tr()),
                      trailing: Icon(item.type.icon, color: item.type.color),
                    ),
                    if (_cursor != null) HBButton.secondary(label: 'notifications.load_more'.tr(), onPressed: () => _load(reset: false)),
                  ]),
      ),
    ]),
  );
}