import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/features/admin/domain/admin_module.dart';

class AdminModulePage extends StatelessWidget {
  final AdminModule module;

  const AdminModulePage({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(module.titleKey.tr(), style: context.textStyles.headlineSmall?.withColor(LightModeColors.lightOnSurface).bold),
              const SizedBox(height: AppSpacing.xs),
              Text(module.descriptionKey.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
              const SizedBox(height: AppSpacing.lg),
              HBCard(
                radius: AppRadius.sm,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: HBEmptyState(icon: module.icon, title: 'admin.module.emptyTitle'.tr(), message: 'admin.module.emptyMessage'.tr(namedArgs: {'phase': module.phase})),
              ),
            ],
          ),
        ),
      ],
    );
  }
}