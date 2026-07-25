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

  /// PIN required to open the Admin Inquiries / Messages panel.
  static String get adminPin {
    const define = String.fromEnvironment('ADMIN_PIN');
    if (define.isNotEmpty) return define;
    try {
      final env = dotenv.maybeGet('ADMIN_PIN')?.trim();
      if (env != null && env.isNotEmpty) return env;
    } catch (_) {}
    return 'medgift';
  }
}
