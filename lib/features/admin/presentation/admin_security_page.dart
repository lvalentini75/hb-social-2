import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/features/admin/domain/admin_list_models.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_read_only_widgets.dart';
import 'package:hb_social/features/admin/providers/admin_console_providers.dart';

/// Database-backed MFA policy controls for console members.
class AdminSecurityPage extends ConsumerWidget {
  const AdminSecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(adminRolesDataProvider);
    return AdminListPage(
      title: 'p40.security.title'.tr(),
      description: 'p40.security.subtitle'.tr(),
      filters: HBCard(color: LightModeColors.lightBackgroundSoft, child: Row(children: [const Icon(Icons.verified_user_outlined), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('p40.security.mandatory'.tr()))])),
      emptyMessage: 'admin.rolesPage.staffEmpty'.tr(),
      onRetry: data.hasError ? () => ref.invalidate(adminRolesDataProvider) : null,
      content: data.when(
        loading: () => const AdminDataTable(headers: ['', '', ''], rows: [], emptyMessage: '', isLoading: true),
        error: (_, __) => const SizedBox.shrink(),
        data: (value) => AdminMfaPolicyTable(staff: value.staff),
      ),
    );
  }
}

class AdminMfaPolicyTable extends ConsumerStatefulWidget {
  final List<AdminStaffRecord> staff;
  const AdminMfaPolicyTable({super.key, required this.staff});

  @override
  ConsumerState<AdminMfaPolicyTable> createState() => _AdminMfaPolicyTableState();
}

class _AdminMfaPolicyTableState extends ConsumerState<AdminMfaPolicyTable> {
  String? savingId;

  @override
  Widget build(BuildContext context) => AdminDataTable(
    headers: ['p40.security.member'.tr(), 'p40.security.role'.tr(), 'p40.security.required'.tr()],
    columnWidths: const [300, 220, 180],
    emptyMessage: 'admin.rolesPage.staffEmpty'.tr(),
    rows: [
      for (final member in widget.staff)
        [
          AdminPersonCell(person: member.person),
          Text('admin.roles.${_roleKey(member.roleName)}'.tr()),
          Switch(value: member.mfaEnabled, onChanged: savingId == member.person.id ? null : (enabled) => _setRequired(member, enabled)),
        ],
    ],
  );

  Future<void> _setRequired(AdminStaffRecord member, bool enabled) async {
    setState(() => savingId = member.person.id);
    try {
      await ref.read(adminListRepositoryProvider).setStaffMfaRequired(userId: member.person.id, enabled: enabled);
      ref.invalidate(adminRolesDataProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('p40.security.saved'.tr())));
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    } finally {
      if (mounted) setState(() => savingId = null);
    }
  }

  String _roleKey(String role) => switch (role) { 'ads_reviewer' => 'adsReviewer', 'hunting_data_editor' => 'huntingDataEditor', _ => role };
}