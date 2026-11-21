import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/legal/providers/legal_providers.dart';
import 'package:hb_social/features/settings/presentation/privacy_security_page.dart';
import 'package:intl/intl.dart';

class LegalConsentsSection extends ConsumerWidget {
  const LegalConsentsSection({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => SettingsSafetySection(titleKey: 'legal.consents.title', child: ref.watch(myLegalConsentsProvider).when(loading: () => const LinearProgressIndicator(), error: (_, __) => Text('legal.consents.error'.tr()), data: (items) => items.isEmpty ? Text('legal.consents.empty'.tr()) : Column(children: [for (final item in items) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.check_circle_outline_rounded, color: LightModeColors.success), title: Text('legal.kind.${item.kind}'.tr()), subtitle: Text('legal.consents.row'.tr(namedArgs: {'version': '${item.version}', 'date': item.acceptedAt == null ? '' : DateFormat.yMd(context.locale.toString()).add_Hm().format(item.acceptedAt!.toLocal()), 'platform': item.platform})))])));
}