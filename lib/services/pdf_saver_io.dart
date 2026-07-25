import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class PdfSaver {
  PdfSaver._();

  /// Saves [bytes] as [fileName] and returns a user-facing description of
  /// where the file went.
  static Future<String> save(Uint8List bytes, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return 'Saved to ${file.path}';
  }
}
