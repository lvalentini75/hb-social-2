import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/verification/data/verification_repository.dart';
import 'package:hb_social/features/verification/domain/verification_request.dart';

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) => VerificationRepository(ref.watch(supabaseClientProvider), ref.watch(mediaUploadServiceProvider)));
final myVerificationProvider = FutureProvider.autoDispose<VerificationStatus>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) return const VerificationStatus();
  return ref.watch(verificationRepositoryProvider).myVerification();
});