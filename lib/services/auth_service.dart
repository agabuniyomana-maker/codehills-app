import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_config.dart';

/// A signed-in account (user or admin).
class Session {
  final String username;
  final bool isAdmin;

  /// Stable account identifier: `auth.users.id` in Supabase mode, and an id
  /// generated once per account in local mode.
  ///
  /// This is the seed of the account's Imigongo identity, so it must never
  /// change for an account. It is not a secret, but public UI shows the
  /// identity code instead of this value.
  final String accountId;

  const Session({
    required this.username,
    required this.isAdmin,
    required this.accountId,
  });
}

/// Authentication.
///
/// Two modes chosen by [BackendConfig.isConfigured]:
/// * Supabase mode — real accounts via Supabase Auth (email + password),
///   admin flag read from the `profiles` table. This is the only mode a
///   release build may use.
/// * Local mode — the phase-1 SharedPreferences store (seeded admin), used by
///   tests, demos and debug builds without keys. Release builds without
///   Supabase keys have no account system at all rather than insecure local
///   credentials.
///
/// The public API is identical in both modes; screens never know which one is
/// active.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _prefsUsers = 'local_users';
  static const _prefsSession = 'local_session';
  static const _prefsAccountIds = 'local_account_ids';

  /// Seeded admin for local demo builds. Only accepted when
  /// [demoModeAvailable] is true, i.e. debug builds without a backend —
  /// release builds must never share these credentials.
  static const adminUsername = 'admin';
  static const adminPassword = 'codehills1001';

  static const _localAdminAccountId = 'local-seeded-admin';

  Session? session;

  /// username -> password. Demo-only: debug builds without a backend. Real
  /// passwords are hashed and stored by Supabase Auth, never here.
  final Map<String, String> _users = {};

  /// username -> stable local account id (kept across logout/logins).
  final Map<String, String> _accountIds = {};

  bool get isSupabaseMode => BackendConfig.isConfigured;

  /// True only in debug/demo builds that have no backend configured.
  bool get demoModeAvailable => !kReleaseMode && !isSupabaseMode;

  /// Local accounts (and their plain-text store) are never enabled in release
  /// builds — a release build without Supabase must not silently fall back to
  /// them.
  bool get _localAuthEnabled => !kReleaseMode;

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
    final idsJson = prefs.getString(_prefsAccountIds);
    if (idsJson != null) {
      _accountIds
          .addAll((jsonDecode(idsJson) as Map<String, dynamic>).cast());
    }
    final sessionJson = prefs.getString(_prefsSession);
    if (sessionJson != null) {
      final map = jsonDecode(sessionJson) as Map<String, dynamic>;
      final username = map['username'] as String;
      final isAdmin = map['isAdmin'] as bool? ?? false;
      final accountId = map['accountId'] as String? ??
          (isAdmin
              ? _localAdminAccountId
              : await _localAccountId(username));
      session = Session(
        username: username,
        isAdmin: isAdmin,
        accountId: accountId,
      );
    }
  }

  bool get isSignedIn => session != null;

  /// Registers a new account. Returns an error message, or null on success.
  ///
  /// Supabase mode: [username] is the account email. If the project has email
  /// confirmation on, returns an informational message (not an error) after
  /// the account is created.
  Future<String?> register(String username, String password) async {
    if (isSupabaseMode) return _registerSupabase(username, password);
    if (!_localAuthEnabled) {
      return 'This build is not connected to the account service.';
    }

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
    await _startSession(
      Session(
        username: name,
        isAdmin: false,
        accountId: await _localAccountId(name),
      ),
    );
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
    if (!_localAuthEnabled) {
      return 'This build is not connected to the account service.';
    }

    final lower = username.trim().toLowerCase();
    if (demoModeAvailable &&
        lower == adminUsername &&
        password == adminPassword) {
      await _startSession(
        const Session(
          username: adminUsername,
          isAdmin: true,
          accountId: _localAdminAccountId,
        ),
      );
      return null;
    }
    final stored = _users[lower];
    if (stored == null) return 'This email/username is not registered.';
    if (stored != password) return 'Incorrect password.';
    await _startSession(
      Session(
        username: username.trim(),
        isAdmin: false,
        accountId: await _localAccountId(username.trim()),
      ),
    );
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
  ///
  /// [User.id] is the stable account id used for the Imigongo identity; the
  /// admin flag is only *displayed* from here — every policy is enforced by
  /// Row Level Security in Postgres.
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
    session = Session(
      username: username,
      isAdmin: isAdmin,
      accountId: user.id,
    );
  }

  Future<void> _startSession(Session s) async {
    session = s;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsSession,
      jsonEncode({
        'username': s.username,
        'isAdmin': s.isAdmin,
        'accountId': s.accountId,
      }),
    );
  }

  /// Stable per-account id for local mode. Generated once, then reused for
  /// that account forever, so its Imigongo identity never changes.
  Future<String> _localAccountId(String username) async {
    final key = username.trim().toLowerCase();
    final existing = _accountIds[key];
    if (existing != null) return existing;

    final id = 'local_${_randomToken(16)}';
    _accountIds[key] = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsAccountIds, jsonEncode(_accountIds));
    return id;
  }

  static String _randomToken(int bytes) {
    final rng = math.Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < bytes; i++) {
      buffer.write(rng.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
