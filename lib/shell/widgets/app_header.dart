import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/composer_sheet.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';
import 'package:hb_social/shell/widgets/account_menu_button.dart';

/// 64px top header on wide layouts: brand mark + wordmark, a centered pill
/// search field with a "⌘K" shortcut hint, notifications, messages, the
/// create button and the account menu.
class AppHeader extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppHeader({super.key, required this.currentIndex, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppBreakpoints.headerHeight,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          const HbLogo(size: 32),
          const SizedBox(width: AppSpacing.sm),
          Text('app.wordmark'.tr(), style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _HeaderSearchField(onTap: () => onDestinationSelected(AppRoutes.branchIndexOf(AppRoutes.search)!)),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          _HeaderIconButton(icon: Icons.notifications_none_rounded, onTap: () => onDestinationSelected(AppRoutes.branchIndexOf(AppRoutes.notifications)!)),
          const SizedBox(width: AppSpacing.xs),
          _HeaderIconButton(icon: Icons.chat_bubble_outline_rounded, onTap: () => onDestinationSelected(AppRoutes.branchIndexOf(AppRoutes.messages)!)),
          const SizedBox(width: AppSpacing.sm),
          HBButton.primary(label: 'nav.create'.tr(), icon: Icons.add_rounded, onPressed: () => showComposerSheet(context)),
          const SizedBox(width: AppSpacing.md),
          const AccountMenuButton(),
        ],
      ),
    );
  }
}

/// 40px round soft icon container used for the header's secondary actions.
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: LightModeColors.lightBackgroundSoft,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, size: 20, color: LightModeColors.lightOnSurfaceVariant),
        ),
      ),
    );
  }
}

class _HeaderSearchField extends StatelessWidget {
  final VoidCallback onTap;

  const _HeaderSearchField({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LightModeColors.lightBackgroundSoft,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 20, color: LightModeColors.lightOnSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'common.search_hint'.tr(),
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.xs)),
                child: Text('common.shortcut_search'.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
