import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/empty_state.dart';
import 'package:hb_social/features/auth/providers/user_providers.dart';
import 'package:hb_social/features/profile/presentation/widgets/profile_header.dart';
import 'package:hb_social/features/profile/presentation/widgets/profile_tabs.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
      clipBehavior: Clip.antiAlias,
      child: user == null
          ? Center(
              child: EmptyState(
                icon: Icons.person_outline_rounded,
                title: 'profile.not_available_title'.tr(),
                message: 'profile.not_available_subtitle'.tr(),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileHeader(user: user),
                  const SizedBox(height: AppSpacing.md),
                  ProfileTabs(user: user),
                ],
              ),
            ),
    );
  }
}
