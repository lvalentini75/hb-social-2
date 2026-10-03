import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

/// Avatar entry point of the shell. While there is no backend the avatar is
/// always in its guest state (person icon + "Ospite" label).
class AccountMenuButton extends ConsumerWidget {
  final double avatarSize;

  const AccountMenuButton({super.key, this.avatarSize = 36});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authStateProvider).isAuthenticated;
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
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              HBAvatar(avatarSize: HBAvatarSize.sm, isGuest: !isAuthenticated),
              const SizedBox(width: AppSpacing.sm),
              Text('nav.guest'.tr(), style: context.textStyles.titleSmall?.withColor(LightModeColors.lightOnSurface)),
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
      child: HBAvatar(size: avatarSize, isGuest: !isAuthenticated),
    );
  }
}
