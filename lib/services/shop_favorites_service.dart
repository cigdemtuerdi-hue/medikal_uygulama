import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local favorites for Shop sale listings (persisted on device).
class ShopFavoritesService extends ChangeNotifier {
  ShopFavoritesService._() {
    ensureLoaded();
  }

  static final ShopFavoritesService instance = ShopFavoritesService._();

  static const _prefsKey = 'medgift_shop_favorites_v1';

  final Set<String> _ids = <String>{};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  int get count => _ids.length;
  Set<String> get ids => Set.unmodifiable(_ids);

  bool contains(String listingId) => _ids.contains(listingId);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? const <String>[];
      _ids
        ..clear()
        ..addAll(raw.where((id) => id.trim().isNotEmpty));
    } catch (err, stack) {
      debugPrint('[ShopFavorites] load failed: $err\n$stack');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(String listingId) async {
    await ensureLoaded();
    if (_ids.contains(listingId)) {
      _ids.remove(listingId);
    } else {
      _ids.add(listingId);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> add(String listingId) async {
    await ensureLoaded();
    if (_ids.add(listingId)) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> remove(String listingId) async {
    await ensureLoaded();
    if (_ids.remove(listingId)) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _ids.toList(growable: false));
    } catch (err, stack) {
      debugPrint('[ShopFavorites] persist failed: $err\n$stack');
    }
  }
}
