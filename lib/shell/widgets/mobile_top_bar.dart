import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/chat/providers/chat_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';

/// PD4 mobile top bar: 56 px, no shadow and no divider. Wordmark on the left,
/// search + chat round buttons and the account avatar on the right.
class MobileTopBar extends ConsumerWidget {
  final ValueChanged<int> onDestinationSelected;

  const MobileTopBar({super.key, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final isAuthenticated = ref.watch(authSessionProvider).value != null;
    return Container(
      height: AppBreakpoints.mobileHeaderHeight,
      color: LightModeColors.pageMobile,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(children: [
        const HbLogo(size: 40),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text('app.name'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: appFont(20, FontWeight.w700, spacing: -0.4, color: LightModeColors.text))),
        const Spacer(),
        MobileTopBarButton(icon: Icons.search_rounded, onTap: () => context.go('${AppRoutes.search}?focus=1')),
        const SizedBox(width: AppSpacing.sm),
        MobileTopBarButton(icon: Icons.chat_bubble_outline_rounded, hasDot: (ref.watch(unreadConversationsCountProvider).value ?? 0) > 0, onTap: () => onDestinationSelected(AppRoutes.branchIndexOf(AppRoutes.messages)!)),
        const SizedBox(width: AppSpacing.sm),
        HBAvatar(size: 40, isGuest: !isAuthenticated, name: profile?.displayName, imageUrl: profile?.avatarUrl, onTap: () => context.go(isAuthenticated ? AppRoutes.profile : AppRoutes.login)),
      ]),
    );
  }
}

/// Round 44 px soft button with an optional 8 px danger dot.
class MobileTopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hasDot;

  const MobileTopBarButton({super.key, required this.icon, required this.onTap, this.hasDot = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44, height: 44,
    child: Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(child: Material(color: LightModeColors.surfaceSoft, shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Icon(icon, size: 22, color: LightModeColors.text)))),
      if (hasDot) Positioned(right: 4, top: 4, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: LightModeColors.danger, shape: BoxShape.circle, border: Border.all(color: LightModeColors.surface, width: 2)))),
    ]),
  );
}
