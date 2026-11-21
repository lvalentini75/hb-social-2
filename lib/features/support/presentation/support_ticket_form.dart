import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/config/app_constants.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/support/presentation/support_page.dart';
import 'package:hb_social/features/support/providers/support_providers.dart';
import 'package:uuid/uuid.dart';

class SupportTicketForm extends ConsumerStatefulWidget {
  final String? initialSubject;
  final String? initialBody;
  final String? initialCategory;
  const SupportTicketForm({super.key, this.initialSubject, this.initialBody, this.initialCategory});
  @override ConsumerState<SupportTicketForm> createState() => _SupportTicketFormState();
}

class _SupportTicketFormState extends ConsumerState<SupportTicketForm> {
  late final subject = TextEditingController(text: widget.initialSubject ?? '');
  late final body = TextEditingController(text: widget.initialBody ?? '');
  final ticketId = const Uuid().v4();
  String? category;
  final files = <PlatformFile>[];
  bool saving = false;
  @override void initState() { super.initState(); category = widget.initialCategory; }
  @override void dispose() { subject.dispose(); body.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final categories = ref.watch(supportCategoriesProvider).value ?? const <String>[];
    category ??= categories.firstOrNull;
    return SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('support.form.title'.tr(), style: context.textStyles.headlineSmall), const SizedBox(height: 16), HBInput(controller: subject, label: 'support.form.subject'.tr()), const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: [for (final item in categories) HBChip(label: 'support.category.$item'.tr(), selected: category == item, onTap: () => setState(() => category = item))]), const SizedBox(height: 12), HBInput(controller: body, label: 'support.form.message'.tr(), maxLines: 6), const SizedBox(height: 12), HBButton.soft(label: 'support.form.attach'.tr(namedArgs: {'count': '${files.length}'}), icon: Icons.attach_file, onPressed: files.length >= 5 ? null : pick), const SizedBox(height: 20), HBButton.primary(label: 'support.form.send'.tr(), isLoading: saving, onPressed: saving ? null : save)]))));
  }
  Future<void> pick() async { final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['jpg','jpeg','png','webp','pdf'], allowMultiple: true, withData: true); if (result != null) setState(() => files.addAll(result.files.take(5 - files.length))); }
  Future<void> save() async {
    if (category == null) return;
    setState(() => saving = true);
    try {
      final user = ref.read(authSessionProvider).value!.user;
      final attachments = <Map<String, dynamic>>[];
      for (final file in files) {
        final extension = (file.extension ?? '').toLowerCase();
        final path = '${user.id}/$ticketId/${const Uuid().v4()}.$extension';
        await ref.read(mediaUploadServiceProvider).uploadBytes(bucket: 'support-media', path: path, bytes: file.bytes!, contentType: extension == 'pdf' ? 'application/pdf' : 'image/${extension == 'jpg' ? 'jpeg' : extension}', isPublic: false, onProgress: (_) {});
        attachments.add({'path': path, 'kind': extension == 'pdf' ? 'pdf' : 'image', 'name': file.name});
      }
      await ref.read(supportRepositoryProvider).create(id: ticketId, subject: subject.text, category: category!, body: body.text, attachments: attachments, context: {'platform': kIsWeb ? 'web' : defaultTargetPlatform.name, 'app_version': AppConstants.appVersion, 'route': AppRouter.router.routeInformationProvider.value.uri.path});
      if (mounted) context.pop();
    } catch (error) { if (mounted) showSupportError(context, error); }
    finally { if (mounted) setState(() => saving = false); }
  }
}