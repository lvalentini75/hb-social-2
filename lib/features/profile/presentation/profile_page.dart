import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

/// There is no authentication yet (see `docs/DECISIONS.md`): the Profile
/// destination always shows this explicit "sign in required" state with a
/// CTA to the sign-in screen, instead of any demo account.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authStateProvider).isAuthenticated;

    return PageColumns(
      center: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: HBCard(
                child: SizedBox(
                  width: double.infinity,
                  child: HBEmptyState(
                    icon: Icons.person_outline_rounded,
                    title: isAuthenticated ? 'profile.empty_title'.tr() : 'profile.signed_out_title'.tr(),
                    message: isAuthenticated ? 'profile.empty_message'.tr() : 'profile.signed_out_message'.tr(),
                    action: isAuthenticated
                        ? null
                        : HBButton.primary(label: 'profile.signed_out_cta'.tr(), onPressed: () => context.go(AppRoutes.login)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
