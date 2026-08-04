import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Result of an auth API call (forgot / reset password, register, login).
class AuthApiResult {
  const AuthApiResult({
    required this.success,
    required this.message,
    this.statusCode,
    this.code,
    this.token,
    this.role,
  });

  final bool success;
  final String message;
  final int? statusCode;
  final String? code;
  final String? token;
  final String? role;
}

/// HTTP client for MedGift US auth endpoints on the Node API.
class AuthApiService {
  AuthApiService._();

  static final AuthApiService instance = AuthApiService._();

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized');
  }

  Future<AuthApiResult> requestPasswordReset({
    required String email,
  }) async {
    return _postJson(
      '/api/auth/forgot-password',
      body: {
        'email': email.trim().toLowerCase(),
        'method': 'email',
      },
      fallbackSuccessMessage: 'Sıfırlama bağlantısı e-postanıza gönderildi',
      fallbackErrorMessage:
          'Şifre sıfırlama isteği gönderilemedi. Lütfen tekrar deneyin.',
    );
  }

  Future<AuthApiResult> register({
    required String email,
    required String password,
    String? phone,
    String? role,
    bool hipaaConsentAccepted = false,
    String? hipaaConsentVersion,
  }) async {
    final body = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'password': password,
      'hipaaConsentAccepted': hipaaConsentAccepted,
      if (hipaaConsentVersion != null)
        'hipaaConsentVersion': hipaaConsentVersion,
      if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
    };
    final trimmedPhone = phone?.trim() ?? '';
    if (trimmedPhone.isNotEmpty) body['phone'] = trimmedPhone;

    return _postJson(
      '/api/auth/register',
      body: body,
      fallbackSuccessMessage: 'Hesabınız oluşturuldu. Giriş yapabilirsiniz.',
      fallbackErrorMessage: 'Kayıt tamamlanamadı. Lütfen tekrar deneyin.',
    );
  }

  Future<AuthApiResult> login({
    required String email,
    required String password,
  }) async {
    return _postJson(
      '/api/auth/login',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
      fallbackSuccessMessage: 'Giriş başarılı.',
      fallbackErrorMessage: 'E-posta veya şifre hatalı.',
    );
  }

  Future<AuthApiResult> adminLogin({
    required String email,
    required String password,
  }) async {
    return _postJson(
      '/api/auth/admin-login',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
      fallbackSuccessMessage: 'Admin girişi başarılı.',
      fallbackErrorMessage: 'Admin e-posta veya şifre hatalı.',
    );
  }

  Future<bool> validateAdminSession(String token) async {
    try {
      final response = await http
          .get(
            _uri('/api/auth/admin-session'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final parsed = _tryParseJson(response.body);
        return parsed?['success'] != false;
      }
      return false;
    } catch (err) {
      debugPrint('[AuthApiService] admin-session failed: $err');
      // Keep local session usable offline until explicit logout.
      return token.startsWith('local-');
    }
  }

  Future<void> adminLogout(String token) async {
    try {
      await http
          .post(
            _uri('/api/auth/admin-logout'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'token': token}),
          )
          .timeout(const Duration(seconds: 8));
    } catch (err) {
      debugPrint('[AuthApiService] admin-logout failed: $err');
    }
  }

  Future<AuthApiResult> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final encoded = Uri.encodeComponent(token.trim());
    return _postJson(
      '/api/auth/reset-password/$encoded',
      body: {
        'newPassword': newPassword,
      },
      fallbackSuccessMessage: 'Şifreniz başarıyla güncellendi.',
      fallbackErrorMessage:
          'Sıfırlama bağlantısının süresi dolmuş veya geçersiz.',
    );
  }

  Future<AuthApiResult> _postJson(
    String path, {
    required Map<String, dynamic> body,
    required String fallbackSuccessMessage,
    required String fallbackErrorMessage,
  }) async {
    try {
      final response = await http
          .post(
            _uri(path),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      final parsed = _tryParseJson(response.body);
      final message = (parsed?['message'] as String?)?.trim();
      final code = parsed?['code'] as String?;
      final token = parsed?['token'] as String?;
      final role = parsed?['role'] as String?;
      final ok = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          (parsed?['success'] != false);

      if (ok) {
        return AuthApiResult(
          success: true,
          message: (message != null && message.isNotEmpty)
              ? message
              : fallbackSuccessMessage,
          statusCode: response.statusCode,
          code: code,
          token: token,
          role: role,
        );
      }

      return AuthApiResult(
        success: false,
        message: (message != null && message.isNotEmpty)
            ? message
            : fallbackErrorMessage,
        statusCode: response.statusCode,
        code: code,
        token: token,
        role: role,
      );
    } catch (err, stack) {
      debugPrint('[AuthApiService] $path failed: $err\n$stack');
      return const AuthApiResult(
        success: false,
        message:
            'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.',
      );
    }
  }

  Map<String, dynamic>? _tryParseJson(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return null;
  }
}
