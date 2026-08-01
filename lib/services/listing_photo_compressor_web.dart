import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'listing_photo_compressor_types.dart';

/// Web implementation: hand the decode, resize and re-encode to the browser.
///
/// Decoding a 12-megapixel JPEG in pure Dart would block the single browser
/// thread for seconds — `compute` is a no-op on web, so there is nowhere to
/// move the work to. The browser's own pipeline is native code and runs off
/// the main thread for the decode.
Future<CompressedPhoto> compressListingPhoto(Uint8List input) async {
  final source = web.Blob([input.toJS].toJS);

  final web.ImageBitmap bitmap;
  try {
    bitmap = await web.window.createImageBitmap(source).toDart;
  } catch (_) {
    throw const PhotoCompressionException('Görsel okunamadı.');
  }

  try {
    final longestEdge =
        bitmap.width > bitmap.height ? bitmap.width : bitmap.height;
    final scale = longestEdge <= kListingPhotoMaxEdge
        ? 1.0
        : kListingPhotoMaxEdge / longestEdge;
    final width = (bitmap.width * scale).round().clamp(1, kListingPhotoMaxEdge);
    final height =
        (bitmap.height * scale).round().clamp(1, kListingPhotoMaxEdge);

    final canvas = web.HTMLCanvasElement()
      ..width = width
      ..height = height;
    final context = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
    if (context == null) {
      throw const PhotoCompressionException('Tarayıcı görseli işleyemedi.');
    }
    context.drawImage(bitmap, 0, 0, width, height);

    final blob = await _toBlob(canvas);
    if (blob == null) {
      throw const PhotoCompressionException('Görsel dönüştürülemedi.');
    }

    final buffer = await blob.arrayBuffer().toDart;
    return CompressedPhoto(
      bytes: buffer.toDart.asUint8List(),
      contentType: 'image/jpeg',
    );
  } finally {
    bitmap.close();
  }
}

/// `toBlob` is callback-based; wrap it so callers can await it.
Future<web.Blob?> _toBlob(web.HTMLCanvasElement canvas) {
  final completer = Completer<web.Blob?>();
  canvas.toBlob(
    (web.Blob? blob) {
      if (!completer.isCompleted) completer.complete(blob);
    }.toJS,
    'image/jpeg',
    (kListingPhotoJpegQuality / 100).toJS,
  );
  return completer.future;
}
