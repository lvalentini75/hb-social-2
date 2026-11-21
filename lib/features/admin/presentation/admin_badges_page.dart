import 'package:flutter/material.dart';
import 'package:hb_social/features/admin/presentation/admin_approvals_page.dart';

/// Badge verification entry point; it shares the approvals queue prefiltered to pending.
class AdminBadgesPage extends StatelessWidget {
  const AdminBadgesPage({super.key});
  @override Widget build(BuildContext context) => const AdminApprovalsPage(initialStatus: 'pending');
}