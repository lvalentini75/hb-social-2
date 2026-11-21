import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_source_picker.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/features/ads/data/ads_repository.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/domain/ad_models.dart';
import 'package:hb_social/features/ads/presentation/widgets/ad_preview_card.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/pages/providers/page_providers.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';

bool _canWrite(AdAccount account) => account.myRole != AdAccountRole.analyst && account.status == AdAccountStatus.active;

class AdCampaignsTab extends ConsumerStatefulWidget {
  final AdAccount account;
  final bool readOnly;
  const AdCampaignsTab({super.key, required this.account, required this.readOnly});
  @override ConsumerState<AdCampaignsTab> createState() => _AdCampaignsTabState();
}

class _AdCampaignsTabState extends ConsumerState<AdCampaignsTab> {
  int filter = 0;
  static const statuses = <AdCampaignStatus?>[null, AdCampaignStatus.draft, AdCampaignStatus.inReview, AdCampaignStatus.active, AdCampaignStatus.paused, AdCampaignStatus.completed, AdCampaignStatus.rejected, AdCampaignStatus.archived];
  Future<void> _status(AdCampaign campaign, AdCampaignStatus status) async { try { await ref.read(adsRepositoryProvider).setCampaignStatus(campaign.id, status); ref.invalidate(adCampaignsProvider(widget.account.id)); } on AppException catch (error) { if (mounted) _error(context, error); } }
  @override Widget build(BuildContext context) {
    final writable = _canWrite(widget.account) && !widget.readOnly;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: Text('ads.campaigns.title'.tr(), style: context.textStyles.titleLarge)), if (writable) HBButton.primary(label: 'ads.campaigns.new'.tr(), icon: Icons.add_rounded, onPressed: () => context.go(AppRoutes.adCampaignNewPath(widget.account.id)))]), const SizedBox(height: AppSpacing.md),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: 850, child: HBSegmentedTabs(labels: ['ads.filters.all'.tr(), 'ads.filters.draft'.tr(), 'ads.filters.in_review'.tr(), 'ads.filters.active'.tr(), 'ads.filters.paused'.tr(), 'ads.filters.completed'.tr(), 'ads.filters.rejected'.tr(), 'ads.filters.archived'.tr()], selectedIndex: filter, onChanged: (value) => setState(() => filter = value)))), const SizedBox(height: AppSpacing.md),
      ref.watch(adCampaignsProvider(widget.account.id)).when(loading: () => const HBListSkeleton(), error: (_, __) => _Retry(onRetry: () => ref.invalidate(adCampaignsProvider(widget.account.id))), data: (items) { final visible = items.where((item) => statuses[filter] == null || statuses[filter] == AdCampaignStatus.active && (item.status == AdCampaignStatus.active || item.status == AdCampaignStatus.scheduled) || item.status == statuses[filter]).toList(); if (visible.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.campaign_outlined, title: 'ads.campaigns.empty_title'.tr(), message: 'ads.campaigns.empty_message'.tr())); return Column(children: [for (final item in visible) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: AdCampaignRow(campaign: item, writable: writable, onStatus: (status) => _status(item, status), onTap: () => item.status == AdCampaignStatus.draft ? context.go(AppRoutes.adCampaignEditPath(widget.account.id, item.id)) : context.go(AppRoutes.adCampaignPath(item.id))))]); }),
    ]);
  }
}

class AdCampaignRow extends StatelessWidget {
  final AdCampaign campaign;
  final bool writable;
  final ValueChanged<AdCampaignStatus> onStatus;
  final VoidCallback onTap;
  const AdCampaignRow({super.key, required this.campaign, required this.writable, required this.onStatus, required this.onTap});
  @override Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final progress = campaign.budgetMinor == 0 ? 0.0 : (campaign.spentMinor / campaign.budgetMinor).clamp(0.0, 1.0);
    return HBCard(child: InkWell(onTap: onTap, child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Flexible(child: Text(campaign.name, overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall?.bold)), const SizedBox(width: AppSpacing.sm), HBStatusChip(kind: _campaignKind(campaign.status), label: campaign.status.labelKey.tr())]),
        Text(campaign.objective.labelKey.tr(), style: context.textStyles.bodySmall), const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(value: progress, backgroundColor: LightModeColors.lightBackgroundSoft), const SizedBox(height: AppSpacing.xs),
        Text('ads.campaigns.spent'.tr(namedArgs: {'spent': MoneyFormatter.format(amountMinor: campaign.spentMinor, currencyCode: campaign.currencyCode, locale: locale), 'total': MoneyFormatter.format(amountMinor: campaign.budgetMinor, currencyCode: campaign.currencyCode, locale: locale)}), style: context.textStyles.bodySmall),
        if (campaign.rejectionReason?.isNotEmpty == true) Text(campaign.rejectionReason!, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError)),
      ])),
      if (writable) PopupMenuButton<AdCampaignStatus>(onSelected: onStatus, itemBuilder: (_) => [for (final status in _campaignActions(campaign.status)) PopupMenuItem(value: status, child: Text('ads.actions.${status.code}'.tr()))]),
    ])));
  }
}

