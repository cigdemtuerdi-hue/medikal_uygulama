import 'donation_models.dart';

/// One side of an exchange (acts as donor for the item they give away).
class ExchangeUser {
  const ExchangeUser({
    required this.name,
    required this.email,
    required this.zipCode,
    required this.city,
    required this.state,
  });

  final String name;
  final String email;
  final String zipCode;
  final String city;
  final String state;

  String get location => '$city, $state $zipCode';
}

/// A tracked item (asset) offered in an exchange.
class ExchangeAsset {
  const ExchangeAsset({
    required this.assetId,
    required this.title,
    required this.category,
    required this.condition,
    required this.fairMarketValueUsd,
    this.brand,
    this.model,
    this.quantity = 1,
  });

  final String assetId;
  final String title;
  final DonationCategory category;
  final ItemCondition condition;
  final double fairMarketValueUsd;
  final String? brand;
  final String? model;
  final int quantity;
}

enum ExchangeStatus { proposed, completed }

/// Two-party exchange: partyA gives [assetFromA] to partyB, and
/// partyB gives [assetFromB] to partyA.
class ExchangeTransaction {
  ExchangeTransaction({
    required this.id,
    required this.partyA,
    required this.partyB,
    required this.assetFromA,
    required this.assetFromB,
    required this.proposedAt,
    this.status = ExchangeStatus.proposed,
    this.completedAt,
  });

  final String id;
  final ExchangeUser partyA;
  final ExchangeUser partyB;
  final ExchangeAsset assetFromA;
  final ExchangeAsset assetFromB;
  final DateTime proposedAt;

  ExchangeStatus status;
  DateTime? completedAt;
}

/// 501(c)(3) tax receipt issued for one asset of a completed exchange.
class ExchangeTaxReceipt {
  const ExchangeTaxReceipt({
    required this.receiptNumber,
    required this.exchangeId,
    required this.donor,
    required this.recipient,
    required this.asset,
    required this.issuedAt,
  });

  final String receiptNumber;
  final String exchangeId;
  final ExchangeUser donor;
  final ExchangeUser recipient;
  final ExchangeAsset asset;
  final DateTime issuedAt;

  String get pdfFileName => '$receiptNumber.pdf';
}
