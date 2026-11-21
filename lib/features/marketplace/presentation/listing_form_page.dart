import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_source_picker.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_image_cropper.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_place_field.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/marketplace/domain/listing.dart';
import 'package:hb_social/features/marketplace/domain/marketplace_category.dart';
import 'package:hb_social/features/marketplace/providers/marketplace_providers.dart';
import 'package:hb_social/features/pages/providers/page_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:image/image.dart' as img;
import 'package:latlong2/latlong.dart';

class ListingFormPage extends ConsumerStatefulWidget {
  final String? listingId;
  const ListingFormPage({super.key, this.listingId});
  @override ConsumerState<ListingFormPage> createState() => _ListingFormPageState();
}

class _ListingFormPageState extends ConsumerState<ListingFormPage> {
  final title = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final municipalityText = TextEditingController();
  final attributes = <String, TextEditingController>{};
  int step = 0;
  String? categoryId;
  String categorySlug = '';
  ListingCondition condition = ListingCondition.good;
  Municipality? municipality;
  String? regionId;
  String currency = 'EUR';
  bool gift = false;
  bool negotiable = false;
  bool shipping = false;
  bool pickupPoint = false;
  double? lat;
  double? lng;
  bool saving = false;
  bool loaded = false;
  ListingStatus originalStatus = ListingStatus.draft;
  final media = <ListingFormMedia>[];

  bool get editing => widget.listingId != null;

