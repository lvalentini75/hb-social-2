import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/composer_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';

/// PD4 composer card. On web the action row uses the four accent colours;
/// on mobile the same row stays monochrome with three actions.
class FeedComposerBar extends ConsumerWidget {
  const FeedComposerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;
    final radius = compact ? AppRadius.cardMobile : AppRadius.cardWeb;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: LightModeColors.surface, borderRadius: BorderRadius.circular(radius), boxShadow: AppShadows.card),
      child: Column(children: [
        Row(children: [
          HBAvatar(name: profile?.displayName ?? '', imageUrl: profile?.avatarUrl, size: compact ? 44 : 48, isGuest: profile == null),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Material(
            color: LightModeColors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () => showComposerSheet(context),
              child: Container(
                height: compact ? 48 : 56,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(compact ? 'home.composer_placeholder_mobile'.tr() : 'home.composer_placeholder_web'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body.withColor(LightModeColors.textSecondary)),
              ),
            ),
          )),
        ]),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: compact ? 44 : 48,
          child: compact
              ? Row(children: [
                  Expanded(child: ComposerAction(icon: Icons.photo_library_outlined, label: 'home.composer_photo_video'.tr(), iconSize: 20, onTap: () => showComposerSheet(context))),
                  const ComposerActionDivider(),
                  Expanded(child: ComposerAction(icon: Icons.place_outlined, label: 'home.composer_checkin'.tr(), iconSize: 20, onTap: () => showComposerSheet(context))),
                  const ComposerActionDivider(),
                  Expanded(child: ComposerAction(icon: Icons.sell_outlined, label: 'home.composer_sell'.tr(), iconSize: 20, onTap: () => showComposerSheet(context))),
                ])
              : Row(children: [
                  Expanded(child: ComposerAction(icon: Icons.photo_library_outlined, label: 'home.composer_photo_video'.tr(), color: LightModeColors.accentGreen, onTap: () => showComposerSheet(context))),
                  const ComposerActionDivider(),
                  Expanded(child: ComposerAction(icon: Icons.place_outlined, label: 'home.composer_checkin'.tr(), color: LightModeColors.accentBlue, onTap: () => showComposerSheet(context))),
                  const ComposerActionDivider(),
                  Expanded(child: ComposerAction(icon: Icons.bar_chart_rounded, label: 'home.composer_poll'.tr(), color: LightModeColors.accentOrange, onTap: () => showComposerSheet(context))),
                  const ComposerActionDivider(),
                  Expanded(child: ComposerAction(icon: Icons.calendar_today_outlined, label: 'home.composer_event'.tr(), color: LightModeColors.accentPurple, onTap: () => showComposerSheet(context))),
                  const ComposerActionDivider(),
                  Expanded(child: ComposerAction(icon: Icons.more_horiz_rounded, label: 'nav.more'.tr(), onTap: () => showCreateMenu(context))),
                ]),
        ),
      ]),
    );
  }
}

class ComposerActionDivider extends StatelessWidget {
  const ComposerActionDivider({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(width: 1, height: 24, child: ColoredBox(color: LightModeColors.divider));
}

class ComposerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final double iconSize;
  final VoidCallback onTap;

  const ComposerAction({super.key, required this.icon, required this.label, required this.onTap, this.color, this.iconSize = 22});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(AppRadius.nav),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.nav),
      onTap: onTap,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: iconSize, color: color ?? LightModeColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: (color == null ? AppText.label : AppText.ui).withColor(LightModeColors.text))),
      ]),
    ),
  );
}
