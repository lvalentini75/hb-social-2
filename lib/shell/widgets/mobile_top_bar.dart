import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';

/// Compact top bar on narrow layouts: brand mark + wordmark, and three round
/// icon buttons (search, notifications, messages). The account avatar lives
/// in the home greeting row instead; language lives in the "Altro" sheet.
class MobileTopBar extends StatelessWidget {
  final ValueChanged<int> onDestinationSelected;

  const MobileTopBar({super.key, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppBreakpoints.headerHeight,
      color: LightModeColors.lightBackground,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          const HbLogo(size: 30),
          const SizedBox(width: AppSpacing.sm),
          Text('app.wordmark'.tr(), style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          _TopBarIconButton(
            icon: Icons.search_rounded,
            onTap: () => onDestinationSelected(AppRoutes.branchIndexOf(AppRoutes.search)!),
          ),
          const SizedBox(width: AppSpacing.sm),
          _TopBarIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: () => onDestinationSelected(AppRoutes.branchIndexOf(AppRoutes.notifications)!),
          ),
          const SizedBox(width: AppSpacing.sm),
          _TopBarIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () => onDestinationSelected(AppRoutes.branchIndexOf(AppRoutes.messages)!),
          ),
        ],
      ),
    );
  }
}

/// Round white 38px icon button with a level1 shadow.
class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: AppShadows.level1),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: LightModeColors.lightOnSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
