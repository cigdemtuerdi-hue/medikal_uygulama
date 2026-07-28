import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

bool _isGoogleMapsLoaded() {
  final readyFlag =
      globalContext.getProperty<JSBoolean?>('googleMapsReady'.toJS);
  if (readyFlag != null && !readyFlag.isUndefinedOrNull && readyFlag.toDart) {
    return true;
  }

  final google = globalContext.getProperty<JSObject?>('google'.toJS);
  if (google == null || google.isUndefinedOrNull) return false;
  final maps = google.getProperty<JSObject?>('maps'.toJS);
  return maps != null && !maps.isUndefinedOrNull;
}

bool get isGoogleMapsScriptReady => _isGoogleMapsLoaded();

Future<bool> waitForGoogleMapsReady({
  Duration timeout = const Duration(seconds: 20),
}) async {
  if (_isGoogleMapsLoaded()) return true;

  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (_isGoogleMapsLoaded()) return true;
  }
  return _isGoogleMapsLoaded();
}
