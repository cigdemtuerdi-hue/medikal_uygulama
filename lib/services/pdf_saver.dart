// Platform-aware PDF file saver.
//
// - Web: triggers a browser download (Blob + anchor element).
// - iOS/Android/desktop: writes the file to the app documents directory.
export 'pdf_saver_io.dart' if (dart.library.html) 'pdf_saver_web.dart';
