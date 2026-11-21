import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? errorKey;
  bool submitting = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(adminAccessProvider);
    if (access.value != null) WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/admin');
    });
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
                              HBInput(controller: emailController, label: 'admin.login.email'.tr(), keyboardType: TextInputType.emailAddress),
                              const SizedBox(height: AppSpacing.md),
                              HBInput(controller: passwordController, label: 'admin.login.password'.tr(), obscureText: true),
                              const SizedBox(height: AppSpacing.lg),
                              HBButton.primary(label: submitting ? 'admin.p05.loginLoading'.tr() : 'admin.login.submit'.tr(), onPressed: submitting ? null : _submit),
                              if (errorKey != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(color: LightModeColors.lightError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
                                  child: Text(errorKey!.tr(), textAlign: TextAlign.center, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError)),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.sm),
                              HBButton.ghost(label: 'admin.login.backToApp'.tr(), onPressed: () => context.go('/')),
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

  Future<void> _submit() async {
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      setState(() => errorKey = 'auth.errors.required_fields');
      return;
    }
    setState(() {
      submitting = true;
      errorKey = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(email: emailController.text, password: passwordController.text);
      ref.invalidate(authSessionProvider);
      ref.invalidate(adminAccessProvider);
      final access = await ref.read(adminAccessProvider.future);
      if (access == null) {
        await ref.read(authRepositoryProvider).signOut();
        if (mounted) setState(() => errorKey = 'admin.p05.noAccess');
        return;
      }
      ref.invalidate(verifiedMfaFactorsProvider);
      final factors = await ref.read(verifiedMfaFactorsProvider.future);
      if (factors.isEmpty) {
        if (mounted) context.go('/admin/mfa-enroll');
        return;
      }
      final needsMfa = await ref.read(authSecurityRepositoryProvider).needsChallenge();
      if (needsMfa) {
        if (mounted) context.go('/mfa-challenge?destination=${Uri.encodeComponent('/admin')}');
        return;
      }
      if (mounted) context.go('/admin');
    } on AppException catch (error) {
      if (mounted) setState(() => errorKey = error.messageKey);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }
}