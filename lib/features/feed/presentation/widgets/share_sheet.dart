import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:hb_social/features/feed/presentation/widgets/post_media_grid.dart';
import 'package:hb_social/features/home/providers/feed_providers.dart';

Future<void> showShareSheet(BuildContext context, FeedPost post, {String? initialText}) {
  final original = post.kind == 'share' ? post.sharedPost : post;
  if (original == null) return Future.value();
  final content = ShareSheet(post: original, initialText: initialText);
  if (MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile) return showDialog(context: context, builder: (_) => Dialog(child: SizedBox(width: 560, child: content)));
  return showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom), child: content));
}

class ShareSheet extends ConsumerStatefulWidget {
  final FeedPost post;
  final String? initialText;

  const ShareSheet({super.key, required this.post, this.initialText});

  @override
  ConsumerState<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<ShareSheet> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialText);
  bool _sharing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final url = Uri.base.resolve('/post/${widget.post.id}').toString();
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('share.link_copied'.tr())));
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await ref.read(feedRepositoryProvider).sharePost(widget.post.id, _controller.text);
      ref.invalidate(feedPostsProvider);
      ref.invalidate(followingFeedProvider);
      ref.invalidate(nearbyFeedProvider);
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('share.success'.tr())));
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('share.title'.tr(), style: context.textStyles.titleLarge),
      const SizedBox(height: AppSpacing.md),
      HBInput(controller: _controller, hint: 'share.comment_hint'.tr(), maxLength: 1000, maxLines: 4),
      const SizedBox(height: AppSpacing.md),
      CompactPostPreview(post: widget.post),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        Expanded(child: HBButton.secondary(label: 'share.copy_link'.tr(), icon: Icons.link_rounded, onPressed: _copy)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: HBButton.primary(label: 'share.to_feed'.tr(), icon: Icons.ios_share_rounded, onPressed: _share, isLoading: _sharing)),
      ]),
    ]),
  );
}

class CompactPostPreview extends StatelessWidget {
  final FeedPost post;

  const CompactPostPreview({super.key, required this.post});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
    child: Row(children: [
      HBAvatar(name: post.author.displayName, imageUrl: post.author.avatarUrl, size: 40),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(post.author.displayName, style: const TextStyle(fontWeight: FontWeight.w700)), if (post.content?.isNotEmpty ?? false) Text(post.content!, maxLines: 2, overflow: TextOverflow.ellipsis)])),
      if (post.media.isNotEmpty && post.media.first.kind != 'video') ...[const SizedBox(width: AppSpacing.sm), ClipRRect(borderRadius: BorderRadius.circular(AppRadius.xs), child: SizedBox(width: 64, height: 64, child: PostNetworkImage(media: post.media.first, onTap: () {})))],
    ]),
  );
}