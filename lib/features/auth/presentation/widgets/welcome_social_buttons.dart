import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hb_social/core/config/auth_config.dart';
import 'package:hb_social/core/providers/platform_providers.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

class WelcomeSocialButtons extends ConsumerStatefulWidget {
  final bool showDivider;
  const WelcomeSocialButtons({super.key, this.showDivider = true});
  @override ConsumerState<WelcomeSocialButtons> createState() => _WelcomeSocialButtonsState();
}

class _WelcomeSocialButtonsState extends ConsumerState<WelcomeSocialButtons> {
  String? loadingProvider;
  @override Widget build(BuildContext context) => ref.watch(platformConfigProvider).when(
    loading: () => const SizedBox(height: 44, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
    error: (_, __) => const SizedBox.shrink(),
    data: (platform) {
      final providers = platform.auth.order.where((provider) => AuthConfig.isProviderVisible(platform.auth, provider)).toList();
      if (providers.isEmpty) return const SizedBox.shrink();
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (widget.showDivider) ...[Row(children: [const Expanded(child: Divider(color: LightModeColors.lightDivider)), Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), child: Text('auth.social.or'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightTextTertiary))), const Expanded(child: Divider(color: LightModeColors.lightDivider))]), const SizedBox(height: AppSpacing.md)],
        for (var index = 0; index < providers.length; index++) ...[
          SizedBox(width: double.infinity, child: HBButton.secondary(label: 'auth.social.continue_with.${providers[index]}'.tr(), leading: FaIcon(_icon(providers[index]), size: 18, color: providers[index] == 'apple' ? LightModeColors.surface : _color(providers[index])), isLoading: loadingProvider == providers[index], backgroundColor: providers[index] == 'apple' ? LightModeColors.brandApple : LightModeColors.surface, foregroundColor: providers[index] == 'apple' ? LightModeColors.surface : LightModeColors.text, onPressed: loadingProvider == null ? () => _signIn(providers[index], platform.auth.providers[providers[index]]?.nativeIos == true) : null)),
          if (index != providers.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ]);
    },
  );

  Future<void> _signIn(String provider, bool nativeApple) async {
    setState(() => loadingProvider = provider);
    try { await ref.read(authRepositoryProvider).signInWithProvider(provider, nativeApple: nativeApple); }
    on AppException catch (error) { if (mounted && error.messageKey != 'auth.cancelled') ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: {'provider': 'auth.social.provider.$provider'.tr()})))); }
    finally { if (mounted) setState(() => loadingProvider = null); }
  }

  FaIconData _icon(String provider) => switch (provider) { 'google' => FontAwesomeIcons.google!, 'apple' => FontAwesomeIcons.apple!, 'facebook' => FontAwesomeIcons.facebook!, 'azure' => FontAwesomeIcons.microsoft!, _ => FontAwesomeIcons.rightToBracket! };
  Color _color(String provider) => switch (provider) { 'google' => LightModeColors.brandGoogle, 'facebook' => LightModeColors.brandFacebook, 'azure' => LightModeColors.brandMicrosoft, _ => LightModeColors.text };
}
