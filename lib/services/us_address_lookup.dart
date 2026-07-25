// Platform-aware US address lookup.
//
// - Web: uses the Google Maps JavaScript API already loaded in
//   `web/index.html` (no HTTP requests from Dart, so no CORS issues).
// - iOS/Android/desktop: uses Google Maps Web Services over HTTP.
export 'us_address_lookup_io.dart'
    if (dart.library.html) 'us_address_lookup_web.dart';
