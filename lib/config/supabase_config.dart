import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // URL Project Supabase
  static const String supabaseUrl = 'https://nbqjeyuchjzadwncwant.supabase.co';
  
  // Anon Public Key
  static const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5icWpleXVjaGp6YWR3bmN3YW50Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ1NTU2NTEsImV4cCI6MjEwMDEzMTY1MX0.5SBLkvCaG94ZwJoVi1vGWJVqCjozdD5ULL58eNYRMZ8';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: supabaseKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}