  bool get isFirearms => categorySlug.contains('firearm');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded && !editing) {
      loaded = true;
      final settings = ref.read(userSettingsProvider);
      currency = settings.currencyCode;
      regionId = settings.regionId;
      final municipalityId = settings.municipalityId;
      if (municipalityId != null) ref.read(referenceRepositoryProvider).getMunicipality(municipalityId).then((value) { if (mounted && value != null) setState(() { municipality = value; municipalityText.text = value.compactName; regionId = value.regionId; }); });
    }
  }

  @override
  void dispose() { title.dispose(); description.dispose(); price.dispose(); municipalityText.dispose(); for (final controller in attributes.values) controller.dispose(); super.dispose(); }

  void load(ListingDetail detail) {
    if (loaded) return;
    loaded = true;
    final listing = detail.listing;
    originalStatus = listing.status;
    categoryId = listing.categoryId;
    categorySlug = listing.categorySlug;
    condition = listing.condition;
    title.text = listing.title;
    description.text = detail.description ?? '';
    price.text = _major(listing.originalPrice.amountMinor);
    gift = listing.originalPrice.amountMinor == 0;
    currency = listing.originalPrice.currencyCode;
    negotiable = listing.negotiable;
    shipping = listing.shippingAvailable;
    regionId = listing.regionId;
    lat = listing.lat;
    lng = listing.lng;
    pickupPoint = lat != null && lng != null;
    municipalityText.text = listing.municipality ?? '';
    for (final entry in detail.attributes.entries) _attribute(entry.key).text = entry.value.toString();
    media.addAll(detail.media.map((item) => ListingFormMedia.existing(item.storagePath, item.path)));
    if (listing.municipalityId != null) ref.read(referenceRepositoryProvider).getMunicipality(listing.municipalityId!).then((value) { if (mounted && value != null) setState(() { municipality = value; municipalityText.text = value.compactName; }); });
  }

  TextEditingController _attribute(String key) => attributes.putIfAbsent(key, TextEditingController.new);

  @override
  Widget build(BuildContext context) {
    if (editing) return ref.watch(listingDetailProvider(widget.listingId!)).when(loading: () => const PageColumns(center: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: LinearProgressIndicator())), error: (_, __) => PageColumns(center: ListingFormUnavailable(onBack: () => context.go(AppRoutes.marketplace))), data: (detail) { if (!detail.isMine || !const {ListingStatus.draft, ListingStatus.active, ListingStatus.reserved, ListingStatus.expired}.contains(detail.listing.status)) return PageColumns(center: ListingFormUnavailable(onBack: () => context.go(AppRoutes.marketplace))); load(detail); return _content(context); });
    return _content(context);
  }

  Widget _content(BuildContext context) {
    final categories = ref.watch(marketplaceCategoriesProvider).value ?? const <MarketplaceCategory>[];
    final category = categories.where((item) => item.id == categoryId).firstOrNull;
    final gunShopPage = (ref.watch(myPagesProvider).value ?? const []).where((page) => page.category == 'gun_shop' && page.verificationStatus == 'verified').firstOrNull;
    final labels = ['marketplace.form.steps.what'.tr(), 'marketplace.form.steps.describe'.tr(), 'marketplace.form.steps.price_place'.tr()];
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      Row(children: [Tooltip(message: 'common.back'.tr(), child: HBButton.icon(icon: Icons.arrow_back_rounded, onPressed: () => context.pop())), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(editing ? 'marketplace.form.edit_title'.tr() : 'marketplace.form.new_title'.tr(), style: context.textStyles.headlineSmall))]),
      const SizedBox(height: AppSpacing.md), ListingStepHeader(labels: labels, selected: step, onChanged: (value) => setState(() => step = value)),
      if (category?.requiresReview == true) ...[const SizedBox(height: AppSpacing.sm), HBCard(color: LightModeColors.lightWarning.withValues(alpha: 0.1), child: Row(children: [const Icon(Icons.fact_check_outlined), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('p42.marketplace_review.category_warning'.tr()))]))],
      const SizedBox(height: AppSpacing.md), HBCard(padding: EdgeInsets.all(MediaQuery.sizeOf(context).width >= 700 ? AppSpacing.lg : AppSpacing.md), child: AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: switch (step) { 0 => ListingWhatStep(key: const ValueKey(0), categoryId: categoryId, condition: condition, onCategory: (value) => setState(() { categoryId = value.id; categorySlug = value.slug; if (value.isRestricted) { shipping = false; negotiable = false; if (value.allowedTypes.isNotEmpty && _attribute('firearm_type').text.isEmpty) _attribute('firearm_type').text = value.allowedTypes.first; } }), onCondition: (value) => setState(() => condition = value)), 1 => ListingDescriptionStep(key: const ValueKey(1), category: category, shopName: gunShopPage?.name, title: title, description: description, attribute: _attribute, media: media, onPick: pickImages, onRemove: (index) => setState(() => media.removeAt(index)), onReorder: (oldIndex, newIndex) => setState(() { if (newIndex > oldIndex) newIndex--; final item = media.removeAt(oldIndex); media.insert(newIndex, item); })), _ => ListingPricePlaceStep(key: const ValueKey(2), mediated: category?.mode == 'mediated_showcase', price: price, gift: gift, currency: currency, negotiable: negotiable, shipping: shipping, municipalityText: municipalityText, municipality: municipality, regionId: regionId, lat: lat, lng: lng, pickupPoint: pickupPoint, onGift: (value) => setState(() => gift = value), onCurrency: (value) => setState(() => currency = value), onNegotiable: (value) => setState(() => negotiable = value), onShipping: (value) => setState(() => shipping = value), onMunicipality: (value) => setState(() { municipality = value; regionId = value.regionId; municipalityText.text = value.compactName; lat = pickupPoint ? value.lat : null; lng = pickupPoint ? value.lng : null; }), onRegion: (value) => setState(() { regionId = value; municipality = null; municipalityText.clear(); }), onPickup: (value) => setState(() { pickupPoint = value; lat = value ? municipality?.lat : null; lng = value ? municipality?.lng : null; }), onPoint: (point) => setState(() { lat = point.latitude; lng = point.longitude; })) })),
      const SizedBox(height: AppSpacing.md), ListingFormNavigation(step: step, saving: saving, editing: editing, onBack: step == 0 ? null : () => setState(() => step--), onNext: step == 2 ? null : next, onDraft: step == 2 ? () => save(ListingStatus.draft) : null, onPublish: step == 2 ? () => save(ListingStatus.active) : null),
    ]))]));
  }

  void next() {
    if (step == 0 && categoryId == null) { _show('marketplace.form.errors.category_required'); return; }
    if (step == 1 && (title.text.trim().length < 3 || title.text.trim().length > 120 || description.text.length > 5000)) { _show('marketplace.form.errors.description_invalid'); return; }
    if (step == 1 && categorySlug.contains('firearm') && ['firearm_type', 'caliber', 'make'].any((key) => _attribute(key).text.trim().isEmpty)) { _show('marketplace.firearms.attributes_required'); return; }
    setState(() => step++);
  }

  Future<void> pickImages() async {
    try {
      final picked = await MediaSourcePicker.postImages(context, ref.read(mediaUploadServiceProvider), remaining: 10 - media.length);
      for (final item in picked) {
        if (!mounted) return;
        final decoded = img.decodeImage(item.bytes);
        if (decoded == null) continue;
        final ratio = decoded.width / decoded.height;
        final width = decoded.width >= decoded.height ? 1600 : (1600 * ratio).round();
        final height = decoded.height > decoded.width ? 1600 : (1600 / ratio).round();
        final cropped = await HBImageCropper.show(context, bytes: item.bytes, aspectRatio: ratio, outputWidth: width, outputHeight: height, jpegQuality: 85);
        if (cropped != null && mounted) setState(() => media.add(ListingFormMedia.pending(cropped)));
      }
    } on AppException catch (error) { _show(error.messageKey); }
  }

  Future<void> save(ListingStatus requested) async {
    if (categoryId == null || title.text.trim().length < 3 || title.text.trim().length > 120 || description.text.length > 5000 || (municipality == null && regionId == null)) { _show('marketplace.form.errors.required'); return; }
    final amount = gift ? 0 : _minor(price.text);
    if (amount == null || amount < 0) { _show('marketplace.form.errors.price_invalid'); return; }
    setState(() => saving = true);
    final repository = ref.read(marketplaceRepositoryProvider);
    final uploader = ref.read(mediaUploadServiceProvider);
    try {
      final id = await repository.upsertListing(id: widget.listingId, categoryId: categoryId!, title: title.text, description: description.text, priceMinor: amount, currencyCode: currency, condition: condition, regionId: regionId, municipalityId: municipality?.id, lat: pickupPoint ? lat : null, lng: pickupPoint ? lng : null, negotiable: isFirearms ? false : negotiable, shippingAvailable: isFirearms ? false : shipping, attributes: {for (final entry in attributes.entries) if (entry.value.text.trim().isNotEmpty) entry.key: _attributeValue(entry.key, entry.value.text)}, status: requested);
      for (final item in media.where((item) => item.bytes != null)) {
        item.progress = 0;
        if (mounted) setState(() {});
        final uploaded = await uploader.uploadToBucket(bucket: 'listing-media', userId: ref.read(currentProfileProvider).value!.id, upload: PreparedUpload(bytes: item.bytes!, extension: 'jpg', contentType: 'image/jpeg'), isPublic: true, progress: item.uploadProgress..stream.listen((value) { item.progress = value; if (mounted) setState(() {}); }));
        item.path = uploaded.path;
        item.url = uploaded.publicUrl;
      }
      final removed = await repository.setListingMedia(id, media.map((item) => item.path).whereType<String>().toList());
      for (final path in removed) await uploader.delete('listing-media', path);
      if (editing && originalStatus == ListingStatus.reserved && requested == ListingStatus.active) await repository.setStatus(id, ListingStatus.reserved);
      ref.invalidate(listingsProvider); ref.invalidate(favoritesProvider); ref.invalidate(myListingsProvider); ref.invalidate(listingDetailProvider(id));
      final submittedForReview = requested == ListingStatus.active && (await repository.myListings(ListingStatus.inReview)).any((item) => item.listing.id == id && item.reviewStatus == 'pending');
      if (mounted) { context.go(submittedForReview ? AppRoutes.marketplaceMine : AppRoutes.marketplaceDetailPath(id)); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((requested == ListingStatus.draft ? 'marketplace.form.draft_saved' : submittedForReview ? 'p42.marketplace_review.submitted' : 'marketplace.form.published').tr()))); }
    } on AppException catch (error) { if (error.messageKey == 'marketplace.gun_shop_page_required') { final page = (ref.read(myPagesProvider).value ?? const []).where((item) => item.category == 'gun_shop').firstOrNull; if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()), action: SnackBarAction(label: 'marketplace.firearms.open_verification'.tr(), onPressed: () => context.push(page == null ? AppRoutes.verification : AppRoutes.pageStudioPath(page.slug))))); } else { _show(error.messageKey); } } finally { if (mounted) setState(() => saving = false); }
  }

  void _show(String key) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr()))); }
}

