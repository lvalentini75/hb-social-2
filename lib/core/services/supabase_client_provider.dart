import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only application-level access point to the initialized Supabase client.
final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);