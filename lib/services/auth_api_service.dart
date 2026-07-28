import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

enum PasswordResetMethod { email, sms }

/// Result of an auth API call (forgot / reset password).
class AuthApiResult {
  const AuthApiResult({
    required this.success,
    required this.message,
    this.statusCode,
    this.code,
    this.method,
    this.phoneHint,
    this.devCode,
    this.dryRun = false,
  });

  final bool success;
  final String message;
  final int? statusCode;
  final String? code;
  final PasswordResetMethod? method;
  final String? phoneHint;
  /// Present only when API runs with SMS_DRY_RUN=true (local/dev).
  final String? devCode;
  final bool dryRun;
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
    String? phone,
    PasswordResetMethod method = PasswordResetMethod.email,
  }) async {
    final body = <String, dynamic>{
      'method': method == PasswordResetMethod.sms ? 'sms' : 'email',
    };
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isNotEmpty) body['email'] = trimmedEmail;
    final trimmedPhone = phone?.trim() ?? '';
    if (trimmedPhone.isNotEmpty) body['phone'] = trimmedPhone;

    return _postJson(
      '/api/auth/forgot-password',
      body: body,
      fallbackSuccessMessage: method == PasswordResetMethod.sms
          ? 'Doğrulama kodu telefonunuza SMS ile gönderildi.'
          : 'Sıfırlama bağlantısı e-postanıza gönderildi',
      fallbackErrorMessage:
          'Şifre sıfırlama isteği gönderilemedi. Lütfen tekrar deneyin.',
    );
  }

  Future<AuthApiResult> register({
    required String email,
    required String password,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'password': password,
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

  Future<AuthApiResult> resetPasswordWithSms({
    String? email,
    String? phone,
    required String code,
    required String newPassword,
  }) async {
    final body = <String, dynamic>{
      'code': code.trim(),
      'newPassword': newPassword,
    };
    final trimmedEmail = email?.trim().toLowerCase() ?? '';
    if (trimmedEmail.isNotEmpty) body['email'] = trimmedEmail;
    final trimmedPhone = phone?.trim() ?? '';
    if (trimmedPhone.isNotEmpty) body['phone'] = trimmedPhone;

    return _postJson(
      '/api/auth/reset-password-sms',
      body: body,
      fallbackSuccessMessage: 'Şifreniz başarıyla güncellendi.',
      fallbackErrorMessage: 'SMS kodu geçersiz veya süresi dolmuş.',
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
      final phoneHint = (parsed?['phoneHint'] as String?)?.trim();
      final devCode = (parsed?['devCode'] as String?)?.trim();
      final dryRun = parsed?['dryRun'] == true;
      final methodRaw = (parsed?['method'] as String?)?.trim().toLowerCase();
      final method = methodRaw == 'sms'
          ? PasswordResetMethod.sms
          : methodRaw == 'email'
              ? PasswordResetMethod.email
              : null;
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
          method: method,
          phoneHint: phoneHint,
          devCode: devCode,
          dryRun: dryRun,
        );
      }

      return AuthApiResult(
        success: false,
        message: (message != null && message.isNotEmpty)
            ? message
            : fallbackErrorMessage,
        statusCode: response.statusCode,
        code: code,
        method: method,
        phoneHint: phoneHint,
        devCode: devCode,
        dryRun: dryRun,
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
