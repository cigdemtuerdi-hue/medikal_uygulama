import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/listing.dart';
import 'auth_session_service.dart';

/// Outcome of a listing API call.
class ListingApiResult<T> {
  const ListingApiResult({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
    this.code,
  });

  final bool success;
  final String message;
  final T? data;
  final int? statusCode;
  final String? code;

  /// True when the session token is missing or expired and the user must
  /// sign in again before the call can succeed.
  bool get needsLogin => statusCode == 401 || code == 'SESSION_REQUIRED';
}

/// HTTP client for `/api/listings` and the admin read-only views.
///
/// Every listing call carries the signed session token from
/// [AuthSessionService]; the server rejects anything else, so a user can only
/// ever read the PII-free projection of someone else's listing.
class ListingApiService {
  ListingApiService._();

  static final ListingApiService instance = ListingApiService._();

  static const _timeout = Duration(seconds: 20);

  /// Photos are far larger than a JSON body, and Render's free tier can be slow
  /// to wake, so uploads get a longer leash.
  static const _uploadTimeout = Duration(seconds: 60);

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    final normalized = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$normalized');
    if (query == null || query.isEmpty) return uri;
    final cleaned = Map<String, String>.from(query)
      ..removeWhere((_, v) => v.isEmpty);
    return uri.replace(queryParameters: cleaned);
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<String?> _sessionToken() async {
    await AuthSessionService.instance.ensureLoaded();
    return AuthSessionService.instance.token;
  }

