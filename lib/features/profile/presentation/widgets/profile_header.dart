import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/user_avatar.dart';
import 'package:hb_social/features/auth/domain/app_user.dart';

/// Cover photo, overlapping avatar, name, handle, bio and the three
/// follower/following/post counters shown at the top of the Profile screen.
class ProfileHeader extends StatelessWidget {
  final AppUser user;

  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
              ),
            ),
            Positioned(
              left: AppSpacing.lg,
              bottom: -40,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: UserAvatar(name: user.name, radius: 44),
              ),
            ),
          ],
        ),
        const SizedBox(height: 52),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: context.textStyles.titleLarge),
              const SizedBox(height: 2),
              Text('@${user.username}', style: context.textStyles.bodyMedium?.withColor(colors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                user.bio.isEmpty ? 'profile.bio_placeholder'.tr() : user.bio,
                style: context.textStyles.bodyMedium?.withColor(
                  user.bio.isEmpty ? colors.onSurfaceVariant : LightModeColors.lightOnSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  _Counter(value: user.followersCount, label: 'profile.followers'.tr()),
                  const SizedBox(width: AppSpacing.xl),
                  _Counter(value: user.followingCount, label: 'profile.following'.tr()),
                  const SizedBox(width: AppSpacing.xl),
                  _Counter(value: user.postsCount, label: 'profile.posts'.tr()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  final int value;
  final String label;

  const _Counter({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value', style: context.textStyles.titleMedium),
        Text(label, style: context.textStyles.bodySmall?.withColor(colors.onSurfaceVariant)),
      ],
    );
  }
}
