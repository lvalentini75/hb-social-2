import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/config/app_constants.dart';
import 'package:hb_social/core/providers/platform_providers.dart';
import 'package:hb_social/core/services/platform_info.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ReleaseGate extends ConsumerStatefulWidget {
  final Widget child;
  const ReleaseGate({super.key, required this.child});
  @override ConsumerState<ReleaseGate> createState() => _ReleaseGateState();
}

class _ReleaseGateState extends ConsumerState<ReleaseGate> {
  Timer? timer;
  @override void dispose() { timer?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context) => ref.watch(platformConfigProvider).when(
    loading: () => const ColoredBox(color: LightModeColors.lightBackground, child: Center(child: CircularProgressIndicator())),
    error: (_, __) => widget.child,
    data: (config) {
      final release = config.release;
      final forced = AppConstants.compareVersions(AppConstants.appVersion, release.forceUpdateBelow) < 0;
      if (forced) return ReleaseBlockingPage(icon: Icons.system_update_alt_rounded, titleKey: 'release.update.title', messageKey: 'release.update.message', actionKey: 'release.update.action', onAction: () => _openStore(release.storeUrls[currentPlatformName] ?? release.webUrl));
      final admin = ref.watch(adminAccessProvider).value != null;
      if (release.maintenanceMode && !admin) {
        timer ??= Timer.periodic(const Duration(seconds: 60), (_) => ref.invalidate(platformConfigProvider));
        return ReleaseBlockingPage(icon: Icons.construction_rounded, titleKey: 'release.maintenance.title', message: release.maintenanceText(context.locale.languageCode), messageKey: 'release.maintenance.message', actionKey: 'release.maintenance.retry', onAction: () => ref.invalidate(platformConfigProvider));
      }
      timer?.cancel(); timer = null;
      final updateAvailable = release.updateAvailable && (AppConstants.compareVersions(AppConstants.appVersion, release.minAppVersion) < 0 || AppConstants.compareVersions(AppConstants.appVersion, release.latestAppVersion) < 0);
      return Column(children: [if (updateAvailable) Material(color: LightModeColors.boscoSoft, child: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs), child: Row(children: [const Icon(Icons.system_update_rounded, size: 20), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('release.update.available'.tr())), HBButton.ghost(label: 'release.update.action'.tr(), size: HBButtonSize.sm, onPressed: () => _openStore(release.storeUrls[currentPlatformName] ?? release.webUrl))])))), Expanded(child: widget.child)]);
    },
  );

  Future<void> _openStore(String value) async { final uri = Uri.tryParse(value); if (uri != null && uri.hasScheme) await launchUrl(uri, mode: LaunchMode.externalApplication); }
}

class ReleaseBlockingPage extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String messageKey;
  final String? message;
  final String actionKey;
  final VoidCallback onAction;
  const ReleaseBlockingPage({super.key, required this.icon, required this.titleKey, required this.messageKey, this.message, required this.actionKey, required this.onAction});
  @override Widget build(BuildContext context) => ColoredBox(color: LightModeColors.lightBackground, child: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: HBEmptyState(icon: icon, title: titleKey.tr(), message: message?.isNotEmpty == true ? message! : messageKey.tr(), action: HBButton.primary(label: actionKey.tr(), onPressed: onAction))))));
}