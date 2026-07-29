import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/site_settings.dart';
import 'admin_access_service.dart';
import 'emergency_mode_service.dart';

/// Loads and caches CMS site settings; admin can push updates.
class SiteSettingsService extends ChangeNotifier {
  SiteSettingsService._();

  static final SiteSettingsService instance = SiteSettingsService._();

  SiteSettings _settings = SiteSettings.defaults();
  bool _loaded = false;
  String? _lastError;

  SiteSettings get settings => _settings;
  bool get isLoaded => _loaded;
  String? get lastError => _lastError;
  String get persistence => _settings.persistence;

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base$path');
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await refresh();
  }

  Future<bool> refresh() async {
    try {
      final response = await http
          .get(
            _uri('/api/settings/public'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final raw = decoded['settings'];
          final persistence = decoded['persistence']?.toString() ?? 'memory';
          if (raw is Map) {
            _settings = SiteSettings.fromJson(
              Map<String, dynamic>.from(raw),
              persistence: persistence,
            );
            _lastError = null;
            _loaded = true;
            await _syncEmergencyLocalFlag();
            notifyListeners();
            return true;
          }
        }
      }
      _lastError = 'Ayarlar yüklenemedi (${response.statusCode}).';
    } catch (err, stack) {
      debugPrint('[SiteSettings] refresh failed: $err\n$stack');
      _lastError = 'Ayarlar sunucusuna bağlanılamadı.';
    }
    _loaded = true;
    notifyListeners();
    return false;
  }

  Future<void> _syncEmergencyLocalFlag() async {
    // Server CMS is source of truth for emergency enabled.
    await EmergencyModeService.instance.setEnabled(_settings.emergency.enabled);
  }

  Future<bool> save(SiteSettings next) async {
    final token = AdminAccessService.instance.token;
    if (token == null || token.isEmpty || token.startsWith('local-')) {
      // Local-only fallback: apply in-memory for this browser session.
      if (token != null && token.startsWith('local-')) {
        _settings = next.copyWith(
          updatedAt: DateTime.now(),
          persistence: 'local',
        );
        await _syncEmergencyLocalFlag();
        notifyListeners();
        return true;
      }
      _lastError = 'Admin oturumu gerekli.';
      notifyListeners();
      return false;
    }

    try {
      final response = await http
          .put(
            _uri('/api/settings/admin'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(next.toJson()),
          )
          .timeout(const Duration(seconds: 20));

      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded is Map<String, dynamic> &&
          decoded['success'] != false) {
        final raw = decoded['settings'];
        final persistence = decoded['persistence']?.toString() ?? 'memory';
        if (raw is Map) {
          _settings = SiteSettings.fromJson(
            Map<String, dynamic>.from(raw),
            persistence: persistence,
          );
        } else {
          _settings = next.copyWith(persistence: persistence);
        }
        _lastError = null;
        await _syncEmergencyLocalFlag();
        notifyListeners();
        return true;
      }

      final message = decoded is Map ? decoded['message']?.toString() : null;
      _lastError = (message != null && message.isNotEmpty)
          ? message
          : 'Kayıt başarısız (${response.statusCode}).';
    } catch (err, stack) {
      debugPrint('[SiteSettings] save failed: $err\n$stack');
      _lastError = 'Kayıt sırasında sunucuya bağlanılamadı.';
    }
    notifyListeners();
    return false;
  }

  /// Prefer CMS override when non-empty, otherwise l10n / fallback.
  String text(String? cmsValue, String fallback) {
    final v = cmsValue?.trim() ?? '';
    return v.isEmpty ? fallback : v;
  }
}
