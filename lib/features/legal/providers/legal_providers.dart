import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/legal/data/legal_repository.dart';
import 'package:hb_social/features/legal/domain/legal_document.dart';

final legalRepositoryProvider = Provider<LegalRepository>((ref) => LegalRepository(ref.watch(supabaseClientProvider)));
final legalDocumentProvider = FutureProvider.autoDispose.family<LegalDocument, ({String kind, String locale})>((ref, request) => ref.watch(legalRepositoryProvider).document(request.kind, request.locale));
final currentLegalDocumentsProvider = FutureProvider.autoDispose.family<List<LegalDocument>, String>((ref, locale) => ref.watch(legalRepositoryProvider).current(locale));
final pendingLegalConsentsProvider = FutureProvider.autoDispose.family<PendingLegalConsents, String>((ref, locale) { ref.watch(authSessionProvider); return ref.watch(legalRepositoryProvider).pending(locale); });
final myLegalConsentsProvider = FutureProvider.autoDispose<List<LegalConsentRecord>>((ref) { ref.watch(authSessionProvider); return ref.watch(legalRepositoryProvider).myConsents(); });