class AdAudiencesTab extends ConsumerWidget {
  final AdAccount account;
  final bool readOnly;
  const AdAudiencesTab({super.key, required this.account, required this.readOnly});
  Future<void> _open(BuildContext context, WidgetRef ref, [AdAudience? audience]) async { final changed = await showModalBottomSheet<bool>(context: context, useSafeArea: true, isScrollControlled: true, builder: (_) => AdAudienceForm(accountId: account.id, audience: audience)); if (changed == true) ref.invalidate(adAudiencesProvider(account.id)); }
  @override Widget build(BuildContext context, WidgetRef ref) { final writable = _canWrite(account) && !readOnly; return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Expanded(child: Text('ads.audiences.title'.tr(), style: context.textStyles.titleLarge)), if (writable) HBButton.primary(label: 'ads.audiences.new'.tr(), icon: Icons.add_rounded, onPressed: () => _open(context, ref))]), const SizedBox(height: AppSpacing.md), ref.watch(adAudiencesProvider(account.id)).when(loading: () => const HBListSkeleton(), error: (_, __) => _Retry(onRetry: () => ref.invalidate(adAudiencesProvider(account.id))), data: (items) => items.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.groups_outlined, title: 'ads.audiences.empty_title'.tr(), message: 'ads.audiences.empty_message'.tr())) : Column(children: [for (final item in items) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: HBCard(child: ListTile(contentPadding: EdgeInsets.zero, title: Text(item.name, style: context.textStyles.titleSmall?.bold), subtitle: Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final value in [...item.countryCodes, ...item.interests, ...item.verificationLevels]) HBChip(label: value), Text('ads.audiences.reach'.tr(namedArgs: {'count': '${item.estimatedReach}'}))]), trailing: writable ? HBButton.ghost(label: 'common.edit'.tr(), onPressed: () => _open(context, ref, item), size: HBButtonSize.sm) : null)))]))]); }
}

class AdAudienceForm extends ConsumerStatefulWidget {
  final String accountId;
  final AdAudience? audience;
  const AdAudienceForm({super.key, required this.accountId, this.audience});
  @override ConsumerState<AdAudienceForm> createState() => _AdAudienceFormState();
}

