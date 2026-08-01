import 'dart:typed_data';

/// A listing photo after downscaling, ready to POST to `/api/uploads`.
class CompressedPhoto {
  const CompressedPhoto({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}

/// Longest edge we keep. A listing photo is only ever shown in a card or a
/// full-screen viewer, so anything beyond this is bytes the donor pays for in
/// upload time and we pay for in storage.
const int kListingPhotoMaxEdge = 1600;

/// JPEG quality. High enough that scratches and model plates on used equipment
/// stay legible, low enough to keep a typical photo near 200 kb.
const int kListingPhotoJpegQuality = 82;

/// Raised when the bytes are not a decodable image.
class PhotoCompressionException implements Exception {
  const PhotoCompressionException(this.message);

  final String message;

  @override
  String toString() => message;
}
