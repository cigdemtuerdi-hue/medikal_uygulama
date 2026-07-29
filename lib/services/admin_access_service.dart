import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'auth_api_service.dart';

/// Session gate for the owner-only Admin Console.
///
/// Prefers server-side `/api/auth/admin-login` so the password stays on the API.
/// Falls back to local [AppConfig] credentials when the API is unreachable and
/// local admin secrets are configured (dev / offline).
class AdminAccessService extends ChangeNotifier {
  AdminAccessService._() {
    _restore();
  }

  static final AdminAccessService instance = AdminAccessService._();

  static const _tokenKey = 'medgift_admin_token';
  static const _emailKey = 'medgift_admin_email';

  bool _authenticated = false;
  bool _restoring = true;
  String? _token;
  String? _email;
  String? _lastError;

  bool get isAuthenticated => _authenticated;
  bool get isRestoring => _restoring;
  String? get email => _email;
  String? get lastError => _lastError;
  String? get token => _token;

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final email = prefs.getString(_emailKey);
      if (token != null && token.isNotEmpty) {
        final ok = await AuthApiService.instance.validateAdminSession(token);
        if (ok) {
          _token = token;
          _email = email;
          _authenticated = true;
        } else {
          await prefs.remove(_tokenKey);
          await prefs.remove(_emailKey);
        }
      }
    } catch (err, stack) {
      debugPrint('[AdminAccess] restore failed: $err\n$stack');
    }
    _restoring = false;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _lastError = null;
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPassword = password;

    final apiResult = await AuthApiService.instance.adminLogin(
      email: trimmedEmail,
      password: trimmedPassword,
    );

    if (apiResult.success &&
        apiResult.token != null &&
        apiResult.token!.isNotEmpty) {
      await _persistSession(
        token: apiResult.token!,
        email: trimmedEmail,
      );
      return true;
    }

    // Local fallback for offline/dev when secrets are baked into the client.
    final localOk = AppConfig.hasLocalAdminCredentials &&
        trimmedEmail == AppConfig.adminEmail.toLowerCase() &&
        trimmedPassword == AppConfig.adminPassword;

    if (localOk) {
      await _persistSession(
        token: 'local-${DateTime.now().millisecondsSinceEpoch}',
        email: trimmedEmail,
      );
      return true;
    }

    _lastError = apiResult.message.isNotEmpty
        ? apiResult.message
        : 'Admin e-posta veya şifre hatalı.';
    notifyListeners();
    return false;
  }

  /// Legacy PIN unlock (maps to password-only when email is preconfigured).
  Future<bool> unlockWithPin(String pin) {
    return login(email: AppConfig.adminEmail, password: pin.trim());
  }

  Future<void> _persistSession({
    required String token,
    required String email,
  }) async {
    _token = token;
    _email = email;
    _authenticated = true;
    _lastError = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_emailKey, email);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> lock() async {
    final token = _token;
    _authenticated = false;
    _token = null;
    _email = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_emailKey);
    } catch (_) {}
    if (token != null && !token.startsWith('local-')) {
      await AuthApiService.instance.adminLogout(token);
    }
  }
}