class _AdAudienceFormState extends ConsumerState<AdAudienceForm> {
  late final name = TextEditingController(text: widget.audience?.name);
  late final interests = TextEditingController(text: widget.audience?.interests.join(', '));
  late final countries = <String>{...?widget.audience?.countryCodes};
  late final levels = <String>{...?widget.audience?.verificationLevels};
  late final locales = <String>{...?widget.audience?.locales};
  int? reach;
  bool loading = false;
  Timer? debounce;
  @override void initState() { super.initState(); if (countries.isEmpty) countries.add('IT'); _estimate(); }
  @override void dispose() { debounce?.cancel(); name.dispose(); interests.dispose(); super.dispose(); }
  List<String> get interestList => interests.text.split(',').map((item) => item.trim()).where((item) => item.length >= 2).take(10).toList();
  void _estimate() { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 400), () async { if (!mounted) return; setState(() => loading = true); try { final value = await ref.read(adsRepositoryProvider).estimateAudience(countryCodes: countries.toList(), regionIds: widget.audience?.regionIds ?? const [], interests: interestList, speciesIds: widget.audience?.speciesIds ?? const [], verificationLevels: levels.toList(), locales: locales.toList()); if (mounted) setState(() => reach = value); } finally { if (mounted) setState(() => loading = false); } }); }
  Future<void> _save() async { try { await ref.read(adsRepositoryProvider).upsertAudience(accountId: widget.accountId, id: widget.audience?.id, name: name.text.trim(), countryCodes: countries.toList(), regionIds: widget.audience?.regionIds ?? const [], interests: interestList, speciesIds: widget.audience?.speciesIds ?? const [], verificationLevels: levels.toList(), locales: locales.toList()); if (mounted) context.pop(true); } on AppException catch (error) { if (mounted) _error(context, error); } }
  @override Widget build(BuildContext context) => Material(color: LightModeColors.lightSurface, child: CustomScrollView(slivers: [SliverAppBar(title: Text(widget.audience == null ? 'ads.audiences.create_title'.tr() : 'ads.audiences.edit_title'.tr()), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop(false))), SliverPadding(padding: const EdgeInsets.all(AppSpacing.lg), sliver: SliverList.list(children: [HBFormField(label: 'ads.fields.name'.tr(), required: true, child: HBInput(controller: name, maxLength: 60)), const SizedBox(height: AppSpacing.md), Text('ads.audiences.countries'.tr(), style: context.textStyles.titleSmall), Wrap(spacing: AppSpacing.xs, children: [for (final code in const ['IT', 'FR', 'ES', 'DE', 'AT']) FilterChip(label: Text(code), selected: countries.contains(code), onSelected: (selected) { setState(() => selected ? countries.add(code) : countries.remove(code)); _estimate(); })]), const SizedBox(height: AppSpacing.md), HBFormField(label: 'ads.audiences.interests'.tr(), helper: 'ads.audiences.interests_help'.tr(), child: HBInput(controller: interests, onChanged: (_) => _estimate())), const SizedBox(height: AppSpacing.md), Text('ads.audiences.verification'.tr(), style: context.textStyles.titleSmall), Wrap(spacing: AppSpacing.xs, children: [for (final value in const ['hunter', 'pro', 'gun_shop', 'breeder', 'page']) FilterChip(label: Text('verification.badge.$value'.tr()), selected: levels.contains(value), onSelected: (selected) { setState(() => selected ? levels.add(value) : levels.remove(value)); _estimate(); })]), const SizedBox(height: AppSpacing.md), Text('ads.audiences.languages'.tr(), style: context.textStyles.titleSmall), Wrap(spacing: AppSpacing.xs, children: [for (final value in const ['it', 'en', 'fr', 'es', 'de']) FilterChip(label: Text(value.toUpperCase()), selected: locales.contains(value), onSelected: (selected) { setState(() => selected ? locales.add(value) : locales.remove(value)); _estimate(); })]), const SizedBox(height: AppSpacing.lg), HBCard(child: Column(children: [if (loading) const LinearProgressIndicator(), Text('ads.audiences.reach'.tr(namedArgs: {'count': '${reach ?? 0}'}), style: context.textStyles.titleMedium), if ((reach ?? 0) < 50) Text('ads.audiences.too_small'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightWarning))])), const SizedBox(height: AppSpacing.lg), HBButton.primary(label: 'common.save'.tr(), onPressed: name.text.trim().length >= 2 ? _save : null)]))]));
}

class AdCreativesTab extends ConsumerStatefulWidget {
  final AdAccount account;
  final bool readOnly;
  const AdCreativesTab({super.key, required this.account, required this.readOnly});
  @override ConsumerState<AdCreativesTab> createState() => _AdCreativesTabState();
}

class _AdCreativesTabState extends ConsumerState<AdCreativesTab> {
  int filter = 0;
  Future<void> _open([AdCreative? creative]) async { final changed = await showModalBottomSheet<bool>(context: context, useSafeArea: true, isScrollControlled: true, builder: (_) => AdCreativeForm(account: widget.account, creative: creative)); if (changed == true) ref.invalidate(adCreativesProvider(widget.account.id)); }
  @override Widget build(BuildContext context) { final writable = _canWrite(widget.account) && !widget.readOnly; return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Expanded(child: Text('ads.creatives.title'.tr(), style: context.textStyles.titleLarge)), if (writable) HBButton.primary(label: 'ads.creatives.new'.tr(), icon: Icons.add_rounded, onPressed: _open)]), const SizedBox(height: AppSpacing.md), HBSegmentedTabs(labels: ['ads.filters.all'.tr(), 'ads.review.pending'.tr(), 'ads.review.approved'.tr(), 'ads.review.rejected'.tr()], selectedIndex: filter, onChanged: (value) => setState(() => filter = value)), const SizedBox(height: AppSpacing.md), ref.watch(adCreativesProvider(widget.account.id)).when(loading: () => const HBListSkeleton(), error: (_, __) => _Retry(onRetry: () => ref.invalidate(adCreativesProvider(widget.account.id))), data: (items) { final status = const [null, 'pending', 'approved', 'rejected'][filter]; final visible = items.where((item) => status == null || item.reviewStatus == status).toList(); if (visible.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.auto_awesome_motion_outlined, title: 'ads.creatives.empty_title'.tr(), message: 'ads.creatives.empty_message'.tr())); return LayoutBuilder(builder: (context, box) { final count = box.maxWidth >= 900 ? 4 : box.maxWidth >= 600 ? 3 : 2; return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: visible.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm, childAspectRatio: .78), itemBuilder: (_, index) => AdCreativeCard(creative: visible[index], onTap: writable ? () => _open(visible[index]) : null)); }); })]); }
}

