import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_onboarding_models.dart';

/// Local signed-in session so signup/login skip the auth landing next time.
class AuthSessionService {
  AuthSessionService._();

  static final AuthSessionService instance = AuthSessionService._();

  static const _loggedInKey = 'auth_session_logged_in';
  static const _emailKey = 'auth_session_email';
  static const _roleKey = 'auth_session_role';
  static const _loggedOutKey = 'auth_session_explicit_logout';

  bool _loaded = false;
  bool _loggedIn = false;
  bool _explicitLogout = false;
  String? _email;
  UserRole? _role;

  bool get isLoggedIn => _loggedIn;
  bool get explicitlyLoggedOut => _explicitLogout;
  String? get email => _email;
  UserRole? get role => _role;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = prefs.getBool(_loggedInKey) ?? false;
    _explicitLogout = prefs.getBool(_loggedOutKey) ?? false;
    _email = prefs.getString(_emailKey);
    final roleName = prefs.getString(_roleKey);
    if (roleName != null) {
      try {
        _role = UserRole.values.byName(roleName);
      } catch (_) {
        _role = null;
      }
    }
    _loaded = true;
  }

  Future<void> startSession({
    required String email,
    UserRole? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = email.trim().toLowerCase();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setBool(_loggedOutKey, false);
    await prefs.setString(_emailKey, normalized);
    if (role != null) {
      await prefs.setString(_roleKey, role.name);
    }
    _loggedIn = true;
    _explicitLogout = false;
    _email = normalized;
    _role = role ?? _role;
    _loaded = true;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
    await prefs.setBool(_loggedOutKey, true);
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);
    _loggedIn = false;
    _explicitLogout = true;
    _email = null;
    _role = null;
    _loaded = true;
  }
}
