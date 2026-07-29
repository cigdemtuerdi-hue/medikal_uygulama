import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central configuration for Google Maps Platform and admin messaging.
class AppConfig {
  /// Single API key for Places, Geocoding, Distance Matrix, and Maps SDK.
  ///
  /// Resolution order:
  /// 1. `--dart-define=GOOGLE_MAPS_API_KEY=...`
  /// 2. `--dart-define=GOOGLE_PLACES_API_KEY=...` (legacy alias)
  /// 3. `GOOGLE_MAPS_API_KEY` in `.env`
  /// 4. `GOOGLE_PLACES_API_KEY` in `.env` (legacy alias)
  static String get googleMapsApiKey {
    const mapsDefine = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (mapsDefine.isNotEmpty) return mapsDefine;

    const placesDefine = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
    if (placesDefine.isNotEmpty) return placesDefine;

    try {
      final mapsEnv = dotenv.maybeGet('GOOGLE_MAPS_API_KEY')?.trim();
      if (mapsEnv != null && mapsEnv.isNotEmpty) return mapsEnv;

      return dotenv.maybeGet('GOOGLE_PLACES_API_KEY')?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  static bool get hasGoogleMapsApiKey => googleMapsApiKey.isNotEmpty;

  @Deprecated('Use googleMapsApiKey')
  static String get googlePlacesApiKey => googleMapsApiKey;

  @Deprecated('Use hasGoogleMapsApiKey')
  static bool get usesGooglePlaces => hasGoogleMapsApiKey;

  static String get missingApiKeyMessage =>
      'Google Maps API key is not configured. '
      'Copy .env.example to .env and set GOOGLE_MAPS_API_KEY.';

  /// Destination inbox for Contact Us / Sponsorship notifications.
  static String get adminNotifyEmail {
    const define = String.fromEnvironment('ADMIN_NOTIFY_EMAIL');
    if (define.isNotEmpty) return define;
    try {
      final env = dotenv.maybeGet('ADMIN_NOTIFY_EMAIL')?.trim();
      if (env != null && env.isNotEmpty) return env;
    } catch (_) {}
    return 'partnerships@medgift.us';
  }

  /// Formspree / webhook URL that forwards inquiries to [adminNotifyEmail].
  /// Leave empty to run in demo mode (in-app inbox only + console log).
  static String get adminEmailEndpoint {
    const define = String.fromEnvironment('ADMIN_EMAIL_ENDPOINT');
    if (define.isNotEmpty) return define;
    try {
      return dotenv.maybeGet('ADMIN_EMAIL_ENDPOINT')?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// PIN required to open the Admin Inquiries / Messages panel (legacy alias).
  static String get adminPin {
    const define = String.fromEnvironment('ADMIN_PIN');
    if (define.isNotEmpty) return define;
    try {
      final env = dotenv.maybeGet('ADMIN_PIN')?.trim();
      if (env != null && env.isNotEmpty) return env;
    } catch (_) {}
    return adminPassword;
  }

  /// Owner admin console email (only this account can unlock `/admin`).
  static String get adminEmail {
    const define = String.fromEnvironment('ADMIN_EMAIL');
    if (define.isNotEmpty) return define.trim();
    try {
      final env = dotenv.maybeGet('ADMIN_EMAIL')?.trim();
      if (env != null && env.isNotEmpty) return env;
    } catch (_) {}
    return adminNotifyEmail;
  }

  /// Owner admin console password. Prefer server-side ADMIN_PASSWORD on Render.
  /// Local/build value is only a fallback when the API is unreachable.
  static String get adminPassword {
    const define = String.fromEnvironment('ADMIN_PASSWORD');
    if (define.isNotEmpty) return define;
    try {
      final env = dotenv.maybeGet('ADMIN_PASSWORD')?.trim();
      if (env != null && env.isNotEmpty) return env;
    } catch (_) {}
    const pinDefine = String.fromEnvironment('ADMIN_PIN');
    if (pinDefine.isNotEmpty) return pinDefine;
    try {
      final pin = dotenv.maybeGet('ADMIN_PIN')?.trim();
      if (pin != null && pin.isNotEmpty) return pin;
    } catch (_) {}
    return '';
  }

  static bool get hasLocalAdminCredentials =>
      adminEmail.trim().isNotEmpty && adminPassword.trim().isNotEmpty;

  /// Base URL for the MedGift Node API (forgot / reset password, etc.).
  ///
  /// Resolution order:
  /// 1. `--dart-define=API_BASE_URL=...`
  /// 2. `API_BASE_URL` in `.env`
  /// 3. Local default `http://localhost:3001`
  static String get apiBaseUrl {
    const define = String.fromEnvironment('API_BASE_URL');
    if (define.isNotEmpty) return define.trim().replaceAll(RegExp(r'/$'), '');
    try {
      final env = dotenv.maybeGet('API_BASE_URL')?.trim();
      if (env != null && env.isNotEmpty) {
        return env.replaceAll(RegExp(r'/$'), '');
      }
    } catch (_) {}
    return 'http://127.0.0.1:3001';
  }
}
