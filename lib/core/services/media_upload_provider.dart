import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';

final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) => MediaUploadService(ref.watch(supabaseClientProvider)));