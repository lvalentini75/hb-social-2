import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/presentation/admin_system_page.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/providers/admin_p43_providers.dart';

class AdminBroadcastsPage extends ConsumerWidget {
  const AdminBroadcastsPage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => AdminListPage(title: 'admin.broadcast.title'.tr(), description: 'admin.broadcast.subtitle'.tr(), actions: [HBButton.primary(label: 'admin.broadcast.new'.tr(), icon: Icons.add, onPressed: () async { await showDialog<void>(context: context, builder: (_) => const BroadcastEditorDialog()); ref.invalidate(adminBroadcastsProvider); })], filters: const SizedBox.shrink(), emptyMessage: 'admin.broadcast.empty'.tr(), content: ref.watch(adminBroadcastsProvider).when(loading: () => const AdminDataTable(headers: ['','',''], rows: [], emptyMessage: '', isLoading: true), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'admin.broadcast.error'.tr(), message: 'admin.broadcast.error_help'.tr()), data: (items) => AdminDataTable(headers: ['admin.broadcast.name'.tr(),'admin.broadcast.status_label'.tr(),'admin.broadcast.recipients'.tr(),'admin.broadcast.opened'.tr(),'admin.broadcast.created_by'.tr()], emptyMessage: 'admin.broadcast.empty'.tr(), rows: [for (final item in items) [Text(item['name']?.toString() ?? ''),HBStatusChip(kind:item['status']=='sent'?HBStatusKind.approved:HBStatusKind.pending,label:'admin.broadcast.status.${item['status']}'.tr()),Text('${item['recipients_count'] ?? 0}'),Text('${item['opened'] ?? 0} / ${item['recipients_count'] ?? 0}'),Text(item['created_by_name']?.toString() ?? '')]])));
}
class BroadcastEditorDialog extends ConsumerStatefulWidget { const BroadcastEditorDialog({super.key}); @override ConsumerState<BroadcastEditorDialog> createState()=>_BroadcastEditorDialogState(); }
class _BroadcastEditorDialogState extends ConsumerState<BroadcastEditorDialog> {
  final name=TextEditingController(), title=TextEditingController(), body=TextEditingController(), route=TextEditingController(); Map<String,dynamic>? estimate; bool saving=false;
  @override void dispose(){name.dispose();title.dispose();body.dispose();route.dispose();super.dispose();}
  Map<String,dynamic> get audience=>{'country_codes':<String>[],'region_ids':<String>[],'locales':<String>[],'verification_levels':<String>[],'interests':<String>[],'active_days':90};
  @override Widget build(BuildContext context)=>AlertDialog(title:Text('admin.broadcast.editor'.tr()),content:SizedBox(width:720,child:SingleChildScrollView(child:Column(children:[HBInput(controller:name,label:'admin.broadcast.name'.tr()),HBInput(controller:title,label:'admin.broadcast.message_title'.tr(),maxLength:80),HBInput(controller:body,label:'admin.broadcast.message_body'.tr(),maxLength:300,maxLines:5),HBInput(controller:route,label:'admin.broadcast.route'.tr()),if(estimate!=null) Text('admin.broadcast.estimate'.tr(namedArgs:{'n':'${estimate!['recipients']??0}','push':'${estimate!['with_push']??0}'}))]))),actions:[HBButton.soft(label:'admin.broadcast.estimate_action'.tr(),onPressed:estimateNow),HBButton.primary(label:'admin.broadcast.save_draft'.tr(),isLoading:saving,onPressed:save)]);
  Future<void> estimateNow() async{try{final value=await ref.read(adminP43RepositoryProvider).estimateBroadcast(audience);if(mounted)setState(()=>estimate=value);}catch(error){if(mounted)p43Error(context,error);}}
  Future<void> save() async{setState(()=>saving=true);try{await ref.read(adminP43RepositoryProvider).saveBroadcast(name:name.text,messages:{'it':{'title':title.text,'body':body.text}},route:route.text,audience:audience);if(mounted)context.pop();}catch(error){if(mounted)p43Error(context,error);}finally{if(mounted)setState(()=>saving=false);}}
}