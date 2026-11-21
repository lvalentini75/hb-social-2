import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/features/verification/domain/verification_request.dart';
import 'package:hb_social/features/verification/providers/verification_providers.dart';

class VerificationWizard extends ConsumerStatefulWidget {
  final BadgeType? fixedType;
  final String? pageId;
  const VerificationWizard({super.key, this.fixedType, this.pageId});
  @override
  ConsumerState<VerificationWizard> createState() => _VerificationWizardState();
}

class _VerificationWizardState extends ConsumerState<VerificationWizard> {
  int _step = 0;
  late BadgeType _type = widget.fixedType ?? BadgeType.hunter;
  final _licence = TextEditingController();
  final _issuer = TextEditingController();
  final _company = TextEditingController();
  final _vat = TextEditingController();
  final _association = TextEditingController();
  final _taxCode = TextEditingController();
  DateTime? _expiresOn;
  final List<VerificationDocument> _documents = [];
  double _progress = 0;
  String? _error;
  bool _working = false;
  bool _submitted = false;

  @override
  void dispose() { for (final controller in [_licence, _issuer, _company, _vat, _association, _taxCode]) { controller.dispose(); } if (!_submitted) { for (final document in _documents) { ref.read(verificationRepositoryProvider).removeDocument(document.path); } } super.dispose(); }

  List<DocumentKind> get _recommended => switch (_type) {BadgeType.hunter => [DocumentKind.licenceFront, DocumentKind.licenceBack, DocumentKind.idDocument], BadgeType.gunShop => [DocumentKind.chamberRegistration, DocumentKind.vatCertificate], BadgeType.guide => [DocumentKind.guideLicence, DocumentKind.idDocument], BadgeType.association => [DocumentKind.associationStatute, DocumentKind.idDocument], BadgeType.page => [DocumentKind.chamberRegistration, DocumentKind.vatCertificate]};

  Future<void> _pick(DocumentKind kind) async {
    if (_documents.length >= 5 || _working) return;
    try {
      final file = await ref.read(mediaUploadServiceProvider).pickDocument();
      if (file == null || !mounted) return;
      setState(() { _working = true; _error = null; _progress = 0; });
      final document = await ref.read(verificationRepositoryProvider).uploadDocument(file, kind, (value) { if (mounted) setState(() => _progress = value); });
      if (mounted) setState(() { _documents.add(document); _working = false; });
    } on AppException catch (error) { if (mounted) setState(() { _working = false; _error = error.messageKey; }); }
  }

  Future<void> _remove(VerificationDocument document) async { setState(() => _documents.remove(document)); await ref.read(verificationRepositoryProvider).removeDocument(document.path); }

  String? _validateData() {
    final licence = _licence.text.trim(); final issuer = _issuer.text.trim(); final vat = _vat.text.trim();
    final vatValid = RegExp(r'^[A-Za-z0-9]{8,20}$').hasMatch(vat);
    if (_type == BadgeType.hunter && (licence.length < 3 || issuer.length < 2 || _expiresOn == null || !_expiresOn!.isAfter(DateTime.now()) || _expiresOn!.isAfter(DateTime.now().add(const Duration(days: 3653))))) return 'verification.errors.data_invalid';
    if (_type == BadgeType.guide && (licence.length < 3 || issuer.length < 2 || _expiresOn != null && !_expiresOn!.isAfter(DateTime.now()))) return 'verification.errors.data_invalid';
    if ((_type == BadgeType.gunShop || _type == BadgeType.page) && (_company.text.trim().isEmpty || !vatValid)) return 'verification.errors.data_invalid';
    if (_type == BadgeType.association && (_association.text.trim().isEmpty || (!vatValid && _taxCode.text.trim().isEmpty))) return 'verification.errors.data_invalid';
    return null;
  }

  Map<String, dynamic> _declaredData() => switch (_type) {BadgeType.hunter => {'licence_number': _licence.text.trim(), 'issuer': _issuer.text.trim(), 'expires_on': _dateValue(_expiresOn!)}, BadgeType.guide => {'licence_number': _licence.text.trim(), 'issuer': _issuer.text.trim(), if (_expiresOn != null) 'expires_on': _dateValue(_expiresOn!)}, BadgeType.gunShop || BadgeType.page => {'company_name': _company.text.trim(), 'vat_id': _vat.text.trim()}, BadgeType.association => {'association': _association.text.trim(), if (_vat.text.trim().isNotEmpty) 'vat_id': _vat.text.trim(), if (_taxCode.text.trim().isNotEmpty) 'tax_code': _taxCode.text.trim()}};

  void _next() { final error = _step == (widget.fixedType == null ? 1 : 0) ? _validateData() : null; if (error != null) { setState(() => _error = error); return; } setState(() { _error = null; _step++; }); }

