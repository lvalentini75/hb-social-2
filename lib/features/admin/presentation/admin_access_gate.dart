import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/features/admin/domain/admin_module.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/shell/admin_shell.dart';

class AdminAccessGate extends ConsumerWidget {
  final String path;
  final Widget child;

  const AdminAccessGate({super.key, required this.path, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (session.isLoading) return const AdminAccessLoadingPage();
    if (session.value == null) {
      _redirect(context, '/admin/login');
      return const AdminAccessLoadingPage();
    }
    final access = ref.watch(adminAccessProvider);
    return access.when(
      loading: () => const AdminAccessLoadingPage(),
      error: (_, __) => AdminShell(child: AdminAccessError(onRetry: () => ref.invalidate(adminAccessProvider))),
      data: (value) {
        if (value == null) {
          _redirect(context, '/admin/forbidden');
          return const AdminAccessLoadingPage();
        }
        final factors = ref.watch(verifiedMfaFactorsProvider);
        if (factors.isLoading) return const AdminAccessLoadingPage();
        if (factors.value?.isEmpty ?? true) {
          _redirect(context, '/admin/mfa-enroll');
          return const AdminAccessLoadingPage();
        }
        final mfaRequired = ref.watch(mfaChallengeRequiredProvider);
        if (mfaRequired.isLoading) return const AdminAccessLoadingPage();
        if (mfaRequired.value == true) {
          _redirect(context, '/mfa-challenge?destination=%2Fadmin');
          return const AdminAccessLoadingPage();
        }
        final routeSlug = path == '/admin' ? '' : path.replaceFirst('/admin/', '').split('/').first;
        final module = adminModuleForSlug(routeSlug);
        final permissionSlug = path.startsWith('/admin/hunting/layers') ? 'maps' : module?.permissionSlug ?? 'dashboard';
        if (!value.canRead(permissionSlug)) {
          _redirect(context, '/admin?denied=1');
          return const AdminAccessLoadingPage();
        }
        return AdminShell(child: child);
      },
    );
  }

  void _redirect(BuildContext context, String location) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && GoRouterState.of(context).uri.toString() != location) context.go(location);
    });
  }
}

class AdminAccessLoadingPage extends StatelessWidget {
  const AdminAccessLoadingPage({super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: LightModeColors.lightBackground,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [HBSkeleton(width: 220, height: 28), SizedBox(height: AppSpacing.xl), HBSkeleton(height: 120), SizedBox(height: AppSpacing.md), HBSkeleton(height: 240)]),
      ),
    ),
  );
}

class AdminAccessError extends StatelessWidget {
  final VoidCallback onRetry;

  const AdminAccessError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(child: IconButton(onPressed: onRetry, tooltip: 'common.retry'.tr(), icon: const Icon(Icons.refresh)));
}