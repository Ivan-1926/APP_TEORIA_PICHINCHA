import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const _supabaseUrl = 'https://uomaqpphyouzbnestbba.supabase.co';
  static const _supabaseAnonKey = 'sb_publishable_fymmXEWgkQSdaXe-F3_8OA_QK6ZOnCe';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }
}
