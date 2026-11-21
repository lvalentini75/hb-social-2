import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/composer/presentation/composer_sheet.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/features/stories/presentation/story_composer.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/providers/platform_providers.dart';
import 'package:intl/intl.dart';

enum CreateContentType { post, story, reel, live, sighting, listing }

Future<void> showCreateMenu(BuildContext context) async {
  final mobile = MediaQuery.sizeOf(context).width < 700;
  final selected = mobile
      ? await showModalBottomSheet<CreateContentType>(context: context, useSafeArea: true, showDragHandle: true, builder: (_) => const CreateContentMenu())
      : await showDialog<CreateContentType>(context: context, builder: (_) => const Dialog(child: SizedBox(width: 360, child: CreateContentMenu())));
  if (!context.mounted || selected == null) return;
  if (selected == CreateContentType.listing) { context.push(AppRoutes.marketplaceNew); return; }
  if (selected == CreateContentType.sighting) { context.push(AppRoutes.sightingsNew); return; }
  if (selected == CreateContentType.reel) { context.push(AppRoutes.reelsNew); return; }
  if (selected == CreateContentType.live) { context.push(AppRoutes.liveNew); return; }
  if (selected == CreateContentType.story) await showStoryComposer(context); else await showComposerSheet(context);
}

Future<void> showComposerSheet(BuildContext context, {String? initialText, String? initialLocationName, double? initialLatitude, double? initialLongitude, PreparedUpload? initialMedia, bool initialCheckin = false, String? locationPrivacyNoteKey}) async {
  final container = ProviderScope.containerOf(context);
  if (container.read(supabaseClientProvider).auth.currentUser == null) {
    context.go(AppRoutes.login);
    return;
  }
  final mobile = MediaQuery.sizeOf(context).width < 700;
  final composer = ComposerSheet(initialText: initialText, initialLocationName: initialLocationName, initialLatitude: initialLatitude, initialLongitude: initialLongitude, initialMedia: initialMedia, initialCheckin: initialCheckin, locationPrivacyNoteKey: locationPrivacyNoteKey);
  final result = mobile
      ? await showModalBottomSheet<Object?>(context: context, useRootNavigator: true, isScrollControlled: true, isDismissible: false, enableDrag: false, useSafeArea: true, backgroundColor: Colors.transparent, builder: (_) => FractionallySizedBox(heightFactor: 1, child: composer))
      : await showDialog<Object?>(context: context, useRootNavigator: true, barrierDismissible: false, builder: (dialogContext) => Dialog(clipBehavior: Clip.antiAlias, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 600, maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.85), child: composer)));
  if (context.mounted) _showComposerResult(context, result);
}

Future<void> showGroupComposerSheet(BuildContext context, {required String groupId, required String groupName, required String groupVisibility}) async {
  final container = ProviderScope.containerOf(context);
  if (container.read(supabaseClientProvider).auth.currentUser == null) { context.go(AppRoutes.login); return; }
  final composer = ComposerSheet(groupId: groupId, groupName: groupName, groupVisibility: groupVisibility);
  final mobile = MediaQuery.sizeOf(context).width < 700;
  final result = mobile
      ? await showModalBottomSheet<Object?>(context: context, useRootNavigator: true, isScrollControlled: true, isDismissible: false, enableDrag: false, useSafeArea: true, backgroundColor: Colors.transparent, builder: (_) => FractionallySizedBox(heightFactor: 1, child: composer))
      : await showDialog<Object?>(context: context, useRootNavigator: true, barrierDismissible: false, builder: (dialogContext) => Dialog(clipBehavior: Clip.antiAlias, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 600, maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.85), child: composer)));
  if (context.mounted) _showComposerResult(context, result);
}

Future<void> showPageComposerSheet(BuildContext context, {required String pageId, required String pageName, String? pageAvatarUrl}) async {
  final container = ProviderScope.containerOf(context);
  if (container.read(supabaseClientProvider).auth.currentUser == null) { context.go(AppRoutes.login); return; }
  final composer = ComposerSheet(pageId: pageId, pageName: pageName, pageAvatarUrl: pageAvatarUrl);
  final mobile = MediaQuery.sizeOf(context).width < 700;
  final result = mobile
      ? await showModalBottomSheet<Object?>(context: context, useRootNavigator: true, isScrollControlled: true, isDismissible: false, enableDrag: false, useSafeArea: true, backgroundColor: Colors.transparent, builder: (_) => FractionallySizedBox(heightFactor: 1, child: composer))
      : await showDialog<Object?>(context: context, useRootNavigator: true, barrierDismissible: false, builder: (dialogContext) => Dialog(clipBehavior: Clip.antiAlias, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 600, maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.85), child: composer)));
  if (context.mounted) _showComposerResult(context, result, pageId: pageId);
}

void _showComposerResult(BuildContext context, Object? result, {String? pageId}) {
  if (result == true) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ComposerSheet.publishedMessage(context))));
  } else if (result is DateTime) {
    final label = DateFormat.yMd(context.locale.toString()).add_Hm().format(result);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('composer.schedule.success'.tr(namedArgs: {'date': label})), action: SnackBarAction(label: 'composer.schedule.view'.tr(), onPressed: () => context.push(AppRoutes.scheduledPostsPath(pageId: pageId)))));
  }
}

class CreateContentMenu extends ConsumerWidget {
  const CreateContentMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('create_menu.title'.tr(), style: context.textStyles.titleLarge),
      const SizedBox(height: AppSpacing.md),
      HBButton.soft(label: 'create_menu.post'.tr(), icon: Icons.edit_outlined, onPressed: () => context.pop(CreateContentType.post)),
      const SizedBox(height: AppSpacing.sm),
      HBButton.soft(label: 'create_menu.story'.tr(), icon: Icons.auto_stories_outlined, onPressed: () => context.pop(CreateContentType.story)),
      if (ref.watch(featureFlagsProvider).value?['reels'] == true) ...[const SizedBox(height: AppSpacing.sm), HBButton.soft(label: 'reels.create'.tr(), icon: Icons.video_collection_outlined, onPressed: () => context.pop(CreateContentType.reel))],
      if (ref.watch(featureFlagsProvider).value?['live'] == true) ...[const SizedBox(height: AppSpacing.sm), HBButton.soft(label: 'live.create'.tr(), icon: Icons.live_tv_outlined, onPressed: () => context.pop(CreateContentType.live))],
      const SizedBox(height: AppSpacing.sm),
      HBButton.soft(label: 'sightings.actions.add'.tr(), icon: Icons.visibility_outlined, onPressed: () => context.pop(CreateContentType.sighting)),
      const SizedBox(height: AppSpacing.sm),
      HBButton.soft(label: 'marketplace.sell'.tr(), icon: Icons.sell_outlined, onPressed: () => context.pop(CreateContentType.listing)),
    ]),
  );
}
