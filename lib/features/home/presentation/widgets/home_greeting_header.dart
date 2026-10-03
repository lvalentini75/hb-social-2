import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

/// Time-based greeting ("Buongiorno" / "Buon pomeriggio" / "Buonasera") with
/// a locale-aware date and a link to set the hunting zone until one exists.
/// There is no user display name in [AuthState] yet, so the greeting never
/// fabricates a ", {nome}" suffix — it will be added once auth is real.
class HomeGreetingHeader extends ConsumerWidget {
  final bool showAvatar;

  const HomeGreetingHeader({super.key, this.showAvatar = false});

  String get _greetingKey {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'home.greeting_morning';
    if (hour < 18) return 'home.greeting_afternoon';
    return 'home.greeting_evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authStateProvider).isAuthenticated;
    final settings = ref.watch(userSettingsProvider);
    final dateText = DateFormat.MMMMEEEEd(context.locale.languageCode).format(DateTime.now());

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_greetingKey.tr(), style: context.textStyles.headlineSmall),
        const SizedBox(height: 2),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('$dateText · ', style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
            GestureDetector(
              onTap: () => context.go(AppRoutes.huntingZone),
              child: Text(
                settings.countryCode == null
                    ? 'home.set_zone_link'.tr()
                    : 'hunting.country_region_unset'.tr(namedArgs: {'country': 'zone.country_${settings.countryCode!.toLowerCase()}'.tr()}),
                style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightForest).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );

    if (!showAvatar) return content;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: content),
        const SizedBox(width: AppSpacing.md),
        HBAvatar(size: 44, isGuest: !isAuthenticated, onTap: () => context.go(AppRoutes.profile)),
      ],
    );
  }
}
