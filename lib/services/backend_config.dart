import 'package:supabase_flutter/supabase_flutter.dart';

/// Backend selection: Supabase when keys are provided, local otherwise.
///
/// Keys are compile-time `--dart-define`s (never committed, never hard-coded):
///
///   flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// Without them the app is fully functional offline (SharedPreferences),
/// so tests and demos need no backend. `flutter test` always runs local.
class BackendConfig {
  BackendConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// True when both keys were provided at build/run time.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static SupabaseClient get client => Supabase.instance.client;

  /// Initializes Supabase when configured; safe no-op otherwise.
  /// Call once from main() before AppData/AuthService init.
  static Future<void> init() async {
    if (!isConfigured) return;
    await Supabase.initialize(
      url: supabaseUrl,
      // The anon (publishable) key is safe to embed in clients; RLS is
      // what actually protects the data.
      publishableKey: supabaseAnonKey,
    );
  }
}
