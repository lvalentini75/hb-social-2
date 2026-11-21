import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/profile/providers/public_profile_providers.dart';
import 'package:hb_social/features/social_graph/providers/follow_providers.dart';
import 'package:hb_social/features/social_graph/providers/social_graph_providers.dart';

/// Reusable optimistic follow control for public profile summaries.
class FollowButton extends ConsumerStatefulWidget {
  final String userId;
  final String? username;
  final HBButtonSize size;

  const FollowButton({super.key, required this.userId, this.username, this.size = HBButtonSize.md});

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool? _optimistic;
  bool _loading = false;

  Future<void> _toggle(bool current) async {
    if (ref.read(authSessionProvider).value == null) {
      context.go(AppRoutes.login);
      return;
    }
    setState(() { _optimistic = !current; _loading = true; });
    try {
      final repository = ref.read(followRepositoryProvider);
      if (current) await repository.unfollow(widget.userId); else await repository.follow(widget.userId);
      ref.invalidate(isFollowingProvider(widget.userId));
      ref.invalidate(currentProfileProvider);
      ref.invalidate(relationshipProvider(widget.userId));
      ref.invalidate(peopleSuggestionsProvider);
      if (widget.username != null) ref.invalidate(publicProfileProvider(widget.username!));
    } catch (_) {
      if (mounted) setState(() => _optimistic = current);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(isFollowingProvider(widget.userId));
    final following = _optimistic ?? value.value ?? false;
    return following
        ? HBButton.soft(label: 'social.following'.tr(), onPressed: _loading ? null : () => _toggle(true), isLoading: _loading, size: widget.size)
        : HBButton.primary(label: 'social.follow'.tr(), onPressed: value.isLoading || _loading ? null : () => _toggle(false), isLoading: _loading, size: widget.size);
  }
}