import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/empty_state.dart';

/// The 340px right rail on wide layouts. Explicitly empty for now — no
/// trending topics or suggestions are faked here.
class RightRail extends StatelessWidget {
  const RightRail({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
        child: EmptyState(
          icon: Icons.auto_awesome_outlined,
          title: 'home.rail_empty_title'.tr(),
          message: 'home.rail_empty_subtitle'.tr(),
        ),
      ),
    );
  }
}
