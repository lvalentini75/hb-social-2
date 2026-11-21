import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/providers/platform_providers.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/support/data/support_repository.dart';
import 'package:hb_social/features/support/domain/support_ticket.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) => SupportRepository(ref.watch(supabaseClientProvider)));
final supportTicketsProvider = FutureProvider.autoDispose<List<SupportTicket>>((ref) async { if (await ref.watch(authSessionProvider.future) == null) return const []; return ref.watch(supportRepositoryProvider).tickets(); });
final supportMessagesProvider = FutureProvider.autoDispose.family<List<SupportMessage>, String>((ref, id) => ref.watch(supportRepositoryProvider).messages(id));
final supportCategoriesProvider = FutureProvider<List<String>>((ref) async => (await ref.watch(platformConfigProvider.future)).supportCategories);