import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/features/ads/domain/ad_delivery.dart';
import 'package:hb_social/features/ads/presentation/widgets/ad_preview_card.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';
import 'package:hb_social/features/safety/presentation/report_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SponsoredCard extends ConsumerStatefulWidget {
  final DeliveredAd ad;
  final AdPreviewVariant variant;
  const SponsoredCard({super.key, required this.ad, this.variant = AdPreviewVariant.feed});
  @override ConsumerState<SponsoredCard> createState() => _SponsoredCardState();
}

class _SponsoredCardState extends ConsumerState<SponsoredCard> {
  Timer? timer;
  String? hiddenId;
  bool reported = false;
  @override void dispose() { timer?.cancel(); super.dispose(); }

  void visibility(double fraction) {
    if (fraction < .5) { timer?.cancel(); timer = null; return; }
    timer ??= Timer(const Duration(seconds: 1), () async { try { await (await ref.read(adsDeliveryRepositoryProvider.future)).recordImpression(widget.ad.adId, widget.ad.placement); } catch (_) {} });
  }

  Future<void> openDestination() async {
    unawaited(ref.read(adsDeliveryRepositoryProvider.future).then((repository) => repository.recordClick(widget.ad.adId, widget.ad.placement)).catchError((_) {}));
    final route = widget.ad.destination['route']?.toString();
    final url = widget.ad.creative.destinationUrl ?? widget.ad.destination['url']?.toString();
    if (route?.startsWith('/') == true && mounted) { context.push(route!); return; }
    final uri = Uri.tryParse(url ?? '');
    if (uri != null && uri.hasScheme) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void openAdvertiser() {
    final advertiser = widget.ad.advertiser;
    if (advertiser.pageSlug?.isNotEmpty == true) context.push(AppRoutes.pageDetailPath(advertiser.pageSlug!));
    else if (advertiser.username?.isNotEmpty == true) context.push(AppRoutes.publicProfilePath(advertiser.username!));
  }

  Future<void> openMenu() async {
    await showModalBottomSheet<void>(context: context, useSafeArea: true, isScrollControlled: true, showDragHandle: true, builder: (_) => SponsoredControlSheet(ad: widget.ad, onAdvertiser: () { context.pop(); openAdvertiser(); }, onHide: hide, onReport: report));
  }

  Future<void> hide(String scope, String? reason) async {
    context.pop();
    try { final id = await (await ref.read(adsDeliveryRepositoryProvider.future)).hideAd(widget.ad.adId, scope: scope, reason: reason); if (mounted) setState(() => hiddenId = id); }
    on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  Future<void> undo() async {
    final id = hiddenId;
    if (id == null) return;
    try { await (await ref.read(adsDeliveryRepositoryProvider.future)).unhideAd(id); if (mounted) setState(() => hiddenId = null); ref.invalidate(hiddenAdsProvider); }
    on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  Future<void> report() async {
    context.pop();
    final done = await showReportSheet(context, targetType: 'ad', targetId: widget.ad.adId, titleKey: 'ads.delivery.report');
    if (done && mounted) setState(() => reported = true);
  }

  Future<void> openStory() async {
    try { await (await ref.read(adsDeliveryRepositoryProvider.future)).recordImpression(widget.ad.adId, widget.ad.placement); } catch (_) {}
    if (!mounted) return;
    await showDialog<void>(context: context, barrierColor: Colors.black87, builder: (_) => Dialog.fullscreen(backgroundColor: Colors.black, child: SafeArea(child: Stack(children: [Center(child: AdPreviewCard(client: ref.read(supabaseClientProvider), advertiserName: widget.ad.advertiser.name, advertiserAvatar: widget.ad.advertiser.avatarUrl, headline: widget.ad.creative.headline, body: widget.ad.creative.body, cta: widget.ad.creative.callToAction, media: widget.ad.creative.media, destination: widget.ad.destination, verified: widget.ad.advertiser.verified, onTap: openDestination, onCta: openDestination)), Positioned(top: AppSpacing.sm, right: AppSpacing.sm, child: HBButton.icon(icon: Icons.close_rounded, onPressed: () => context.pop()))]))));
  }

  @override Widget build(BuildContext context) {
    if (hiddenId != null || reported) return HBCard(child: Row(children: [Expanded(child: Text((reported ? 'ads.delivery.reported' : 'ads.delivery.hidden').tr())), if (!reported) HBButton.ghost(label: 'ads.delivery.undo'.tr(), onPressed: undo)]));
    final url = Uri.tryParse(widget.ad.creative.destinationUrl ?? '');
    final label = url?.host.isNotEmpty == true ? 'ads.delivery.open_domain'.tr(namedArgs: {'domain': url!.host.replaceFirst('www.', '')}) : null;
    return VisibilityDetector(key: ValueKey('delivered-ad-${widget.ad.adId}-${widget.variant.name}'), onVisibilityChanged: (info) => visibility(info.visibleFraction), child: AdPreviewCard(client: ref.watch(supabaseClientProvider), advertiserName: widget.ad.advertiser.name, advertiserAvatar: widget.ad.advertiser.avatarUrl, headline: widget.ad.creative.headline, body: widget.ad.isBoost ? 'boost.sponsored_by'.tr(namedArgs: {'name': widget.ad.advertiser.name}) : widget.ad.creative.body, cta: widget.ad.creative.callToAction, ctaLabel: label, media: widget.ad.creative.media, destination: widget.ad.destination, variant: widget.variant, verified: widget.ad.advertiser.verified, trailing: HBButton.icon(icon: Icons.more_horiz_rounded, onPressed: openMenu, size: HBButtonSize.sm), onAdvertiserTap: openAdvertiser, onTap: widget.variant == AdPreviewVariant.story ? openStory : openDestination, onCta: openDestination));
  }
}

class SponsoredControlSheet extends ConsumerWidget {
  final DeliveredAd ad;
  final VoidCallback onAdvertiser;
  final void Function(String scope, String? reason) onHide;
  final VoidCallback onReport;
  const SponsoredControlSheet({super.key, required this.ad, required this.onAdvertiser, required this.onHide, required this.onReport});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final authenticated = ref.watch(supabaseClientProvider).auth.currentUser != null;
    return Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(onTap: onAdvertiser, child: Row(children: [HBAvatar(name: ad.advertiser.name, imageUrl: ad.advertiser.avatarUrl, size: 44), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(ad.advertiser.name, style: context.textStyles.titleMedium?.bold)), if (ad.advertiser.verified) const Icon(Icons.verified_rounded, color: LightModeColors.lightPrimary)])),
      const SizedBox(height: AppSpacing.lg), Text('ads.delivery.why_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.sm), Text('ads.delivery.why_intro'.tr()), const SizedBox(height: AppSpacing.sm), for (final reason in ad.why) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.xs), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_rounded, size: 18, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.xs), Expanded(child: Text(_why(context, reason)))])),
      HBButton.ghost(label: 'ads.delivery.preferences'.tr(), onPressed: () { context.pop(); context.push(AppRoutes.adsSettings); }), const Divider(),
      if (!authenticated) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.login_rounded), title: Text('ads.delivery.login_manage'.tr()), onTap: () { context.pop(); context.push(AppRoutes.login); }) else ...[
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.visibility_off_outlined), title: Text('ads.delivery.hide_ad'.tr()), onTap: () => _reasons(context)),
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.block_rounded), title: Text('ads.delivery.hide_advertiser'.tr(namedArgs: {'name': ad.advertiser.name})), onTap: () => onHide('advertiser', null)),
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.flag_outlined), title: Text('ads.delivery.report'.tr()), onTap: onReport),
      ],
    ])));
  }
  Future<void> _reasons(BuildContext context) async { final reason = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (sheet) => SafeArea(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final value in const ['not_relevant','too_often','already_seen','offensive','other']) HBChip(label: 'ads.delivery.hide_reason.$value'.tr(), onTap: () => sheet.pop(value))])))); if (reason != null) onHide('ad', reason); }
  String _why(BuildContext context, String value) { final parts = value.split(':'); final kind = parts.first; final detail = parts.length > 1 ? parts.sublist(1).join(':') : ''; if (kind == 'all') return 'ads.delivery.why.all'.tr(); if (kind == 'country') return 'ads.delivery.why.country'.tr(namedArgs: {'value': 'zone.country_${detail.toLowerCase()}'.tr()}); if (kind == 'locale') return 'ads.delivery.why.locale'.tr(namedArgs: {'value': 'language.${detail.toLowerCase()}'.tr()}); return 'ads.delivery.why.$kind'.tr(namedArgs: {'value': detail}); }
}