class ListingFormMedia {
  Uint8List? bytes;
  String? path;
  String? url;
  double? progress;
  final UploadProgress uploadProgress = UploadProgress();
  ListingFormMedia.pending(this.bytes);
  ListingFormMedia.existing(this.path, this.url);
}

class ListingStepHeader extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const ListingStepHeader({super.key, required this.labels, required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(children: [
    for (var index = 0; index < labels.length; index++)
      Expanded(child: InkWell(onTap: index <= selected ? () => onChanged(index) : null, child: Column(children: [
        CircleAvatar(radius: 16, backgroundColor: index <= selected ? LightModeColors.lightPrimary : LightModeColors.lightBackgroundSoft, child: Text('${index + 1}', style: TextStyle(color: index <= selected ? Colors.white : LightModeColors.lightOnSurfaceVariant))),
        const SizedBox(height: 4),
        Text(labels[index], maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall, textAlign: TextAlign.center),
      ]))),
  ]);
}

class ListingWhatStep extends ConsumerWidget {
  final String? categoryId;
  final ListingCondition condition;
  final ValueChanged<MarketplaceCategory> onCategory;
  final ValueChanged<ListingCondition> onCondition;
  const ListingWhatStep({super.key, required this.categoryId, required this.condition, required this.onCategory, required this.onCondition});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(marketplaceCategoriesProvider);
    final gunShop = ref.watch(currentProfileProvider).value?.verificationLevel == 'gun_shop';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [HBFormSection(title: 'marketplace.form.what_title'.tr(), children: [categories.when(loading: () => const LinearProgressIndicator(), error: (_, __) => Text('marketplace.error_message'.tr()), data: (items) => LayoutBuilder(builder: (context, constraints) => Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final category in items.where((item) => item.available && (!item.isRestricted || gunShop))) SizedBox(width: constraints.maxWidth >= 600 ? (constraints.maxWidth - 16) / 3 : (constraints.maxWidth - 8) / 2, child: ListingCategoryChoice(category: category, selected: category.id == categoryId, enabled: true, onTap: () => onCategory(category)))])))]), const HBFormSectionDivider(), HBFormSection(title: 'marketplace.form.condition'.tr(), children: [HBChoice<ListingCondition>(options: ListingCondition.values, value: condition, onChanged: onCondition, labelBuilder: (value) => value.labelKey.tr(), descriptions: {for (final value in ListingCondition.values) value: 'marketplace.form.condition_help.${value.code}'.tr()})])]);
  }
}

