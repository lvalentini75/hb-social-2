import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/page_columns.dart';

/// Placeholder page for shell destinations whose screens are not built yet.
/// It never fakes content: a single explicit "coming soon" empty state,
/// labelled with the destination name.
class HBComingSoonPage extends StatelessWidget {
  final IconData icon;
  final String titleKey;

  const HBComingSoonPage({super.key, required this.icon, required this.titleKey});

  @override
  Widget build(BuildContext context) {
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
                    icon: icon,
                    title: 'common.coming_soon_title'.tr(),
                    message: 'common.coming_soon_message'.tr(namedArgs: {'section': titleKey.tr()}),
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
