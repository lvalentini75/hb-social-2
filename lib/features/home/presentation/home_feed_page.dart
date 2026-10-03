import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/empty_state.dart';

/// The center feed column. No posts exist yet (no backend), so this is an
/// explicit empty state rather than any sample content.
class HomeFeedPage extends StatelessWidget {
  const HomeFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
      alignment: Alignment.center,
      child: EmptyState(
        icon: Icons.dynamic_feed_outlined,
        title: 'home.feed_empty_title'.tr(),
        message: 'home.feed_empty_subtitle'.tr(),
      ),
    );
  }
}
