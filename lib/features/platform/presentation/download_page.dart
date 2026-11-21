import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/providers/platform_providers.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_logo.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hb_social/core/services/seo_service.dart';

class DownloadPage extends ConsumerWidget {
  const DownloadPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) { SeoService.update(title: 'seo.download_title'.tr(), description: 'seo.download_description'.tr(), path: '/download'); return ColoredBox(color: LightModeColors.lightBackground, child: SafeArea(child: Center(child: SizedBox(width: 760, child: ref.watch(platformConfigProvider).when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, __) => Center(child: Text('download.error'.tr())),
    data: (config) {
      final release = config.release;
      final pageUrl = release.webUrl.isNotEmpty ? release.webUrl : 'https://huntingbook.app/download';
      return ListView(padding: const EdgeInsets.all(AppSpacing.xl), shrinkWrap: true, children: [
        const Center(child: HbLogo()), const SizedBox(height: AppSpacing.lg), Text('download.title'.tr(), textAlign: TextAlign.center, style: context.textStyles.headlineMedium), Text('download.subtitle'.tr(), textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg), Center(child: Semantics(label: 'download.qr_label'.tr(), child: QrImageView(data: pageUrl, size: 180))), const SizedBox(height: AppSpacing.lg),
        Wrap(alignment: WrapAlignment.center, spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [StoreDownloadButton(platform: 'ios', url: release.storeUrls['ios']), StoreDownloadButton(platform: 'android', url: release.storeUrls['android']), if (kIsWeb) HBButton.primary(label: 'download.open_web'.tr(), icon: Icons.language_rounded, onPressed: release.webUrl.isEmpty ? null : () => launchUrl(Uri.parse(release.webUrl)))])
      ]);
    },
  ))))); }
}

class StoreDownloadButton extends StatelessWidget {
  final String platform;
  final String? url;
  const StoreDownloadButton({super.key, required this.platform, this.url});
  @override Widget build(BuildContext context) => HBButton.secondary(label: url?.isNotEmpty == true ? 'download.$platform'.tr() : 'download.coming_soon'.tr(), icon: platform == 'ios' ? Icons.apple : Icons.android, onPressed: url?.isNotEmpty == true ? () => launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication) : null);
}