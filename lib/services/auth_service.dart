import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_config.dart';

/// A signed-in account (user or admin).
class Session {
  final String username;
  final bool isAdmin;

  const Session({required this.username, required this.isAdmin});
}

/// Authentication.
///
/// Two modes chosen by [BackendConfig.isConfigured]:
/// * Supabase mode — real accounts via Supabase Auth (email + password),
///   admin flag read from the `profiles` table.
/// * Local mode — the phase-1 SharedPreferences store (seeded admin),
///   used by tests, demos and any build without keys.
///
/// The public API is identical in both modes; screens never know which
/// one is active.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _prefsUsers = 'local_users';
  static const _prefsSession = 'local_session';

  /// Seeded admin for the local (no-backend) portal (change before release).
  static const adminUsername = 'admin';
  static const adminPassword = 'codehills1001';

  Session? session;
  final Map<String, String> _users = {}; // username -> password (plain, local)

  bool get isSupabaseMode => BackendConfig.isConfigured;

  Future<void> init() async {
    if (isSupabaseMode) {
      // Supabase restores its persisted session itself.
      final user = BackendConfig.client.auth.currentUser;
      if (user != null) await _startSupabaseSession(user);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_prefsUsers);
    if (usersJson != null) {
      _users.addAll((jsonDecode(usersJson) as Map<String, dynamic>).cast());
    }
    final sessionJson = prefs.getString(_prefsSession);
    if (sessionJson != null) {
      final map = jsonDecode(sessionJson) as Map<String, dynamic>;
      session = Session(
        username: map['username'] as String,
        isAdmin: map['isAdmin'] as bool? ?? false,
      );
    }
  }

  bool get isSignedIn => session != null;

  /// Registers a new account. Returns an error message, or null on success.
  ///
  /// Supabase mode: [username] is the account email. If the project has
  /// email confirmation on, returns an informational message (not an error)
  /// after the account is created.
  Future<String?> register(String username, String password) async {
    if (isSupabaseMode) return _registerSupabase(username, password);

    final name = username.trim();
    if (name.isEmpty || name.length < 3) {
      return 'Username must be at least 3 characters.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    final lower = name.toLowerCase();
    if (_users.containsKey(lower) ||
        lower == adminUsername ||
        lower == 'admin') {
      return 'That username is already taken.';
    }
    _users[lower] = password;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsUsers, jsonEncode(_users));
    await _startSession(Session(username: name, isAdmin: false));
    return null;
  }

  Future<String?> _registerSupabase(String email, String password) async {
    final address = email.trim();
    if (!address.contains('@') || !address.contains('.')) {
      return 'Please enter a valid email address.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    try {
      final res = await BackendConfig.client.auth.signUp(
        email: address,
        password: password,
        data: {'username': address.split('@').first},
      );
      if (res.session == null) {
        // Project requires email confirmation before first login.
        return 'Account created. Check your email to confirm it, '
            'then log in.';
      }
      await _startSupabaseSession(res.user!);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Check your connection.';
    }
  }

  /// Signs in. Returns an error message, or null on success.
  Future<String?> login(String username, String password) async {
    if (isSupabaseMode) return _loginSupabase(username, password);

    final lower = username.trim().toLowerCase();
    if (lower == adminUsername && password == adminPassword) {
      await _startSession(
        const Session(username: adminUsername, isAdmin: true),
      );
      return null;
    }
    final stored = _users[lower];
    if (stored == null) return 'This email/username is not registered.';
    if (stored != password) return 'Incorrect password.';
    await _startSession(Session(username: username.trim(), isAdmin: false));
    return null;
  }

  Future<String?> _loginSupabase(String email, String password) async {
    final address = email.trim();
    if (address.isEmpty || password.isEmpty) {
      return 'Enter your email and password.';
    }
    try {
      final res = await BackendConfig.client.auth.signInWithPassword(
        email: address,
        password: password,
      );
      await _startSupabaseSession(res.user!);
      return null;
    } on AuthException {
      return 'Incorrect email or password.';
    } catch (_) {
      return 'Could not reach the server. Check your connection.';
    }
  }

  Future<void> logout() async {
    session = null;
    if (isSupabaseMode) {
      await BackendConfig.client.auth.signOut();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsSession);
  }

  /// Loads the signed-in user's profile row (username + admin flag).
  Future<void> _startSupabaseSession(User user) async {
    var username = user.email?.split('@').first ?? 'user';
    var isAdmin = false;
    try {
      final row = await BackendConfig.client
          .from('profiles')
          .select('username, is_admin')
          .eq('id', user.id)
          .single();
      username = row['username'] as String? ?? username;
      isAdmin = (row['is_admin'] as bool?) ?? false;
    } catch (_) {
      // Profile row not created yet (trigger not installed) — use email name.
    }
    session = Session(username: username, isAdmin: isAdmin);
  }

  Future<void> _startSession(Session s) async {
    session = s;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsSession,
      jsonEncode({'username': s.username, 'isAdmin': s.isAdmin}),
    );
  }
}
