import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/listing.dart'; // formatUsdCents

/// Local shopping cart for marketplace sale listings (one of each item).
class CartService extends ChangeNotifier {
  CartService._();

  static final CartService instance = CartService._();

  static const _prefsKey = 'medgift_cart_v1';
  static const maxItems = 10;

  final List<CartItem> _items = [];
  bool _loaded = false;

  List<CartItem> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  int get totalCents =>
      _items.fold<int>(0, (sum, item) => sum + item.priceCents);

  String get totalLabel => formatUsdCents(totalCents);

  bool contains(String listingId) =>
      _items.any((item) => item.listingId == listingId);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    _items.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final row in decoded) {
            if (row is Map) {
              final item =
                  CartItem.fromJson(row.cast<String, dynamic>());
              if (item.listingId.isNotEmpty && item.priceCents >= 100) {
                _items.add(item);
              }
            }
          }
        }
      } catch (err, stack) {
        debugPrint('[Cart] load failed: $err\n$stack');
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_items.map((e) => e.toJson()).toList(growable: false)),
    );
  }

  /// Returns a stable outcome code for UI snackbars.
  Future<String> addListing(Listing listing) async {
    await ensureLoaded();
    if (!listing.isSale || listing.id.isEmpty) return 'invalid';
    if ((listing.priceCents ?? 0) < 100) return 'invalid';

    if (contains(listing.id)) return 'duplicate';
    if (_items.length >= maxItems) return 'full';

    _items.add(CartItem.fromListing(listing));
    await _persist();
    notifyListeners();
    return 'added';
  }

  Future<void> remove(String listingId) async {
    await ensureLoaded();
    final before = _items.length;
    _items.removeWhere((item) => item.listingId == listingId);
    if (_items.length == before) return;
    await _persist();
    notifyListeners();
  }

  Future<void> clear() async {
    await ensureLoaded();
    if (_items.isEmpty) return;
    _items.clear();
    await _persist();
    notifyListeners();
  }

  List<String> get listingIds =>
      _items.map((e) => e.listingId).toList(growable: false);
}
