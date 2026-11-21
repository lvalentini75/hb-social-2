import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hb_social/core/services/platform_info.dart';

/// Public client configuration for the connected Supabase project.
class SupabaseConfig {
  static const String url = 'https://vbgktgujpwygqfjornnw.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZiZ2t0Z3VqcHd5Z3Fmam9ybm53Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEwMjUzNjYsImV4cCI6MjEwNjYwMTM2Nn0.ZcIiU3BS_lBnjR8votyCpQzzz7_2cNJzG62NN59uTMk';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      headers: {'x-hb-platform': currentPlatformName},
    );
  }
}