class AdCreativeCard extends ConsumerWidget {
  final AdCreative creative;
  final VoidCallback? onTap;
  final bool selected;
  const AdCreativeCard({super.key, required this.creative, this.onTap, this.selected = false});
  @override Widget build(BuildContext context, WidgetRef ref) { final path = creative.media.firstOrNull?.posterPath ?? creative.media.firstOrNull?.path; return HBCard.media(child: InkWell(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: path == null ? const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.image_outlined)) : Image.network(storagePublicUrl(ref.watch(supabaseClientProvider), AdsRepository.creativeBucket, path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft))), Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(creative.headline.isEmpty ? creative.kind.labelKey.tr() : creative.headline, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodyMedium?.bold), const SizedBox(height: AppSpacing.xs), Wrap(spacing: AppSpacing.xs, children: [HBChip(label: creative.kind.labelKey.tr()), HBStatusChip(kind: creative.reviewStatus == 'approved' ? HBStatusKind.approved : creative.reviewStatus == 'rejected' ? HBStatusKind.rejected : HBStatusKind.pending, label: 'ads.review.${creative.reviewStatus}'.tr())]), if (creative.rejectionReason != null) Text(creative.rejectionReason!, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))]))]))); }
}

class AdCreativeForm extends ConsumerStatefulWidget {
  final AdAccount account;
  final AdCreative? creative;
  final AdCreativeKind? initialKind;
  const AdCreativeForm({super.key, required this.account, this.creative, this.initialKind});
  @override ConsumerState<AdCreativeForm> createState() => _AdCreativeFormState();
}

