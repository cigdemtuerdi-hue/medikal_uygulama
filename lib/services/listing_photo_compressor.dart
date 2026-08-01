/// Downscales and re-encodes a picked photo before upload.
///
/// A phone camera shot is routinely 4000×3000 and several megabytes, which is
/// slow to upload on a clinic's connection and wasteful to store. Both
/// implementations return a JPEG whose longest edge is
/// [kListingPhotoMaxEdge].
///
/// The two backends exist because decoding differs sharply by platform: pure
/// Dart decoding is fine on a native isolate but would freeze a browser tab for
/// seconds, so the web build hands the work to the browser's own image
/// pipeline instead.
library;

export 'listing_photo_compressor_types.dart';

export 'listing_photo_compressor_io.dart'
    if (dart.library.js_interop) 'listing_photo_compressor_web.dart';