class ListingCategoryChoice extends StatelessWidget {
  final MarketplaceCategory category;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  const ListingCategoryChoice({super.key, required this.category, required this.selected, required this.enabled, required this.onTap});
  @override Widget build(BuildContext context) => Opacity(opacity: enabled ? 1 : .55, child: HBCard(color: selected ? LightModeColors.lightPrimarySoft : LightModeColors.lightBackgroundSoft, padding: const EdgeInsets.all(AppSpacing.md), child: InkWell(onTap: enabled ? onTap : () => context.push(AppRoutes.verification), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(_categoryIcon(category.slug), color: selected ? LightModeColors.lightPrimary : LightModeColors.lightOnSurfaceVariant), const SizedBox(height: AppSpacing.xs), Text(category.nameKey.tr(), style: context.textStyles.labelLarge), if (category.isRestricted) Text(enabled ? 'marketplace.form.firearms_note'.tr() : 'marketplace.form.request_gun_shop'.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant), maxLines: 2)]))));
}

class ListingDescriptionStep extends StatelessWidget {
  final MarketplaceCategory? category;
  final String? shopName;
  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController Function(String) attribute;
  final List<ListingFormMedia> media;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;
  final ReorderCallback onReorder;
  const ListingDescriptionStep({super.key, required this.category, this.shopName, required this.title, required this.description, required this.attribute, required this.media, required this.onPick, required this.onRemove, required this.onReorder});
  @override Widget build(BuildContext context) { final firearms = category?.mode == 'mediated_showcase'; return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [HBFormSection(title: 'marketplace.form.describe_title'.tr(), children: [if (firearms) ...[Text('marketplace.firearms.serial_warning'.tr(), style: context.textStyles.bodyMedium?.copyWith(color: LightModeColors.lightError)), const SizedBox(height: AppSpacing.sm), if (category!.allowedTypes.isNotEmpty) HBFormField(label: 'marketplace.firearms.type_label'.tr(), required: true, child: HBChoice<String>(options: category!.allowedTypes, value: attribute('firearm_type').text, onChanged: (value) => attribute('firearm_type').text = value, labelBuilder: (value) => 'marketplace.firearms.type.$value'.tr()))], HBFormField(label: 'marketplace.form.title'.tr(), required: true, child: HBInput(controller: title, maxLength: 120)), HBFormField(label: 'marketplace.form.description'.tr(), helper: firearms ? 'marketplace.firearms.description_help'.tr() : 'marketplace.form.description_help'.tr(), child: HBInput(controller: description, maxLines: 7, maxLength: 5000)), if (firearms) ...[for (final key in ['caliber', 'make', 'model', 'year', 'barrel_length', 'transfer_notes']) HBFormField(label: 'marketplace.firearms.field.$key'.tr(), required: const {'caliber', 'make'}.contains(key), child: HBInput(controller: attribute(key), keyboardType: {'year', 'barrel_length'}.contains(key) ? TextInputType.number : TextInputType.text)), if (shopName != null) Text('marketplace.firearms.pickup_shop'.tr(namedArgs: {'name': shopName!}))] else if (_fields(category?.slug ?? '').isNotEmpty) ...[for (final key in _fields(category?.slug ?? '')) HBFormField(label: 'marketplace.attribute_extra.$key'.tr(), child: key == 'pedigree' ? HBSelect<String>(value: attribute(key).text.isEmpty ? null : attribute(key).text, options: [HBSelectOption(value: 'true', label: 'marketplace.form.yes'.tr()), HBSelectOption(value: 'false', label: 'marketplace.form.no'.tr())], onChanged: (value) => attribute(key).text = value ?? '') : HBInput(controller: attribute(key), keyboardType: {'year', 'km', 'age', 'duration'}.contains(key) ? TextInputType.number : TextInputType.text))]]), const HBFormSectionDivider(), HBFormSection(title: 'marketplace.form.photos'.tr(), subtitle: 'marketplace.form.photos_help'.tr(), children: [ListingPhotosField(media: media, onPick: onPick, onRemove: onRemove, onReorder: onReorder)])]); }
}

