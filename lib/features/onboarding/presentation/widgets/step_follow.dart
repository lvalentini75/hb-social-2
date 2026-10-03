import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';

/// Onboarding step 3: people and groups to follow. There is no backend yet,
/// so this always shows the explicit empty state rather than fake
/// suggestions.
class StepFollow extends StatelessWidget {
  const StepFollow({super.key});

  @override
  Widget build(BuildContext context) {
    return HBEmptyState(
      icon: Icons.group_add_outlined,
      title: 'onboarding.follow_empty_title'.tr(),
      message: 'onboarding.follow_empty_subtitle'.tr(),
    );
  }
}
