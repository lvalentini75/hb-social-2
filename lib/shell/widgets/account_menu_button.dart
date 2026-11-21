import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/notifications/providers/notification_providers.dart';

/// Avatar entry point of the shell, backed by the authenticated profile.
class AccountMenuButton extends ConsumerWidget {
  final double avatarSize;
  final bool showName;

  const AccountMenuButton({super.key, this.avatarSize = 36, this.showName = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).value;
    final isAuthenticated = session != null;
    final profile = ref.watch(currentProfileProvider).value;
    final displayName = profile?.displayName;
    return PopupMenuButton<String>(
      tooltip: 'nav.account_menu'.tr(),
      offset: const Offset(0, 48),
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 'profile') {
          context.go(AppRoutes.profile);
          return;
        }
        if (value == 'settings') context.go(AppRoutes.settings);
        if (value == 'billing') context.go(AppRoutes.billing);
        if (value == 'ads') context.go(AppRoutes.ads);
        if (value == 'scheduled') context.go(AppRoutes.scheduledPosts);
        if (value == 'download') context.go(AppRoutes.download);
        if (value == 'logout') () async {
          await ref.read(pushNotificationServiceProvider).unregisterCurrentDevice();
          await ref.read(authRepositoryProvider).signOut();
          if (context.mounted) context.go(AppRoutes.welcome);
        }();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
               HBAvatar(avatarSize: HBAvatarSize.sm, isGuest: !isAuthenticated, name: displayName, imageUrl: profile?.avatarUrl),
              const SizedBox(width: AppSpacing.sm),
                Text(displayName ?? (isAuthenticated ? session?.user.email ?? 'nav.account_menu'.tr() : 'nav.guest'.tr()), overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall?.withColor(LightModeColors.lightOnSurface)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 20, color: LightModeColors.lightOnSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text('nav.profile'.tr(), style: context.textStyles.bodyMedium),
            ],
          ),
        ),
        if (isAuthenticated) PopupMenuItem<String>(value: 'billing', child: Row(children: [const Icon(Icons.credit_card_outlined, size: 20, color: LightModeColors.lightOnSurfaceVariant), const SizedBox(width: AppSpacing.sm), Text('billing.settings_entry'.tr(), style: context.textStyles.bodyMedium)])),
        if (isAuthenticated) PopupMenuItem<String>(value: 'ads', child: Row(children: [const Icon(Icons.campaign_outlined, size: 20, color: LightModeColors.lightOnSurfaceVariant), const SizedBox(width: AppSpacing.sm), Text('ads.center.title'.tr(), style: context.textStyles.bodyMedium)])),
        if (isAuthenticated) PopupMenuItem<String>(value: 'scheduled', child: Row(children: [const Icon(Icons.schedule_outlined, size: 20, color: LightModeColors.lightOnSurfaceVariant), const SizedBox(width: AppSpacing.sm), Text('posts.scheduled.title'.tr(), style: context.textStyles.bodyMedium)])),
        if (kIsWeb) PopupMenuItem<String>(value: 'download', child: Row(children: [const Icon(Icons.download_outlined, size: 20, color: LightModeColors.lightOnSurfaceVariant), const SizedBox(width: AppSpacing.sm), Text('download.title'.tr(), style: context.textStyles.bodyMedium)])),
        if (isAuthenticated) PopupMenuItem<String>(value: 'logout', child: Row(children: [const Icon(Icons.logout_rounded, size: 20, color: LightModeColors.lightOnSurfaceVariant), const SizedBox(width: AppSpacing.sm), Text('auth.logout'.tr(), style: context.textStyles.bodyMedium)])),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
           value: 'settings',
           child: Row(children: [
             const Icon(Icons.settings_outlined, size: 20, color: LightModeColors.lightOnSurfaceVariant),
             const SizedBox(width: AppSpacing.sm),
             Text('settings.title'.tr(), style: context.textStyles.bodyMedium),
           ]),
        ),
      ],
      child: showName
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              HBAvatar(size: avatarSize, isGuest: !isAuthenticated, name: displayName, imageUrl: profile?.avatarUrl),
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(displayName?.split(' ').first ?? 'nav.guest'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: appFont(15, FontWeight.w600, color: LightModeColors.text)),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: LightModeColors.textSecondary),
            ])
          : HBAvatar(size: avatarSize, isGuest: !isAuthenticated, name: displayName, imageUrl: profile?.avatarUrl),
    );
  }
}
