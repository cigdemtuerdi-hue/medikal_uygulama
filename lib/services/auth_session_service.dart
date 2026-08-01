import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_onboarding_models.dart';

/// Local signed-in session so signup/login skip the auth landing next time.
///
/// HIPAA session security: idle timeout of [idleTimeout] forces re-auth.
class AuthSessionService {
  AuthSessionService._();

  static final AuthSessionService instance = AuthSessionService._();

  /// 15 minutes of inactivity → require re-authentication.
  static const idleTimeout = Duration(minutes: 15);

  static const _loggedInKey = 'auth_session_logged_in';
  static const _emailKey = 'auth_session_email';
  static const _roleKey = 'auth_session_role';
  static const _loggedOutKey = 'auth_session_explicit_logout';
  static const _lastActiveKey = 'auth_session_last_active_ms';
  static const _tokenKey = 'auth_session_token';

  bool _loaded = false;
  bool _loggedIn = false;
  bool _explicitLogout = false;
  String? _email;
  UserRole? _role;
  DateTime? _lastActivityAt;
  String? _token;

  bool get isLoggedIn => _loggedIn;
  bool get explicitlyLoggedOut => _explicitLogout;
  String? get email => _email;
  UserRole? get role => _role;
  DateTime? get lastActivityAt => _lastActivityAt;

  /// Signed session token from the API; sent as a bearer on listing calls.
  String? get token => _token;

  /// True when a session exists but idle time exceeded [idleTimeout].
  bool get isIdleExpired {
    if (!_loggedIn || _lastActivityAt == null) return false;
    return DateTime.now().difference(_lastActivityAt!) >= idleTimeout;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = prefs.getBool(_loggedInKey) ?? false;
    _explicitLogout = prefs.getBool(_loggedOutKey) ?? false;
    _email = prefs.getString(_emailKey);
    _token = prefs.getString(_tokenKey);
    final roleName = prefs.getString(_roleKey);
    if (roleName != null) {
      try {
        _role = UserRole.values.byName(roleName);
      } catch (_) {
        _role = null;
      }
    }
    final lastMs = prefs.getInt(_lastActiveKey);
    if (lastMs != null) {
      _lastActivityAt = DateTime.fromMillisecondsSinceEpoch(lastMs);
    }
    _loaded = true;

    if (_loggedIn && isIdleExpired) {
      await clearSession(dueToIdle: true);
    }
  }

  Future<void> startSession({
    required String email,
    UserRole? role,
    String? token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = email.trim().toLowerCase();
    final now = DateTime.now();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setBool(_loggedOutKey, false);
    await prefs.setString(_emailKey, normalized);
    await prefs.setInt(_lastActiveKey, now.millisecondsSinceEpoch);
    if (role != null) {
      await prefs.setString(_roleKey, role.name);
    }
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_tokenKey, token);
      _token = token;
    }
    _loggedIn = true;
    _explicitLogout = false;
    _email = normalized;
    _role = role ?? _role;
    _lastActivityAt = now;
    _loaded = true;
  }

  /// Call on user interaction to reset the idle clock.
  Future<void> touchActivity() async {
    if (!_loggedIn) return;
    final now = DateTime.now();
    _lastActivityAt = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastActiveKey, now.millisecondsSinceEpoch);
  }

  /// Returns true if session was cleared due to idle timeout.
  Future<bool> enforceIdleTimeout() async {
    await ensureLoaded();
    if (_loggedIn && isIdleExpired) {
      await clearSession(dueToIdle: true);
      return true;
    }
    return false;
  }

  Future<void> clearSession({bool dueToIdle = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
    // Always require an explicit sign-in after logout or idle timeout (HIPAA).
    await prefs.setBool(_loggedOutKey, true);
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_lastActiveKey);
    await prefs.remove(_tokenKey);
    _loggedIn = false;
    _explicitLogout = true;
    _email = null;
    _role = null;
    _lastActivityAt = null;
    _token = null;
    _loaded = true;
  }
}
