import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

class AdminForbiddenPage extends ConsumerWidget {
  const AdminForbiddenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: LightModeColors.lightBackground,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: HBEmptyState(
            icon: Icons.lock_outline,
            title: 'admin.p05.forbiddenTitle'.tr(),
            message: 'admin.p05.forbiddenMessage'.tr(),
            action: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                HBButton.primary(
                  label: 'auth.logout'.tr(),
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go('/admin/login');
                  },
                ),
                HBButton.ghost(label: 'admin.login.backToApp'.tr(), onPressed: () => context.go('/')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}