class _AdCreativeFormState extends ConsumerState<AdCreativeForm> {
  late AdCreativeKind kind = widget.creative?.kind ?? widget.initialKind ?? AdCreativeKind.image;
  late final headline = TextEditingController(text: widget.creative?.headline);
  late final body = TextEditingController(text: widget.creative?.body);
  late final destination = TextEditingController(text: widget.creative?.destinationUrl);
  late String cta = widget.creative?.callToAction ?? 'learn_more';
  late List<AdCreativeMedia> media = [...?widget.creative?.media];
  double? progress;
  bool saving = false;
  @override void dispose() { headline.dispose(); body.dispose(); destination.dispose(); super.dispose(); }
  Future<void> _pick() async { try { final upload = kind == AdCreativeKind.video ? await MediaSourcePicker.video(context, ref.read(mediaUploadServiceProvider)) : await MediaSourcePicker.singleImage(context, ref.read(mediaUploadServiceProvider), maxDimension: 1600); if (upload == null) return; final tracker = UploadProgress(); final sub = tracker.stream.listen((value) { if (mounted) setState(() => progress = value); }); final uploaded = await ref.read(adsRepositoryProvider).uploadCreative(upload, progress: tracker); await sub.cancel(); await tracker.close(); if (mounted) setState(() { media = [uploaded]; progress = null; }); } on AppException catch (error) { if (mounted) _error(context, error); } }
  Future<void> _save() async { setState(() => saving = true); try { await ref.read(adsRepositoryProvider).upsertCreative(accountId: widget.account.id, id: widget.creative?.id, kind: kind, headline: headline.text.trim(), body: body.text.trim(), callToAction: cta, destinationType: 'url', destinationUrl: destination.text.trim(), media: media); if (mounted) context.pop(true); } on AppException catch (error) { if (mounted) _error(context, error); } finally { if (mounted) setState(() => saving = false); } }
  @override Widget build(BuildContext context) => Material(color: LightModeColors.lightSurface, child: CustomScrollView(slivers: [SliverAppBar(title: Text(widget.creative == null ? 'ads.creatives.create_title'.tr() : 'ads.creatives.edit_title'.tr()), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop(false))), SliverPadding(padding: const EdgeInsets.all(AppSpacing.lg), sliver: SliverToBoxAdapter(child: LayoutBuilder(builder: (context, box) { final preview = AdPreviewCard(client: ref.watch(supabaseClientProvider), advertiserName: widget.account.pageName ?? widget.account.name, advertiserAvatar: widget.account.pageAvatarUrl, headline: headline.text, body: body.text, cta: cta, media: media); final form = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [HBFormField(label: 'ads.creatives.kind'.tr(), child: HBSelect(value: kind, items: [for (final value in AdCreativeKind.values) HBSelectItem(value: value, label: value.labelKey.tr())], onChanged: (value) => setState(() => kind = value!))), const SizedBox(height: AppSpacing.md), if ({AdCreativeKind.image, AdCreativeKind.video, AdCreativeKind.carousel}.contains(kind)) ...[HBButton.secondary(label: 'ads.creatives.upload'.tr(), icon: Icons.upload_rounded, onPressed: _pick), if (progress != null) HBUploadProgress(progress: progress!)], const SizedBox(height: AppSpacing.md), HBFormField(label: 'ads.creatives.headline'.tr(), required: kind != AdCreativeKind.listing && kind != AdCreativeKind.event && kind != AdCreativeKind.page, child: HBInput(controller: headline, maxLength: 60, onChanged: (_) => setState(() {}))), const SizedBox(height: AppSpacing.md), HBFormField(label: 'ads.creatives.body'.tr(), child: HBInput(controller: body, maxLength: 300, maxLines: 4, onChanged: (_) => setState(() {}))), const SizedBox(height: AppSpacing.md), HBFormField(label: 'ads.creatives.destination'.tr(), required: true, child: HBInput(controller: destination, keyboardType: TextInputType.url)), const SizedBox(height: AppSpacing.md), HBFormField(label: 'ads.creatives.cta'.tr(), child: HBSelect(value: cta, items: [for (final value in const ['learn_more', 'shop_now', 'sign_up', 'contact_us']) HBSelectItem(value: value, label: 'ads.cta.$value'.tr())], onChanged: (value) => setState(() => cta = value!))), const SizedBox(height: AppSpacing.lg), Text('ads.creatives.review_note'.tr(), style: context.textStyles.bodySmall), const SizedBox(height: AppSpacing.sm), HBButton.primary(label: 'common.save'.tr(), isLoading: saving, onPressed: saving ? null : _save)]); return box.maxWidth > 800 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: form), const SizedBox(width: AppSpacing.xl), Expanded(child: preview)]) : Column(children: [preview, const SizedBox(height: AppSpacing.lg), form]); }))) ]));
}

class AdMembersTab extends ConsumerWidget {
  final AdAccount account;
  final bool readOnly;
  const AdMembersTab({super.key, required this.account, required this.readOnly});
  Future<void> _add(BuildContext context, WidgetRef ref) async { final result = await showModalBottomSheet<({String userId, AdAccountRole role})>(context: context, isScrollControlled: true, builder: (_) => AdMemberForm(account: account)); if (result == null) return; try { await ref.read(adsRepositoryProvider).addMember(accountId: account.id, userId: result.userId, role: result.role); ref.invalidate(adAccountMembersProvider(account.id)); } on AppException catch (error) { if (context.mounted) _error(context, error); } }
  @override Widget build(BuildContext context, WidgetRef ref) { final manager = (account.myRole == AdAccountRole.owner || account.myRole == AdAccountRole.admin) && !readOnly; final myId = ref.watch(authSessionProvider).value?.user.id; return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Expanded(child: Text('ads.members.title'.tr(), style: context.textStyles.titleLarge)), if (manager) HBButton.primary(label: 'ads.members.add'.tr(), icon: Icons.person_add_alt_1_rounded, onPressed: () => _add(context, ref))]), const SizedBox(height: AppSpacing.md), ref.watch(adAccountMembersProvider(account.id)).when(loading: () => const HBListSkeleton(), error: (_, __) => _Retry(onRetry: () => ref.invalidate(adAccountMembersProvider(account.id))), data: (members) => members.isEmpty ? HBEmptyState(icon: Icons.people_outline_rounded, title: 'ads.members.empty'.tr(), message: 'ads.members.empty_message'.tr()) : HBCard(child: Column(children: [for (final member in members) ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(size: 40, name: member.displayName, imageUrl: member.avatarUrl), title: Text(member.displayName ?? member.username ?? ''), subtitle: Text('@${member.username ?? ''} · ${member.role.labelKey.tr()}'), trailing: member.role == AdAccountRole.owner ? Text('ads.members.owner_locked'.tr()) : manager || member.userId == myId ? PopupMenuButton<String>(onSelected: (value) async { if (value == 'remove') { try { await ref.read(adsRepositoryProvider).removeMember(accountId: account.id, userId: member.userId); ref.invalidate(adAccountMembersProvider(account.id)); if (member.userId == myId && context.mounted) context.go(AppRoutes.ads); } on AppException catch (error) { if (context.mounted) _error(context, error); } } }, itemBuilder: (_) => [PopupMenuItem(value: 'remove', child: Text(member.userId == myId ? 'ads.members.leave'.tr() : 'common.remove'.tr()))]) : null)]))) ]); }
}

