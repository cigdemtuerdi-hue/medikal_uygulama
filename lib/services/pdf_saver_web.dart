import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

class PdfSaver {
  PdfSaver._();

  /// Triggers a browser download of [bytes] as [fileName] using a
  /// data-URL anchor element. Returns a user-facing status message.
  static Future<String> save(Uint8List bytes, String fileName) async {
    final dataUrl = 'data:application/pdf;base64,${base64Encode(bytes)}';

    final document = globalContext.getProperty<JSObject>('document'.toJS);
    final anchor = document.callMethod<JSObject>(
      'createElement'.toJS,
      'a'.toJS,
    );
    anchor.setProperty('href'.toJS, dataUrl.toJS);
    anchor.setProperty('download'.toJS, fileName.toJS);
    anchor.callMethod<JSAny?>('click'.toJS);

    return 'Downloaded $fileName';
  }
}
