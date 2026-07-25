import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Session gate for the Admin Inquiries / Messages panel.
class AdminAccessService extends ChangeNotifier {
  AdminAccessService._();

  static final AdminAccessService instance = AdminAccessService._();

  bool _authenticated = false;

  bool get isAuthenticated => _authenticated;

  bool unlock(String pin) {
    final ok = pin.trim() == AppConfig.adminPin;
    if (ok) {
      _authenticated = true;
      notifyListeners();
    }
    return ok;
  }

  void lock() {
    if (!_authenticated) return;
    _authenticated = false;
    notifyListeners();
  }
}