class AdMemberForm extends ConsumerStatefulWidget {
  final AdAccount account;
  const AdMemberForm({super.key, required this.account});
  @override ConsumerState<AdMemberForm> createState() => _AdMemberFormState();
}
class _AdMemberFormState extends ConsumerState<AdMemberForm> {
  final search = TextEditingController();
  List<UserProfile> results = const [];
  UserProfile? selected;
  AdAccountRole role = AdAccountRole.advertiser;
  bool loading = false;
  @override void dispose() { search.dispose(); super.dispose(); }
  Future<void> _search() async { setState(() => loading = true); try { final values = await ref.read(pageRepositoryProvider).searchProfiles(search.text); if (mounted) setState(() => results = values); } finally { if (mounted) setState(() => loading = false); } }
  @override Widget build(BuildContext context) { final roles = [AdAccountRole.advertiser, AdAccountRole.analyst, if (widget.account.myRole == AdAccountRole.owner) AdAccountRole.admin]; return SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('ads.members.add'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: HBInput(controller: search, hint: 'ads.members.search'.tr(), onSubmitted: (_) => _search())), const SizedBox(width: AppSpacing.sm), HBButton.icon(icon: Icons.search, tooltip: 'common.search'.tr(), onPressed: _search)]), if (loading) const LinearProgressIndicator(), for (final user in results) ListTile(selected: selected?.id == user.id, leading: HBAvatar(size: 36, name: user.displayName, imageUrl: user.avatarUrl), title: Text(user.displayName), subtitle: Text('@${user.username}'), onTap: () => setState(() => selected = user)), const SizedBox(height: AppSpacing.md), HBSelect(value: role, items: [for (final value in roles) HBSelectItem(value: value, label: value.labelKey.tr())], onChanged: (value) => setState(() => role = value!)), const SizedBox(height: AppSpacing.lg), HBButton.primary(label: 'ads.members.add'.tr(), onPressed: selected == null ? null : () => context.pop((userId: selected!.id, role: role)))]))); }
}

class _Retry extends StatelessWidget { final VoidCallback onRetry; const _Retry({required this.onRetry}); @override Widget build(BuildContext context) => HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'ads.errors.load_title'.tr(), message: 'ads.errors.load_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: onRetry))); }
HBStatusKind _campaignKind(AdCampaignStatus status) => switch (status) { AdCampaignStatus.inReview || AdCampaignStatus.paused => HBStatusKind.pending, AdCampaignStatus.active => HBStatusKind.approved, AdCampaignStatus.scheduled => HBStatusKind.info, AdCampaignStatus.rejected => HBStatusKind.rejected, _ => HBStatusKind.neutral };
List<AdCampaignStatus> _campaignActions(AdCampaignStatus status) => switch (status) { AdCampaignStatus.draft => [AdCampaignStatus.archived], AdCampaignStatus.inReview => [AdCampaignStatus.draft, AdCampaignStatus.archived], AdCampaignStatus.active || AdCampaignStatus.scheduled => [AdCampaignStatus.paused, AdCampaignStatus.archived], AdCampaignStatus.paused => [AdCampaignStatus.active, AdCampaignStatus.archived], AdCampaignStatus.rejected => [AdCampaignStatus.draft, AdCampaignStatus.archived], _ => [AdCampaignStatus.archived] };
void _error(BuildContext context, AppException error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));