import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/notifications/providers/notification_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/safety/domain/user_strike.dart';
import 'package:hb_social/features/safety/providers/safety_providers.dart' as safety;

class SuspendedPage extends ConsumerWidget {
  const SuspendedPage({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(pushNotificationServiceProvider).unregisterCurrentDevice();
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banned = ref.watch(currentProfileProvider).value?.status == 'banned';
    final suspendedUntil = ref.watch(currentProfileProvider).value?.suspendedUntil;
    return Scaffold(
      backgroundColor: LightModeColors.lightBackground,
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: CustomScrollView(shrinkWrap: true, slivers: [SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList.list(children: [
            Center(child: Container(width: 64, height: 64, decoration: const BoxDecoration(color: LightModeColors.lightErrorContainer, shape: BoxShape.circle), child: const Center(child: HBBadge(kind: HBBadgeKind.error)))),
            const SizedBox(height: AppSpacing.md),
            Text((banned ? 'suspended.banned_title' : 'suspended.title').tr(), textAlign: TextAlign.center, style: context.textStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text('suspended.message'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
            if (!banned && suspendedUntil != null) ...[const SizedBox(height: AppSpacing.xs), Text('p41.suspended_until'.tr(namedArgs: {'date': DateFormat.yMMMd(context.locale.toString()).add_Hm().format(suspendedUntil.toLocal())}), textAlign: TextAlign.center, style: context.textStyles.bodyMedium?.bold)],
            const SizedBox(height: AppSpacing.lg),
            Text('strikes.active_title'.tr(), style: context.textStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ref.watch(safety.myStrikesProvider).when(
              loading: () => const HBCard(child: HBListSkeleton(count: 2, showTrailing: false)),
              error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'strikes.error_title'.tr(), message: 'strikes.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(safety.myStrikesProvider)))),
              data: (strikes) => strikes.isEmpty ? HBCard(child: StrikeFreeRow()) : HBCard(child: Column(children: [for (var index = 0; index < strikes.length; index++) ...[StrikeRow(strike: strikes[index]), if (index != strikes.length - 1) const Divider(height: 1, color: LightModeColors.lightDivider)]])),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(width: double.infinity, child: HBButton.primary(label: 'auth.logout'.tr(), onPressed: () => _signOut(context, ref))),
          ]),
        )]),
      ))),
    );
  }
}

class StrikeRow extends StatelessWidget {
  final UserStrike strike;

  const StrikeRow({super.key, required this.strike});

  @override
  Widget build(BuildContext context) {
    final expiry = strike.expiresAt == null ? null : DateFormat.yMMMd(context.locale.toString()).format(strike.expiresAt!.toLocal());
    return Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.warning_amber_rounded, color: LightModeColors.lightWarning),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('safety.reasons.${strike.reason}'.tr(), style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        Text(relativeTime(context, strike.createdAt), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
        if (expiry != null) Text('strikes.expires'.tr(namedArgs: {'date': expiry}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      ])),
    ]));
  }
}

class StrikeFreeRow extends StatelessWidget {
  const StrikeFreeRow({super.key});

  @override
  Widget build(BuildContext context) => Row(children: [const Icon(Icons.check_circle_rounded, color: LightModeColors.lightSuccess), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('strikes.none'.tr()))]);
}