/// A donor offer, recipient request, or paid sale as returned by `/api/listings`.
///
/// The API decides what each caller may see, so this model holds the union of
/// the public, owner and admin projections and leaves the fields the caller was
/// not entitled to as null. Read [ownerEmail] only in the admin console.
class Listing {
  const Listing({
    required this.id,
    required this.kind,
    required this.title,
    required this.category,
    this.description = '',
    this.condition,
    this.sizeNote,
    this.quantity = 1,
    this.urgency = 'normal',
    this.city,
    this.state,
    this.postalPrefix,
    this.postalCode,
    this.photos = const [],
    this.photoUrl,
    this.priceCents,
    this.currency,
    this.commissionRate,
    this.commissionCents,
    this.sellerNetCents,
    this.status = 'active',
    this.reservedUntil,
    this.createdAt,
    this.hidden = false,
    this.ownerEmail,
    this.ownerUserId,
    this.ownerRole,
    this.matchScore,
    this.matchReasons = const [],
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) {
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    return Listing(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'offer',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      condition: json['condition']?.toString(),
      sizeNote: json['sizeNote']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      urgency: json['urgency']?.toString() ?? 'normal',
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      postalPrefix: json['postalPrefix']?.toString(),
      postalCode: json['postalCode']?.toString(),
      photos: (json['photos'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList(growable: false) ??
          const [],
      photoUrl: json['photoUrl']?.toString(),
      priceCents: (json['priceCents'] as num?)?.toInt(),
      currency: json['currency']?.toString(),
      commissionRate: (json['commissionRate'] as num?)?.toDouble(),
      commissionCents: (json['commissionCents'] as num?)?.toInt(),
      sellerNetCents: (json['sellerNetCents'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'active',
      reservedUntil: parseDate(json['reservedUntil']),
      createdAt: parseDate(json['createdAt']),
      hidden: json['hidden'] == true,
      ownerEmail: json['ownerEmail']?.toString(),
      ownerUserId: json['ownerUserId']?.toString(),
      ownerRole: json['ownerRole']?.toString(),
      matchScore: (json['matchScore'] as num?)?.toInt(),
      matchReasons: (json['matchReasons'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
    );
  }

  final String id;

  /// 'offer' | 'request' | 'sale'
  final String kind;
  final String title;
  final String category;
  final String description;
  final String? condition;
  final String? sizeNote;
  final int quantity;
  final String urgency;
  final String? city;
  final String? state;

  /// First three ZIP digits — as precise as counterparts are allowed to see.
  final String? postalPrefix;

  /// Full ZIP, present only on the owner's own listings.
  final String? postalCode;

  /// Photo paths relative to the API host, in display order. Up to five.
  final List<String> photos;

  /// Cover image on records created before [photos] existed.
  final String? photoUrl;

  /// Asking price in USD cents — only set on [isSale] listings.
  final int? priceCents;
  final String? currency;
  final double? commissionRate;
  final int? commissionCents;
  final int? sellerNetCents;
  final String status;
  final DateTime? reservedUntil;
  final DateTime? createdAt;
  final bool hidden;

  /// Admin-only fields.
  final String? ownerEmail;
  final String? ownerUserId;
  final String? ownerRole;

  /// Populated by `/api/listings/:id/matches`.
  final int? matchScore;
  final List<String> matchReasons;

  bool get isOffer => kind == 'offer';
  bool get isSale => kind == 'sale';
  bool get isUrgent => urgency == 'high';

  /// Formatted asking price, e.g. `$125.00`. Empty when not a sale.
  String get priceLabel {
    final cents = priceCents;
    if (cents == null) return '';
    return formatUsdCents(cents);
  }

  /// Photos to display, falling back to the pre-[photos] single-image field.
  List<String> get displayPhotos {
    if (photos.isNotEmpty) return photos;
    final legacy = photoUrl;
    return (legacy != null && legacy.isNotEmpty) ? [legacy] : const [];
  }

  /// Human-readable location at the precision the caller is allowed to see.
  String get locationLabel {
    final parts = <String>[
      if (city != null && city!.isNotEmpty) city!,
      if (state != null && state!.isNotEmpty) state!,
    ];
    final zip = postalCode ?? (postalPrefix != null ? '$postalPrefix**' : null);
    if (zip != null) parts.add(zip);
    return parts.isEmpty ? 'Konum belirtilmemiş' : parts.join(', ');
  }
}

/// Formats integer USD cents as `$1,234.56`.
String formatUsdCents(int cents) {
  final dollars = cents / 100;
  final whole = dollars.truncate();
  final frac = (cents.abs() % 100).toString().padLeft(2, '0');
  final wholeStr = whole.abs().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );
  final sign = cents < 0 ? '-' : '';
  return '$sign\$$wholeStr.$frac';
}

/// A registered account as shown in the admin console.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    this.role,
    this.phoneMasked,
    this.hasPassword = false,
    this.hipaaConsentVersion,
    this.hipaaConsentAt,
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) {
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    return AdminUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString(),
      phoneMasked: json['phoneMasked']?.toString(),
      hasPassword: json['hasPassword'] == true,
      hipaaConsentVersion: json['hipaaConsentVersion']?.toString(),
      hipaaConsentAt: parseDate(json['hipaaConsentAt']),
      createdAt: parseDate(json['createdAt']),
    );
  }

  final String id;
  final String email;
  final String? role;
  final String? phoneMasked;
  final bool hasPassword;
  final String? hipaaConsentVersion;
  final DateTime? hipaaConsentAt;
  final DateTime? createdAt;
}

/// Headline counts for the admin dashboard.
class AdminOverview {
  const AdminOverview({
    required this.totalUsers,
    required this.usersByRole,
    required this.offers,
    required this.requests,
    required this.reserved,
    required this.fulfilled,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    final users = (json['users'] as Map?)?.cast<String, dynamic>() ?? const {};
    final listings =
        (json['listings'] as Map?)?.cast<String, dynamic>() ?? const {};
    final byRole = (users['byRole'] as Map?)?.cast<String, dynamic>() ?? const {};

    return AdminOverview(
      totalUsers: (users['total'] as num?)?.toInt() ?? 0,
      usersByRole: byRole.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
      offers: (listings['offers'] as num?)?.toInt() ?? 0,
      requests: (listings['requests'] as num?)?.toInt() ?? 0,
      reserved: (listings['reserved'] as num?)?.toInt() ?? 0,
      fulfilled: (listings['fulfilled'] as num?)?.toInt() ?? 0,
    );
  }

  final int totalUsers;
  final Map<String, int> usersByRole;
  final int offers;
  final int requests;
  final int reserved;
  final int fulfilled;
}