class ListingPhotosField extends StatelessWidget {
  final List<ListingFormMedia> media;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;
  final ReorderCallback onReorder;
  const ListingPhotosField({super.key, required this.media, required this.onPick, required this.onRemove, required this.onReorder});
  @override Widget build(BuildContext context) => Column(children: [if (media.isNotEmpty) SizedBox(height: 150, child: ReorderableListView.builder(scrollDirection: Axis.horizontal, itemCount: media.length, onReorder: onReorder, itemBuilder: (context, index) { final item = media[index]; return Container(key: ValueKey(item), width: 130, margin: const EdgeInsets.only(right: AppSpacing.sm), child: Column(children: [Expanded(child: Stack(fit: StackFit.expand, children: [ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: item.bytes != null ? Image.memory(item.bytes!, fit: BoxFit.cover) : Image.network(item.url!, fit: BoxFit.cover)), Positioned(top: 4, right: 4, child: IconButton.filled(onPressed: () => onRemove(index), icon: const Icon(Icons.close_rounded, size: 18))), if (index == 0) Positioned(left: 4, bottom: 4, child: Container(color: LightModeColors.lightSurface, padding: const EdgeInsets.all(4), child: Text('marketplace.form.cover'.tr(), style: context.textStyles.labelSmall))) ])), if (item.progress != null) HBUploadProgress(progress: item.progress)]) ); })), const SizedBox(height: AppSpacing.sm), Align(alignment: Alignment.centerLeft, child: HBButton.secondary(label: 'marketplace.form.add_photos'.tr(), icon: Icons.add_photo_alternate_outlined, onPressed: media.length >= 10 ? null : onPick))]);
}

