import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';
import 'package:hb_social/core/widgets/user_avatar.dart';
import 'package:hb_social/features/auth/domain/app_user.dart';

/// 64px top header shown on wide (web) layouts: logo, centered pill search
/// bar, notifications, messages, the green "+ Crea" button and the avatar.
class AppHeader extends StatelessWidget {
  final AppUser? currentUser;

  const AppHeader({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: AppBreakpoints.headerHeight,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          const HbLogo(size: 36),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(color: LightModeColors.lightSurfaceVariant, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 20, color: LightModeColors.lightOnSurfaceVariant),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintText: 'common.search_hint'.tr(),
                            hintStyle: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          IconButton(
            onPressed: () => showComingSoon(context),
            icon: const Icon(Icons.notifications_none_rounded, color: LightModeColors.lightOnSurfaceVariant),
          ),
          IconButton(
            onPressed: () => showComingSoon(context),
            icon: const Icon(Icons.mail_outline_rounded, color: LightModeColors.lightOnSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: () => showComingSoon(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            label: Text('home.create_button'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: AppSpacing.md),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => context.go(AppRoutes.profile),
            child: UserAvatar(name: currentUser?.name, radius: 18),
          ),
        ],
      ),
    );
  }
}
