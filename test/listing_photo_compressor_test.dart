import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:medikal_uygulama/services/listing_photo_compressor.dart';

/// Exercises the real compressor on whichever platform the test runs on.
///
/// Run against the browser too — the web implementation calls into
/// `createImageBitmap` and `canvas.toBlob`, whose runtime behaviour a VM test
/// cannot cover:
///
///   flutter test test/listing_photo_compressor_test.dart
///   flutter test --platform chrome test/listing_photo_compressor_test.dart
Uint8List samplePhoto({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  // A flat fill would survive any resize, so paint a gradient plus a marker
  // block that a broken scale or crop would visibly destroy.
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgb(x, y, (x * 255) ~/ width, (y * 255) ~/ height, 90);
    }
  }
  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: width ~/ 8,
    y2: height ~/ 8,
    color: img.ColorRgb8(255, 0, 0),
  );
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  test('downscales an oversized photo to the long-edge budget', () async {
    final source = samplePhoto(width: 3200, height: 2400);

    final result = await compressListingPhoto(source);

    expect(result.contentType, 'image/jpeg');

    final decoded = img.decodeJpg(result.bytes);
    expect(decoded, isNotNull, reason: 'output should be a valid JPEG');
    expect(decoded!.width, kListingPhotoMaxEdge);
    // 3200x2400 is 4:3; the height must scale with it rather than stretch.
    expect(decoded.height, closeTo(kListingPhotoMaxEdge * 3 / 4, 2));
    // The point of compressing is that a phone photo fits comfortably under
    // the server's 2 MB ceiling with room to spare on a slow connection.
    expect(result.bytes.length, lessThan(500 * 1024));
  });

  test('keeps a portrait photo upright', () async {
    final result = await compressListingPhoto(
      samplePhoto(width: 1200, height: 2400),
    );

    final decoded = img.decodeJpg(result.bytes)!;
    expect(decoded.height, kListingPhotoMaxEdge);
    expect(decoded.width, closeTo(kListingPhotoMaxEdge / 2, 2));
  });

  test('leaves an already-small photo at its original size', () async {
    final result = await compressListingPhoto(
      samplePhoto(width: 640, height: 480),
    );

    final decoded = img.decodeJpg(result.bytes)!;
    expect(decoded.width, 640);
    expect(decoded.height, 480);
  });

  test('rejects bytes that are not an image', () async {
    await expectLater(
      compressListingPhoto(Uint8List.fromList(List.filled(256, 7))),
      throwsA(isA<Exception>()),
    );
  });
}