class ListingPricePlaceStep extends ConsumerWidget {
  final bool mediated;
  final TextEditingController price;
  final bool gift;
  final String currency;
  final bool negotiable;
  final bool shipping;
  final TextEditingController municipalityText;
  final Municipality? municipality;
  final String? regionId;
  final double? lat;
  final double? lng;
  final bool pickupPoint;
  final ValueChanged<bool> onGift;
  final ValueChanged<String> onCurrency;
  final ValueChanged<bool> onNegotiable;
  final ValueChanged<bool> onShipping;
  final ValueChanged<Municipality> onMunicipality;
  final ValueChanged<String?> onRegion;
  final ValueChanged<bool> onPickup;
  final ValueChanged<LatLng> onPoint;
  const ListingPricePlaceStep({super.key, required this.mediated, required this.price, required this.gift, required this.currency, required this.negotiable, required this.shipping, required this.municipalityText, required this.municipality, required this.regionId, required this.lat, required this.lng, required this.pickupPoint, required this.onGift, required this.onCurrency, required this.onNegotiable, required this.onShipping, required this.onMunicipality, required this.onRegion, required this.onPickup, required this.onPoint});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final currencies = ref.watch(currenciesProvider).value ?? const <ReferenceCurrency>[];
    final regions = settings.countryCode == null ? const <ReferenceRegion>[] : ref.watch(regionsProvider(settings.countryCode!)).value ?? const [];
    final symbol = currencies.where((item) => item.code == currency).firstOrNull?.symbol ?? currency;
    return Column(children: [HBFormSection(title: 'marketplace.form.price_title'.tr(), children: [if (!mediated) SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('marketplace.form.gift'.tr()), value: gift, onChanged: onGift), Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: HBFormField(label: 'marketplace.form.price'.tr(), required: !gift, child: HBInput(controller: price, enabled: !gift, hint: symbol, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))]))), const SizedBox(width: AppSpacing.md), Expanded(child: HBFormField(label: 'marketplace.form.currency'.tr(), child: HBSelect<String>(value: currency, options: currencies.map((item) => HBSelectOption(value: item.code, label: '${item.code} ${item.symbol}')).toList(), onChanged: (value) { if (value != null) onCurrency(value); }))) ]), if (!mediated) SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('marketplace.negotiable'.tr()), value: negotiable, onChanged: onNegotiable), if (!mediated) SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('marketplace.form.shipping_available'.tr()), value: shipping, onChanged: onShipping), if (mediated) Text('marketplace.firearms.no_shipping'.tr())]), const HBFormSectionDivider(), HBFormSection(title: 'marketplace.form.place_title'.tr(), children: [HBFormField(label: 'marketplace.municipality'.tr(), child: HBPlaceField<Municipality>(controller: municipalityText, hint: 'marketplace.municipality_hint'.tr(), search: (query) async => [for (final item in await ref.read(referenceRepositoryProvider).searchMunicipalities(query, countryCode: settings.countryCode ?? 'IT', regionId: regionId)) HBPlaceSuggestion(value: item, title: item.compactName, subtitle: item.regionName)], onSelected: onMunicipality)), Text('marketplace.form.or_region'.tr(), style: context.textStyles.labelSmall), HBFormField(label: 'marketplace.region'.tr(), child: HBSelect<String>(value: regionId, allowClear: true, options: regions.map((item) => HBSelectOption(value: item.id, label: item.name)).toList(), onChanged: onRegion)), if (!mediated) SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('marketplace.form.pickup_point'.tr()), subtitle: Text('marketplace.form.pickup_point_help'.tr()), value: pickupPoint, onChanged: municipality?.lat == null ? null : onPickup), if (!mediated && municipality?.lat != null && municipality?.lng != null) ListingPickupMap(center: LatLng(lat ?? municipality!.lat!, lng ?? municipality!.lng!), exact: pickupPoint, onPoint: pickupPoint ? onPoint : null)])]);
  }
}