  Future<void> _submit() async {
    if (_documents.isEmpty) { setState(() => _error = 'verification.errors.documents_required'); return; }
    setState(() { _working = true; _error = null; });
    try { await ref.read(verificationRepositoryProvider).submit(badgeType: _type, declaredData: _declaredData(), documents: _documents, pageId: widget.pageId); _submitted = true; ref.invalidate(myVerificationProvider); if (mounted) context.pop(true); } on AppException catch (error) { if (mounted) setState(() { _working = false; _error = error.messageKey; }); }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.fixedType == null ? 3 : 2;
    final logicalStep = widget.fixedType == null ? _step : _step + 1;
    return Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: Text('verification.wizard_title'.tr(), style: context.textStyles.headlineSmall)), IconButton(onPressed: _working ? null : () => context.pop(false), icon: const Icon(Icons.close_rounded))]),
      Text('verification.step'.tr(namedArgs: {'current': '${_step + 1}', 'total': '$total'}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      const SizedBox(height: AppSpacing.md),
      Flexible(child: SingleChildScrollView(child: logicalStep == 0 ? _TypeStep(value: _type, onChanged: (value) => setState(() => _type = value)) : logicalStep == 1 ? _DataStep(type: _type, licence: _licence, issuer: _issuer, company: _company, vat: _vat, association: _association, taxCode: _taxCode, expiresOn: _expiresOn, onDate: () async { final value = await showDatePicker(context: context, initialDate: _expiresOn ?? DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now().add(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 3653))); if (value != null) setState(() => _expiresOn = value); }) : _DocumentsStep(recommended: _recommended, documents: _documents, working: _working, progress: _progress, onPick: _pick, onRemove: _remove))),
      if (_error != null) ...[const SizedBox(height: AppSpacing.sm), Text(_error!.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))],
      const SizedBox(height: AppSpacing.md),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [if (_step > 0) HBButton.secondary(label: 'common.back'.tr(), onPressed: _working ? null : () => setState(() { _step--; _error = null; })), if (_step > 0) const SizedBox(width: AppSpacing.sm), HBButton.primary(label: _step == total - 1 ? 'verification.submit'.tr() : 'common.next'.tr(), isLoading: _working, onPressed: _working ? null : (_step == total - 1 ? _submit : _next))]),
    ])));
  }
}

class _TypeStep extends StatelessWidget {
  final BadgeType value;
  final ValueChanged<BadgeType> onChanged;
  const _TypeStep({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final options = BadgeType.values.where((item) => item != BadgeType.page).toList();
    return HBFormSection(title: 'verification.choose_type'.tr(), children: [HBChoice<BadgeType>(options: options, value: value, onChanged: onChanged, labelBuilder: (type) => type.translationKey.tr(), descriptions: {for (final type in options) type: 'verification.badge_help.${type.code}'.tr()})]);
  }
}

class _DataStep extends StatelessWidget {
  final BadgeType type; final TextEditingController licence; final TextEditingController issuer; final TextEditingController company; final TextEditingController vat; final TextEditingController association; final TextEditingController taxCode; final DateTime? expiresOn; final VoidCallback onDate;
  const _DataStep({required this.type, required this.licence, required this.issuer, required this.company, required this.vat, required this.association, required this.taxCode, required this.expiresOn, required this.onDate});
  @override
  Widget build(BuildContext context) => HBFormSection(title: 'verification.declared_data'.tr(), children: [
    if (type == BadgeType.hunter || type == BadgeType.guide) ...[HBFormField(label: 'verification.fields.licence_number'.tr(), required: true, child: HBInput(controller: licence, maxLength: 80)), HBFormField(label: 'verification.fields.issuer'.tr(), required: true, child: HBInput(controller: issuer, maxLength: 120)), HBFormField(label: 'verification.fields.expires_on'.tr(), required: type == BadgeType.hunter, child: HBButton.secondary(label: expiresOn == null ? 'verification.fields.choose_date'.tr() : DateFormat.yMMMd(context.locale.languageCode).format(expiresOn!), onPressed: onDate))],
    if (type == BadgeType.gunShop || type == BadgeType.page) ...[HBFormField(label: 'verification.fields.company_name'.tr(), required: true, child: HBInput(controller: company, maxLength: 120)), HBFormField(label: 'verification.fields.vat_id'.tr(), required: true, child: HBInput(controller: vat, maxLength: 20))],
    if (type == BadgeType.association) ...[HBFormField(label: 'verification.fields.association'.tr(), required: true, child: HBInput(controller: association, maxLength: 120)), HBFormField(label: 'verification.fields.vat_id'.tr(), child: HBInput(controller: vat, maxLength: 20)), HBFormField(label: 'verification.fields.tax_code'.tr(), child: HBInput(controller: taxCode, maxLength: 20))],
  ]);
}

class _DocumentsStep extends StatelessWidget {
  final List<DocumentKind> recommended; final List<VerificationDocument> documents; final bool working; final double progress; final ValueChanged<DocumentKind> onPick; final ValueChanged<VerificationDocument> onRemove;
  const _DocumentsStep({required this.recommended, required this.documents, required this.working, required this.progress, required this.onPick, required this.onRemove});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('verification.documents'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), for (final kind in recommended) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: HBTile(child: Row(children: [Expanded(child: Text(kind.translationKey.tr())), HBButton.soft(label: 'verification.add'.tr(), size: HBButtonSize.sm, onPressed: working || documents.length >= 5 ? null : () => onPick(kind))]))), for (final document in documents) ListTile(contentPadding: EdgeInsets.zero, leading: Icon(document.name.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf_outlined : Icons.image_outlined), title: Text(document.name, overflow: TextOverflow.ellipsis), subtitle: Text(document.kind.translationKey.tr()), trailing: IconButton(onPressed: working ? null : () => onRemove(document), icon: const Icon(Icons.close_rounded))), if (working) HBUploadProgress(progress: progress), const SizedBox(height: AppSpacing.sm), Text('verification.privacy'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]);
}

String _dateValue(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';