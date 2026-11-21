import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/auth/domain/social_auth_models.dart';
import 'package:hb_social/features/auth/presentation/change_password_dialog.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';

class LoginMethodsPage extends ConsumerWidget {
  const LoginMethodsPage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => PageColumns(
    center: CustomScrollView(slivers: [SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      sliver: SliverList.list(children: [
        Row(children: [HBButton.icon(icon: Icons.arrow_back, onPressed: () => context.pop()), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('settings.login_methods.title'.tr(), style: context.textStyles.headlineSmall))]),
        const SizedBox(height: AppSpacing.lg),
        ref.watch(myAuthIdentitiesProvider).when(
          loading: () => const HBCard(child: Column(children: [HBSkeleton(height: 48), SizedBox(height: 8), HBSkeleton(height: 48)])),
          error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'settings.login_methods.error'.tr(), message: 'errors.network'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(myAuthIdentitiesProvider)))),
          data: (value) => LoginMethodsContent(value: value),
        ),
      ]),
    )]),
  );
}

class LoginMethodsContent extends ConsumerWidget {
  final MyAuthIdentities value;
  const LoginMethodsContent({super.key, required this.value});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final linked = value.identities.map((item) => item.provider).toSet();
    final available = value.providersEnabled.where((provider) => !linked.contains(provider)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('settings.login_methods.linked'.tr(), style: context.textStyles.titleMedium?.bold), const SizedBox(height: AppSpacing.sm),
      HBCard(child: value.identities.isEmpty ? HBEmptyState(icon: Icons.key_outlined, title: 'settings.login_methods.empty'.tr(), message: 'settings.login_methods.empty_help'.tr()) : Column(children: [for (final identity in value.identities) LoginIdentityRow(identity: identity, canUnlink: value.canUnlink, onUnlink: () => _confirmUnlink(context, ref, identity))])),
      if (value.manualLinking && available.isNotEmpty) ...[const SizedBox(height: AppSpacing.lg), Text('settings.login_methods.add'.tr(), style: context.textStyles.titleMedium?.bold), const SizedBox(height: AppSpacing.sm), HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final provider in available) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: HBButton.secondary(label: 'settings.login_methods.link_provider'.tr(namedArgs: {'provider': 'auth.social.provider.$provider'.tr()}), leading: providerIconWidget(provider), foregroundColor: providerColor(provider), onPressed: () => _link(context, ref, provider)))]))],
      const SizedBox(height: AppSpacing.lg), Text('settings.login_methods.password'.tr(), style: context.textStyles.titleMedium?.bold), const SizedBox(height: AppSpacing.sm),
      HBCard(child: value.hasPassword ? HBButton.secondary(label: 'auth.password_change.title'.tr(), icon: Icons.password, onPressed: () => showDialog<void>(context: context, builder: (_) => const ChangePasswordDialog())) : HBButton.primary(label: 'settings.login_methods.set_password'.tr(), icon: Icons.password, onPressed: () => showDialog<void>(context: context, builder: (_) => const SetPasswordDialog()))),
    ]);
  }

  Future<void> _link(BuildContext context, WidgetRef ref, String provider) async {
    try { await ref.read(authRepositoryProvider).linkProvider(provider); ref.invalidate(myAuthIdentitiesProvider); }
    on AppException catch (error) { if (context.mounted && error.messageKey != 'auth.cancelled') ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  Future<void> _confirmUnlink(BuildContext context, WidgetRef ref, AuthIdentityInfo identity) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text('settings.login_methods.unlink_title'.tr()), content: Text('settings.login_methods.unlink_message'.tr(namedArgs: {'provider': 'auth.social.provider.${identity.provider}'.tr()})), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop(false)), HBButton.primary(label: 'settings.login_methods.unlink'.tr(), onPressed: () => context.pop(true))]));
    if (confirmed != true) return;
    try { await ref.read(authRepositoryProvider).unlinkProvider(identity.id); ref.invalidate(myAuthIdentitiesProvider); }
    on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }
}

class LoginIdentityRow extends StatelessWidget {
  final AuthIdentityInfo identity;
  final bool canUnlink;
  final VoidCallback onUnlink;
  const LoginIdentityRow({super.key, required this.identity, required this.canUnlink, required this.onUnlink});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Row(children: [providerIconWidget(identity.provider), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(identity.provider == 'email' ? 'settings.login_methods.email_password'.tr() : 'auth.social.provider.${identity.provider}'.tr(), style: context.textStyles.bodyMedium?.bold), Text(identity.email ?? 'common.unavailable'.tr(), style: context.textStyles.bodySmall), if (identity.lastSignInAt != null) Text('settings.login_methods.last_sign_in'.tr(namedArgs: {'time': relativeTime(context, identity.lastSignInAt!)}), style: context.textStyles.bodySmall?.withColor(LightModeColors.textTertiary))])), if (canUnlink && identity.provider != 'email') HBButton.ghost(label: 'settings.login_methods.unlink'.tr(), size: HBButtonSize.sm, onPressed: onUnlink)]));
}

class SetPasswordDialog extends ConsumerStatefulWidget {
  const SetPasswordDialog({super.key});
  @override ConsumerState<SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends ConsumerState<SetPasswordDialog> {
  final password = TextEditingController(); final confirm = TextEditingController(); bool saving = false; String? error;
  @override void dispose() { password.dispose(); confirm.dispose(); super.dispose(); }
  Future<void> save() async {
    if (password.text.length < 8 || password.text != confirm.text) { setState(() => error = 'auth.password_reset.invalid_password'); return; }
    setState(() { saving = true; error = null; });
    try { await ref.read(authRepositoryProvider).updatePassword(password.text); ref.invalidate(myAuthIdentitiesProvider); if (mounted) { context.pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('settings.login_methods.password_set'.tr()))); } }
    on AppException catch (value) { if (mounted) setState(() => error = value.messageKey); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override Widget build(BuildContext context) => AlertDialog(title: Text('settings.login_methods.set_password'.tr()), content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [HBInput(label: 'auth.password_reset.new_password'.tr(), controller: password, obscureText: true), const SizedBox(height: AppSpacing.sm), HBInput(label: 'auth.password_reset.confirm_password'.tr(), controller: confirm, obscureText: true), if (error != null) Text(error!.tr(), style: const TextStyle(color: LightModeColors.lightError))])), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: saving ? null : () => context.pop()), HBButton.primary(label: 'common.save'.tr(), onPressed: saving ? null : save, isLoading: saving)]);
}

Widget providerIconWidget(String provider) => provider == 'email' ? Icon(Icons.mail_outline, color: providerColor(provider), size: 22) : FaIcon(switch (provider) { 'google' => FontAwesomeIcons.google!, 'apple' => FontAwesomeIcons.apple!, 'facebook' => FontAwesomeIcons.facebook!, 'azure' => FontAwesomeIcons.microsoft!, _ => FontAwesomeIcons.key! }, color: providerColor(provider), size: 22);
Color providerColor(String provider) => switch (provider) { 'google' => LightModeColors.brandGoogle, 'apple' => LightModeColors.brandApple, 'facebook' => LightModeColors.brandFacebook, 'azure' => LightModeColors.brandMicrosoft, _ => LightModeColors.textSecondary };