class ListingPickupMap extends StatelessWidget {
  final LatLng center;
  final bool exact;
  final ValueChanged<LatLng>? onPoint;
  const ListingPickupMap({super.key, required this.center, required this.exact, this.onPoint});
  @override Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SizedBox(height: 190, child: FlutterMap(options: MapOptions(initialCenter: center, initialZoom: 12, onTap: (_, point) => onPoint?.call(point)), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hbsocial.app'), if (exact) MarkerLayer(markers: [Marker(point: center, width: 44, height: 44, child: const Icon(Icons.location_pin, color: LightModeColors.lightPrimary, size: 42))]) else CircleLayer(circles: [CircleMarker(point: center, radius: 38, color: LightModeColors.lightPrimary.withValues(alpha: .18), borderColor: LightModeColors.lightPrimary, borderStrokeWidth: 2)]), RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')])] )));
}

class ListingFormNavigation extends StatelessWidget {
  final int step;
  final bool saving;
  final bool editing;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onDraft;
  final VoidCallback? onPublish;
  const ListingFormNavigation({super.key, required this.step, required this.saving, required this.editing, this.onBack, this.onNext, this.onDraft, this.onPublish});
  @override Widget build(BuildContext context) => Wrap(alignment: WrapAlignment.end, spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [if (onBack != null) HBButton.ghost(label: 'common.back'.tr(), onPressed: saving ? null : onBack), if (onNext != null) HBButton.primary(label: 'common.next'.tr(), onPressed: onNext), if (onDraft != null && !editing) HBButton.secondary(label: 'marketplace.form.save_draft'.tr(), onPressed: saving ? null : onDraft), if (onPublish != null) HBButton.primary(label: editing ? 'marketplace.form.save'.tr() : 'marketplace.form.publish'.tr(), onPressed: saving ? null : onPublish, isLoading: saving)]);
}

class ListingFormUnavailable extends StatelessWidget {
  final VoidCallback onBack;
  const ListingFormUnavailable({super.key, required this.onBack});
  @override Widget build(BuildContext context) => HBCard(child: Column(children: [Text('marketplace.not_found_message'.tr()), const SizedBox(height: AppSpacing.md), HBButton.secondary(label: 'common.back'.tr(), onPressed: onBack)]));
}

List<String> _fields(String slug) {
  if (slug.contains('optic')) return const ['brand', 'model', 'magnification'];
  if (slug.contains('cloth') || slug.contains('apparel')) return const ['brand', 'size'];
  if (slug.contains('dog')) return const ['breed', 'age', 'pedigree'];
  if (slug.contains('vehicle')) return const ['brand', 'model', 'year', 'km'];
  if (slug.contains('firearm')) return const ['brand', 'model', 'caliber'];
  if (slug.contains('service')) return const ['duration'];
  return const [];
}

Object _attributeValue(String key, String value) { if (key == 'pedigree') return value == 'true'; if ({'age', 'year', 'km', 'duration'}.contains(key)) return int.tryParse(value) ?? value; return value.trim(); }
int? _minor(String value) { final normalized = value.trim().replaceAll(',', '.'); if (normalized.isEmpty) return null; final parts = normalized.split('.'); final whole = int.tryParse(parts.first); if (whole == null) return null; final fraction = parts.length > 1 ? parts[1].padRight(2, '0').substring(0, 2) : '00'; return whole * 100 + (int.tryParse(fraction) ?? 0); }
String _major(int value) => '${value ~/ 100},${(value % 100).toString().padLeft(2, '0')}';
IconData _categoryIcon(String slug) => slug.contains('optic') ? Icons.visibility_outlined : slug.contains('cloth') || slug.contains('apparel') ? Icons.checkroom_outlined : slug.contains('dog') ? Icons.pets_outlined : slug.contains('vehicle') ? Icons.directions_car_outlined : slug.contains('firearm') ? Icons.shield_outlined : slug.contains('service') ? Icons.handyman_outlined : Icons.inventory_2_outlined;