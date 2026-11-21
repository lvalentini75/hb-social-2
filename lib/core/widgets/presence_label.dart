import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/realtime_service.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

/// Displays live or recent activity for an authenticated viewer.
class PresenceLabel extends ConsumerWidget {
  final String userId;
  final DateTime? lastSeenAt;

  const PresenceLabel({super.key, required this.userId, this.lastSeenAt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authSessionProvider).value == null) return const SizedBox.shrink();
    final online = ref.watch(onlineUsersProvider).value?.contains(userId) ?? false;
    if (online) return Text('presence.online'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightSuccess));
    final seen = lastSeenAt;
    if (seen == null || DateTime.now().toUtc().difference(seen).inDays >= 7) return const SizedBox.shrink();
    return Text('presence.active'.tr(namedArgs: {'time': relativeTime(context, seen)}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant));
  }
}