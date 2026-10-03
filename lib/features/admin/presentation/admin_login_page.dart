import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/config/env.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/features/admin/providers/admin_preview_provider.dart';

class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  bool showNotice = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightModeColors.adminSidebar,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HBCard(
                          radius: AppRadius.sm,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Align(alignment: Alignment.center, child: HbLogo()),
                              const SizedBox(height: AppSpacing.lg),
                              Text('admin.login.title'.tr(), textAlign: TextAlign.center, style: context.textStyles.headlineSmall?.withColor(LightModeColors.lightOnSurface).bold),
                              const SizedBox(height: AppSpacing.xs),
                              Text('admin.login.subtitle'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
                              const SizedBox(height: AppSpacing.xl),
                              HBInput(label: 'admin.login.email'.tr(), keyboardType: TextInputType.emailAddress),
                              const SizedBox(height: AppSpacing.md),
                              HBInput(label: 'admin.login.password'.tr(), obscureText: true),
                              const SizedBox(height: AppSpacing.md),
                              HBInput(label: 'admin.login.twoFactor'.tr(), keyboardType: TextInputType.number, maxLength: 6, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                              const SizedBox(height: AppSpacing.lg),
                              HBButton.primary(label: 'admin.login.submit'.tr(), onPressed: () => setState(() => showNotice = true)),
                              if (showNotice) ...[
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(color: LightModeColors.lightPrimarySoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
                                  child: Text('admin.login.notice'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightForest)),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.sm),
                              HBButton.ghost(label: 'admin.login.backToApp'.tr(), onPressed: () => context.go('/')),
                              if (Env.previewEnabled) ...[
                                const SizedBox(height: AppSpacing.xs),
                                HBButton.ghost(
                                  label: 'admin.login.preview'.tr(),
                                  onPressed: () {
                                    if (!Env.previewEnabled) return;
                                    ref.read(adminPreviewProvider.notifier).state = true;
                                    context.go('/admin');
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}