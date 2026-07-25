// Platform-aware geocoding + distance lookup.
//
// - Web: Google Maps JavaScript API (no HTTP from Dart, so no CORS errors).
// - iOS/Android/desktop: Google Maps Web Services over HTTP.
export 'maps_distance_lookup_io.dart'
    if (dart.library.html) 'maps_distance_lookup_web.dart';
