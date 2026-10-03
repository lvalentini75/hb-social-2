import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';

/// Google / Apple / Facebook sign-in buttons. Since the backend is not
/// connected yet, tapping any of them simply informs the user instead of
/// simulating a real sign-in.
class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({super.key});

  void _notComingYet(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('welcome.social_coming_soon'.tr())));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: 'welcome.social_google'.tr(),
            icon: Icons.g_mobiledata_rounded,
            onTap: () => _notComingYet(context),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SocialButton(
            label: 'welcome.social_apple'.tr(),
            icon: Icons.apple_rounded,
            onTap: () => _notComingYet(context),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SocialButton(
            label: 'welcome.social_facebook'.tr(),
            icon: Icons.facebook_rounded,
            onTap: () => _notComingYet(context),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: AppShadows.card,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: LightModeColors.lightOnSurface),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelLarge?.withColor(LightModeColors.lightOnSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
