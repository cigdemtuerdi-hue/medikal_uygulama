import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/user_onboarding_models.dart';
import 'auth_session_service.dart';

/// Client for HIPAA consent + PHI audit / health-record APIs.
class ComplianceApiService {
  ComplianceApiService._();

  static final ComplianceApiService instance = ComplianceApiService._();

  static const hipaaNoticeVersion = 'hipaa-npp-2026.07';
  static const consentTypeHipaa = 'hipaa_npp';
  static const consentTypeHealthSubmit = 'health_data_submission';

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized');
  }

  Map<String, String> _phiHeaders({
    required UserRole? role,
    String? email,
    String? userId,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (role != null) headers['X-User-Role'] = role.name;
    if (email != null && email.trim().isNotEmpty) {
      headers['X-User-Email'] = email.trim().toLowerCase();
    }
    if (userId != null && userId.trim().isNotEmpty) {
      headers['X-User-Id'] = userId.trim();
    }
    return headers;
  }

  Future<bool> recordConsent({
    required String email,
    required String consentType,
    String? userId,
    String version = hipaaNoticeVersion,
  }) async {
    try {
      final response = await http
          .post(
            _uri('/api/compliance/consent'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              if (userId != null) 'userId': userId,
              'consentType': consentType,
              'version': version,
              'accepted': true,
            }),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (err) {
      debugPrint('[ComplianceApi] consent failed (non-fatal)');
      return false;
    }
  }

  Future<bool> recordAudit({
    required String action,
    required String resourceType,
    String? resourceId,
    String? details,
  }) async {
    try {
      final session = AuthSessionService.instance;
      await session.ensureLoaded();
      final response = await http
          .post(
            _uri('/api/compliance/audit'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'actorEmail': session.email,
              'actorRole': session.role?.name,
              'action': action,
              'resourceType': resourceType,
              if (resourceId != null) 'resourceId': resourceId,
              if (details != null) 'details': details,
            }),
          )
          .timeout(const Duration(seconds: 12));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Uploads PHI metadata (file refs / notes) — server encrypts at rest.
  Future<bool> upsertHealthRecord({
    required String recordType,
    String? title,
    String? notes,
    String? fileRef,
  }) async {
    try {
      final session = AuthSessionService.instance;
      await session.ensureLoaded();
      final role = session.role;
      if (role == null || role == UserRole.donor) {
        debugPrint('[ComplianceApi] RBAC: donor cannot write PHI');
        return false;
      }

      final response = await http
          .post(
            _uri('/api/health-records'),
            headers: _phiHeaders(
              role: role,
              email: session.email,
              userId: session.email,
            ),
            body: jsonEncode({
              'recordType': recordType,
              if (title != null) 'title': title,
              if (notes != null) 'notes': notes,
              if (fileRef != null) 'fileRef': fileRef,
            }),
          )
          .timeout(const Duration(seconds: 20));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (err) {
      debugPrint('[ComplianceApi] health-record write failed (non-fatal)');
      return false;
    }
  }
}
