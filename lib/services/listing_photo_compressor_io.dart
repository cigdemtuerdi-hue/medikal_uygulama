import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'listing_photo_compressor_types.dart';

/// Native implementation: decode, downscale and re-encode on a background
/// isolate so a multi-megapixel photo does not drop frames on the UI thread.
Future<CompressedPhoto> compressListingPhoto(Uint8List input) {
  return compute(_downscale, input);
}

CompressedPhoto _downscale(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) {
    throw const PhotoCompressionException('Görsel okunamadı.');
  }

  // Phone cameras write the sensor orientation to EXIF rather than rotating
  // the pixels; without this the photo would upload sideways.
  final upright = img.bakeOrientation(decoded);

  final longestEdge =
      upright.width > upright.height ? upright.width : upright.height;
  final resized = longestEdge <= kListingPhotoMaxEdge
      ? upright
      : img.copyResize(
          upright,
          width: upright.width >= upright.height ? kListingPhotoMaxEdge : null,
          height: upright.height > upright.width ? kListingPhotoMaxEdge : null,
          interpolation: img.Interpolation.average,
        );

  return CompressedPhoto(
    bytes: img.encodeJpg(resized, quality: kListingPhotoJpegQuality),
    contentType: 'image/jpeg',
  );
}
