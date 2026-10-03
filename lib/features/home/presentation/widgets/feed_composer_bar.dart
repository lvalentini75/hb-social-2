import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/composer_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_card.dart';

/// Web-only composer row at the top of the feed. It never edits anything
/// inline: tapping the field or one of its actions opens the composer
/// placeholder (see P09). On mobile the composer disappears; only the FAB
/// in the bottom nav remains.
class FeedComposerBar extends StatelessWidget {
  const FeedComposerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return HBCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              const HBAvatar(avatarSize: HBAvatarSize.md, isGuest: true),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Material(
                  color: LightModeColors.lightBackgroundSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: () => showComposerSheet(context),
                    child: Container(
                      height: 44,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(
                        'home.composer_placeholder'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _ComposerAction(icon: Icons.photo_library_outlined, label: 'home.composer_photo_video'.tr(), onTap: () => showComposerSheet(context)),
              ),
              Expanded(
                child: _ComposerAction(icon: Icons.place_outlined, label: 'home.composer_checkin'.tr(), onTap: () => showComposerSheet(context)),
              ),
              Expanded(
                child: _ComposerAction(icon: Icons.sell_outlined, label: 'home.composer_sell'.tr(), onTap: () => showComposerSheet(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ComposerAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: LightModeColors.lightOnSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelMedium?.withColor(LightModeColors.lightOnSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
