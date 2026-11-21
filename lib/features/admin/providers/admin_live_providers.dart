import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/admin/data/admin_live_repository.dart';
import 'package:hb_social/features/admin/domain/admin_live.dart';

final adminLiveRepositoryProvider = Provider<AdminLiveRepository>((ref) => AdminLiveRepository(ref.watch(supabaseClientProvider)));
final adminLiveListProvider = FutureProvider.family<List<AdminLiveRecord>, String?>((ref, status) => ref.watch(adminLiveRepositoryProvider).list(status: status));