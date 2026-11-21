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
import 'package:hb_social/features/profile/presentation/public_profile_page.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final String? initialTab;
  const ProfilePage({super.key, this.initialTab});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  int _tabIndex = 0;
  bool _routeTabApplied = false;

  @override
  void initState() { super.initState(); if (widget.initialTab == 'albums') _tabIndex = 1; }

  @override
  Widget build(BuildContext context) {
    if (!_routeTabApplied) { _routeTabApplied = true; if (widget.initialTab == 'albums' || GoRouterState.of(context).uri.queryParameters['tab'] == 'albums') _tabIndex = 1; }
    final session = ref.watch(authSessionProvider);
    if (session.isLoading) return const PageColumns(center: Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.lg), child: ProfileSkeleton()));
    if (session.value == null) return const SignedOutProfileState();

    return ref.watch(currentProfileProvider).when(
      loading: () => const PageColumns(center: Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.lg), child: ProfileSkeleton())),
      error: (error, stackTrace) => PageColumns(
        center: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: HBCard(
            child: HBEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'profile.error_title'.tr(),
              message: 'profile.error_message'.tr(),
              action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(currentProfileProvider)),
            ),
          ),
        ),
      ),
      data: (profile) => profile == null
          ? PageColumns(
              center: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: HBCard(child: HBEmptyState(icon: Icons.person_outline_rounded, title: 'profile.empty_title'.tr(), message: 'profile.empty_message'.tr())),
              ),
            )
          : ProfileBody(username: profile.username, user: profile, tabIndex: _tabIndex, onTabChanged: (index) => setState(() => _tabIndex = index)),
    );
  }
}

class SignedOutProfileState extends StatelessWidget {
  const SignedOutProfileState({super.key});

  @override
  Widget build(BuildContext context) => PageColumns(
    center: CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: HBCard(
              child: HBEmptyState(
                icon: Icons.person_outline_rounded,
                title: 'profile.signed_out_title'.tr(),
                message: 'profile.signed_out_message'.tr(),
                action: HBButton.primary(label: 'profile.signed_out_cta'.tr(), onPressed: () => context.go(AppRoutes.login)),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}