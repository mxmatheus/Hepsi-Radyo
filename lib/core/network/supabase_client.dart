import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static Future<void> init() async {
    const defaultUrl = 'https://stcgvfwyzojgndricgob.supabase.co';
    const defaultAnonKey = 'sb_publishable_XpKQG6_gqc_MAEVKby98Fg_g0yABD5q';

    const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: defaultUrl);
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: defaultAnonKey);

    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
        );
        _isInitialized = true;
      } catch (_) {
        _isInitialized = false;
      }
    }
  }

  static SupabaseClient? get client {
    if (_isInitialized) {
      return Supabase.instance.client;
    }
    return null;
  }
}
