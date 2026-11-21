import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/auth/data/auth_security_repository.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MfaEnrollPage extends ConsumerStatefulWidget {
  final String? destination;
  const MfaEnrollPage({super.key, this.destination});

  @override
  ConsumerState<MfaEnrollPage> createState() => _MfaEnrollPageState();
}

class _MfaEnrollPageState extends ConsumerState<MfaEnrollPage> {
  final _code = TextEditingController();
  MfaEnrollment? _enrollment;
  AppException? _error;
  bool _loading = true;

  @override
  void initState() { super.initState(); Future.microtask(_enroll); }
  @override
  void dispose() { _code.dispose(); super.dispose(); }

  Future<void> _enroll() async {
    try { _enrollment = await ref.read(authSecurityRepositoryProvider).enroll(); } on AppException catch (error) { _error = error; }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _verify() async {
    if (_enrollment == null || _code.text.length != 6) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authSecurityRepositoryProvider).verify(_enrollment!.factorId, _code.text);
      ref.invalidate(verifiedMfaFactorsProvider);
      ref.invalidate(mfaChallengeRequiredProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('auth.mfa.enabled_success'.tr())));
        widget.destination == null ? context.pop() : context.go(widget.destination!);
      }
    } on AppException catch (error) { if (mounted) setState(() => _error = error); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.all(AppSpacing.lg), sliver: SliverToBoxAdapter(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: HBCard(child: _loading && _enrollment == null ? const LinearProgressIndicator() : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('auth.mfa.enroll_title'.tr(), style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.md), if (_enrollment != null) ...[Center(child: SizedBox.square(dimension: 220, child: SvgPicture.string(_enrollment!.qrCode))), const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: SelectableText(_enrollment!.secret)), HBButton.icon(icon: Icons.copy_outlined, tooltip: 'auth.mfa.copy_secret'.tr(), onPressed: () => Clipboard.setData(ClipboardData(text: _enrollment!.secret)))]), const SizedBox(height: AppSpacing.md), HBInput(controller: _code, label: 'auth.mfa.code'.tr(), keyboardType: TextInputType.number, maxLength: 6, inputFormatters: [FilteringTextInputFormatter.digitsOnly]), const SizedBox(height: AppSpacing.md), HBButton.primary(label: 'auth.mfa.verify'.tr(), onPressed: _verify, isLoading: _loading)], if (_error != null) Text(_error!.messageKey.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))]))))))]);
}