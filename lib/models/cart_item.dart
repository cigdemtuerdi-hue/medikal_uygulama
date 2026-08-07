import 'listing.dart';

/// A sale listing snapshot saved in the local shopping cart.
class CartItem {
  const CartItem({
    required this.listingId,
    required this.title,
    required this.priceCents,
    this.currency = 'USD',
    this.photoPath,
    this.ownerUserId,
    this.city,
    this.state,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  factory CartItem.fromListing(Listing listing) {
    final photos = listing.displayPhotos;
    return CartItem(
      listingId: listing.id,
      title: listing.title,
      priceCents: listing.priceCents ?? 0,
      currency: listing.currency ?? 'USD',
      photoPath: photos.isEmpty ? listing.photoUrl : photos.first,
      ownerUserId: listing.ownerUserId,
      city: listing.city,
      state: listing.state,
      addedAt: DateTime.now(),
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      listingId: json['listingId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      priceCents: (json['priceCents'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      photoPath: json['photoPath']?.toString(),
      ownerUserId: json['ownerUserId']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      addedAt: DateTime.tryParse(json['addedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String listingId;
  final String title;
  final int priceCents;
  final String currency;
  final String? photoPath;
  final String? ownerUserId;
  final String? city;
  final String? state;
  final DateTime addedAt;

  String get priceLabel => formatUsdCents(priceCents);

  String get locationLabel {
    final parts = <String>[
      if (city != null && city!.isNotEmpty) city!,
      if (state != null && state!.isNotEmpty) state!,
    ];
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'listingId': listingId,
        'title': title,
        'priceCents': priceCents,
        'currency': currency,
        'photoPath': photoPath,
        'ownerUserId': ownerUserId,
        'city': city,
        'state': state,
        'addedAt': addedAt.toIso8601String(),
      };
}