  Map<String, dynamic>? _parse(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.map((k, v) => MapEntry('$k', v));
    } catch (_) {}
    return null;
  }

  ListingApiResult<T> _failure<T>(
    http.Response response,
    String fallback,
  ) {
    final parsed = _parse(response.body);
    final message = (parsed?['message'] as String?)?.trim();
    return ListingApiResult<T>(
      success: false,
      message: (message != null && message.isNotEmpty) ? message : fallback,
      statusCode: response.statusCode,
      code: parsed?['code'] as String?,
    );
  }

  ListingApiResult<T> _offline<T>() => const ListingApiResult(
        success: false,
        message: 'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.',
      );

  List<Listing> _listingsFrom(Map<String, dynamic>? json, String key) {
    final raw = json?[key] as List? ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => Listing.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// Publishes an offer, request, or paid sale.
  ///
  /// Donate kinds are derived from the account role on the server. Pass
  /// [kind] `'sale'` (and [priceCents]) for the marketplace — any signed-in
  /// user may sell.
  Future<ListingApiResult<Listing>> create({
    required String title,
    required String category,
    String? kind,
    String? description,
    String? condition,
    String? sizeNote,
    int quantity = 1,
    String urgency = 'normal',
    String? city,
    String? state,
    String? postalCode,
    List<String> photos = const [],
    int? priceCents,
  }) async {
    try {
      final response = await http
          .post(
            _uri('/api/listings'),
            headers: _headers(await _sessionToken()),
            body: jsonEncode({
              'title': title,
              'category': category,
              'kind': ?kind,
              'description': ?description,
              'condition': ?condition,
              'sizeNote': ?sizeNote,
              'quantity': quantity,
              'urgency': urgency,
              'city': ?city,
              'state': ?state,
              'postalCode': ?postalCode,
              'photos': photos,
              'priceCents': ?priceCents,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final parsed = _parse(response.body);
        final listing = parsed?['listing'] as Map?;
        return ListingApiResult<Listing>(
          success: true,
          message: 'İlanınız yayınlandı.',
          data: listing == null
              ? null
              : Listing.fromJson(listing.cast<String, dynamic>()),
          statusCode: response.statusCode,
        );
      }
      return _failure<Listing>(response, 'İlan yayınlanamadı.');
    } catch (err, stack) {
      debugPrint('[ListingApi] create failed: $err\n$stack');
      return _offline<Listing>();
    }
  }

  /// Uploads one listing photo and returns the path to reference it by.
  ///
  /// Sends the raw bytes rather than base64 or multipart: base64 would inflate
  /// the payload by a third for no benefit, and multipart would need a parser
  /// on the server for a single field.
  Future<ListingApiResult<String>> uploadPhoto({
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final token = await _sessionToken();
      final response = await http
          .post(
            _uri('/api/uploads'),
            headers: {
              'Content-Type': contentType,
              'Accept': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: bytes,
          )
          .timeout(_uploadTimeout);

      if (response.statusCode == 201) {
        final url = _parse(response.body)?['url']?.toString();
        if (url != null && url.isNotEmpty) {
          return ListingApiResult<String>(
            success: true,
            message: 'Görsel yüklendi.',
            data: url,
            statusCode: response.statusCode,
          );
        }
      }
      return _failure<String>(response, 'Görsel yüklenemedi.');
    } catch (err, stack) {
      debugPrint('[ListingApi] uploadPhoto failed: $err\n$stack');
      return _offline<String>();
    }
  }

  /// Absolute URL for a photo path returned by [uploadPhoto] or read off a
  /// [Listing]. Values that are already absolute are passed through.
  String photoUrlFor(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return _uri(path).toString();
  }

  /// The caller's own listings, including hidden ones.
  Future<ListingApiResult<List<Listing>>> listMine() async {
    return _getListings(
      '/api/listings/mine',
      key: 'listings',
      fallback: 'İlanlarınız yüklenemedi.',
    );
  }

  /// Counterpart listings with contact details stripped by the server.
  Future<ListingApiResult<List<Listing>>> browse({
    String? category,
    String? state,
    String? search,
    int limit = 60,
  }) async {
    return _getListings(
      '/api/listings/browse',
      key: 'listings',
      fallback: 'İlanlar yüklenemedi.',
      query: {
        'category': ?category,
        'state': ?state,
        'q': ?search,
        'limit': '$limit',
      },
    );
  }

  /// Active paid sale listings for the marketplace.
  Future<ListingApiResult<List<Listing>>> shop({
    String? category,
    String? state,
    String? search,
    int limit = 60,
  }) async {
    return _getListings(
      '/api/listings/shop',
      key: 'listings',
      fallback: 'Satış ilanları yüklenemedi.',
      query: {
        'category': ?category,
        'state': ?state,
        'q': ?search,
        'limit': '$limit',
      },
    );
  }

  /// Starts Stripe or PayPal Checkout for a sale listing.
  ///
  /// On success [ListingApiResult.data] is the hosted Checkout URL. When the
  /// API returns [code] `STRIPE_NOT_CONFIGURED` / `PAYPAL_NOT_CONFIGURED` /
  /// `PAYMENT_NOT_CONFIGURED`, call [purchase] instead (or try the other
  /// provider).
  Future<ListingApiResult<String>> checkout(
    String listingId, {
    String provider = 'stripe',
  }) async {
    try {
      final response = await http
          .post(
            _uri('/api/listings/$listingId/checkout'),
            headers: _headers(await _sessionToken()),
            body: jsonEncode({'provider': provider}),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final url = _parse(response.body)?['checkoutUrl']?.toString();
        if (url != null && url.isNotEmpty) {
          return ListingApiResult<String>(
            success: true,
            message: '',
            data: url,
            statusCode: response.statusCode,
          );
        }
      }
      return _failure<String>(response, 'Ödeme oturumu açılamadı.');
    } catch (err, stack) {
      debugPrint('[ListingApi] checkout failed: $err\n$stack');
      return _offline<String>();
    }
  }

  /// Starts Stripe / PayPal Checkout for multiple sale listings in one session.
  Future<ListingApiResult<String>> checkoutCart(
    List<String> listingIds, {
    String provider = 'stripe',
  }) async {
    try {
      final response = await http
          .post(
            _uri('/api/orders/cart/checkout'),
            headers: _headers(await _sessionToken()),
            body: jsonEncode({
              'listingIds': listingIds,
              'provider': provider,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final url = _parse(response.body)?['checkoutUrl']?.toString();
        if (url != null && url.isNotEmpty) {
          return ListingApiResult<String>(
            success: true,
            message: '',
            data: url,
            statusCode: response.statusCode,
          );
        }
      }
      return _failure<String>(response, 'Sepet ödemesi açılamadı.');
    } catch (err, stack) {
      debugPrint('[ListingApi] checkoutCart failed: $err\n$stack');
      return _offline<String>();
    }
  }

  /// Releases soft-holds when the buyer cancels hosted checkout.
  Future<ListingApiResult<void>> cancelPendingCheckout({
    String? orderId,
    String? cartCheckoutId,
  }) async {
    try {
      final response = await http
          .post(
            _uri('/api/orders/cancel-pending'),
            headers: _headers(await _sessionToken()),
            body: jsonEncode({
              if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
              if (cartCheckoutId != null && cartCheckoutId.isNotEmpty)
                'cartCheckoutId': cartCheckoutId,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return ListingApiResult<void>(
          success: true,
          message: '',
          statusCode: response.statusCode,
        );
      }
      return _failure<void>(response, 'Rezervasyon kaldırılamadı.');
    } catch (err, stack) {
      debugPrint('[ListingApi] cancelPendingCheckout failed: $err\n$stack');
      return _offline<void>();
    }
  }

  /// Captures a PayPal order after the buyer returns from PayPal.
  Future<ListingApiResult<SaleOrder>> capturePayPal(String paypalOrderId) async {
    try {
      final response = await http
          .post(
            _uri('/api/orders/paypal/capture'),
            headers: _headers(await _sessionToken()),
            body: jsonEncode({'paypalOrderId': paypalOrderId}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final raw = _parse(response.body)?['order'] as Map?;
        return ListingApiResult<SaleOrder>(
          success: true,
          message: '',
          data: raw == null
              ? null
              : SaleOrder.fromJson(raw.cast<String, dynamic>()),
          statusCode: response.statusCode,
        );
      }
      return _failure<SaleOrder>(response, 'PayPal ödemesi tamamlanamadı.');
    } catch (err, stack) {
      debugPrint('[ListingApi] capturePayPal failed: $err\n$stack');
      return _offline<SaleOrder>();
    }
  }

  /// Which checkout providers the API currently has credentials for.
  Future<({bool stripe, bool paypal})> paymentProviders() async {
    try {
      final response = await http
          .get(_uri('/api/health'))
          .timeout(const Duration(seconds: 12));
      final payments = _parse(response.body)?['payments'];
      if (payments is Map) {
        return (
          stripe: payments['stripeConfigured'] == true,
          paypal: payments['paypalConfigured'] == true,
        );
      }
    } catch (err, stack) {
      debugPrint('[ListingApi] paymentProviders failed: $err\n$stack');
    }
    return (stripe: false, paypal: false);
  }

  Future<ListingApiResult<SaleOrder>> orderBySession(String sessionId) async {
    try {
      final response = await http
          .get(
            _uri('/api/orders/by-session/$sessionId'),
            headers: _headers(await _sessionToken()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final raw = _parse(response.body)?['order'] as Map?;
        return ListingApiResult<SaleOrder>(
          success: true,
          message: '',
          data: raw == null
              ? null
              : SaleOrder.fromJson(raw.cast<String, dynamic>()),
          statusCode: response.statusCode,
        );
      }
      return _failure<SaleOrder>(response, 'Sipariş yüklenemedi.');
    } catch (err, stack) {
      debugPrint('[ListingApi] orderBySession failed: $err\n$stack');
      return _offline<SaleOrder>();
    }
  }

  /// Buyer hold on a sale listing when Stripe is not configured.
  Future<ListingApiResult<Listing>> purchase(String listingId) async {
    try {
      final response = await http
          .post(
            _uri('/api/listings/$listingId/purchase'),
            headers: _headers(await _sessionToken()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final parsed = _parse(response.body);
        final listing = parsed?['listing'] as Map?;
        final message = (parsed?['message'] as String?)?.trim();
        return ListingApiResult<Listing>(
          success: true,
          message: (message != null && message.isNotEmpty)
              ? message
              : 'Satın alma talebiniz alındı.',
          data: listing == null
              ? null
              : Listing.fromJson(listing.cast<String, dynamic>()),
          statusCode: response.statusCode,
        );
      }
      return _failure<Listing>(response, 'Satın alma talebi gönderilemedi.');
    } catch (err, stack) {
      debugPrint('[ListingApi] purchase failed: $err\n$stack');
      return _offline<Listing>();
    }
  }

  /// Ranked counterparts for one of the caller's own listings.
  Future<ListingApiResult<List<Listing>>> matchesFor(String listingId) async {
    return _getListings(
      '/api/listings/$listingId/matches',
      key: 'matches',
      fallback: 'Eşleşmeler yüklenemedi.',
    );
  }

  Future<ListingApiResult<List<Listing>>> _getListings(
    String path, {
    required String key,
    required String fallback,
    Map<String, String>? query,
  }) async {
    try {
      final response = await http
          .get(_uri(path, query), headers: _headers(await _sessionToken()))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return ListingApiResult<List<Listing>>(
          success: true,
          message: '',
          data: _listingsFrom(_parse(response.body), key),
          statusCode: response.statusCode,
        );
      }
      return _failure<List<Listing>>(response, fallback);
    } catch (err, stack) {
      debugPrint('[ListingApi] $path failed: $err\n$stack');
      return _offline<List<Listing>>();
    }
  }

  /// Places a 48-hour hold on a counterpart listing.
  Future<ListingApiResult<Listing>> reserve(String listingId) async {
    try {
      final response = await http
          .post(
            _uri('/api/listings/$listingId/reserve'),
            headers: _headers(await _sessionToken()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final listing = _parse(response.body)?['listing'] as Map?;
        return ListingApiResult<Listing>(
          success: true,
          message: 'İlan 48 saat için size ayrıldı.',
          data: listing == null
              ? null
              : Listing.fromJson(listing.cast<String, dynamic>()),
          statusCode: response.statusCode,
        );
      }
      return _failure<Listing>(response, 'Rezervasyon yapılamadı.');
    } catch (err, stack) {
      debugPrint('[ListingApi] reserve failed: $err\n$stack');
      return _offline<Listing>();
    }
  }

  /// Owner-only status change, e.g. marking an item as handed over.
  Future<ListingApiResult<Listing>> updateStatus(
    String listingId,
    String status,
  ) async {
    try {
      final response = await http
          .patch(
            _uri('/api/listings/$listingId'),
            headers: _headers(await _sessionToken()),
            body: jsonEncode({'status': status}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final listing = _parse(response.body)?['listing'] as Map?;
        return ListingApiResult<Listing>(
          success: true,
          message: 'İlan güncellendi.',
          data: listing == null
              ? null
              : Listing.fromJson(listing.cast<String, dynamic>()),
          statusCode: response.statusCode,
        );
      }
      return _failure<Listing>(response, 'İlan güncellenemedi.');
    } catch (err, stack) {
      debugPrint('[ListingApi] updateStatus failed: $err\n$stack');
      return _offline<Listing>();
    }
  }

  // ---------------------------------------------------------------------
  // Admin console (requires the admin token, not the user session token).
  // ---------------------------------------------------------------------

  Future<ListingApiResult<AdminOverview>> adminOverview(String adminToken) async {
    try {
      final response = await http
          .get(_uri('/api/admin/overview'), headers: _headers(adminToken))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final parsed = _parse(response.body);
        return ListingApiResult<AdminOverview>(
          success: true,
          message: '',
          data: parsed == null ? null : AdminOverview.fromJson(parsed),
          statusCode: response.statusCode,
        );
      }
      return _failure<AdminOverview>(response, 'Özet yüklenemedi.');
    } catch (err, stack) {
      debugPrint('[ListingApi] adminOverview failed: $err\n$stack');
      return _offline<AdminOverview>();
    }
  }

  Future<ListingApiResult<List<AdminUser>>> adminUsers(
    String adminToken, {
    String? role,
  }) async {
    try {
      final response = await http
          .get(
            _uri('/api/admin/users', {'role': ?role}),
            headers: _headers(adminToken),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final raw = _parse(response.body)?['users'] as List? ?? const [];
        return ListingApiResult<List<AdminUser>>(
          success: true,
          message: '',
          data: raw
              .whereType<Map>()
              .map((e) => AdminUser.fromJson(e.cast<String, dynamic>()))
              .toList(growable: false),
          statusCode: response.statusCode,
        );
      }
      return _failure<List<AdminUser>>(response, 'Kullanıcılar yüklenemedi.');
    } catch (err, stack) {
      debugPrint('[ListingApi] adminUsers failed: $err\n$stack');
      return _offline<List<AdminUser>>();
    }
  }

  Future<ListingApiResult<List<Listing>>> adminListings(
    String adminToken, {
    String? kind,
  }) async {
    try {
      final response = await http
          .get(
            _uri('/api/admin/listings', {'kind': ?kind}),
            headers: _headers(adminToken),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return ListingApiResult<List<Listing>>(
          success: true,
          message: '',
          data: _listingsFrom(_parse(response.body), 'listings'),
          statusCode: response.statusCode,
        );
      }
      return _failure<List<Listing>>(response, 'İlanlar yüklenemedi.');
    } catch (err, stack) {
      debugPrint('[ListingApi] adminListings failed: $err\n$stack');
      return _offline<List<Listing>>();
    }
  }
}
