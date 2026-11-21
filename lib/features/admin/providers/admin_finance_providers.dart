import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/admin/data/admin_finance_repository.dart';
import 'package:hb_social/features/admin/domain/admin_finance_models.dart';

final adminFinanceRepositoryProvider = Provider<AdminFinanceRepository>((ref) => AdminFinanceRepository(ref.watch(supabaseClientProvider)));
final adminFinanceProvider = FutureProvider.autoDispose<FinanceSnapshot>((ref) => ref.watch(adminFinanceRepositoryProvider).load());