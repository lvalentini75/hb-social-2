import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/features/calls/domain/call.dart';
import 'package:hb_social/features/calls/providers/calls_providers.dart';

class CallsPage extends ConsumerWidget {
  const CallsPage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => ListPageScaffold(title: 'calls.title'.tr(), body: ref.watch(callHistoryProvider).when(loading: () => const HBListSkeleton(), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'calls.error'.tr(), message: 'calls.error_message'.tr()), data: (items) => items.isEmpty ? HBEmptyState(icon: Icons.phone_outlined, title: 'calls.empty'.tr(), message: 'calls.empty_message'.tr()) : Column(children: [for (final item in items) CallHistoryTile(call: item)])));
}

class CallHistoryTile extends ConsumerWidget {
  final AppCall call;
  const CallHistoryTile({super.key, required this.call});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final missed = call.status == 'missed';
    return ListTile(leading: HBAvatar(name: call.peer.displayName, imageUrl: call.peer.avatarUrl), title: Text(call.peer.displayName), subtitle: Text('${'calls.status.${call.status}'.tr()} · ${relativeTime(context, call.createdAt)}', style: TextStyle(color: missed ? LightModeColors.danger : null)), trailing: Icon(call.kind == 'video' ? Icons.videocam_outlined : Icons.phone_outlined), onTap: () async {
      final next = await ref.read(callsRepositoryProvider).start(call.peer.id, call.kind);
      if (context.mounted) context.push(AppRoutes.callPath(next.id));
    });
  }
}