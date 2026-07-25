import 'package:flutter/foundation.dart';

import '../models/donation_models.dart';
import '../models/exchange_models.dart';

/// In-memory exchange state. Completing an exchange issues two separate
/// 501(c)(3) tax receipts — one per asset/donor — which the Profile & Tax
/// Records screen listens to via [ChangeNotifier].
class ExchangeService extends ChangeNotifier {
  ExchangeService._();

  static final ExchangeService instance = ExchangeService._();

  static const currentUser = ExchangeUser(
    name: 'Cigdem Yeter',
    email: 'donor@medgift.us',
    zipCode: '94102',
    city: 'San Francisco',
    state: 'CA',
  );

  final List<ExchangeTransaction> _exchanges = [
    ExchangeTransaction(
      id: 'EXC-2026-0012',
      partyA: currentUser,
      partyB: const ExchangeUser(
        name: 'Robert Miller',
        email: 'r.miller@example.com',
        zipCode: '94607',
        city: 'Oakland',
        state: 'CA',
      ),
      assetFromA: const ExchangeAsset(
        assetId: 'AST-4471',
        title: 'Drive Medical Rollator Walker',
        category: DonationCategory.dme,
        condition: ItemCondition.good,
        fairMarketValueUsd: 189.99,
        brand: 'Drive Medical',
        model: 'Nitro Euro Style',
      ),
      assetFromB: const ExchangeAsset(
        assetId: 'AST-5290',
        title: 'Manual Transport Wheelchair',
        category: DonationCategory.dme,
        condition: ItemCondition.excellent,
        fairMarketValueUsd: 245.00,
        brand: 'Medline',
        model: 'Freedom 2',
      ),
      proposedAt: DateTime(2026, 7, 18),
    ),
    ExchangeTransaction(
      id: 'EXC-2026-0013',
      partyA: currentUser,
      partyB: const ExchangeUser(
        name: 'Maria Gonzalez',
        email: 'm.gonzalez@example.com',
        zipCode: '95112',
        city: 'San Jose',
        state: 'CA',
      ),
      assetFromA: const ExchangeAsset(
        assetId: 'AST-4818',
        title: 'Sterile Wound Dressing Kits (sealed)',
        category: DonationCategory.woundCare,
        condition: ItemCondition.excellent,
        fairMarketValueUsd: 64.50,
        brand: '3M',
        model: 'Tegaderm Kit',
        quantity: 4,
      ),
      assetFromB: const ExchangeAsset(
        assetId: 'AST-6031',
        title: 'Compression Wrap Assortment',
        category: DonationCategory.woundCare,
        condition: ItemCondition.excellent,
        fairMarketValueUsd: 58.00,
        brand: 'Medline',
        model: 'CoFlex',
        quantity: 6,
      ),
      proposedAt: DateTime(2026, 7, 20),
    ),
  ];

  final List<ExchangeTaxReceipt> _receipts = [];

  int _receiptCounter = 100;

  List<ExchangeTransaction> get exchanges => List.unmodifiable(_exchanges);

  List<ExchangeTaxReceipt> get receipts => List.unmodifiable(_receipts);

  /// Receipts where the current user is the donor (their tax deduction).
  List<ExchangeTaxReceipt> get currentUserReceipts => _receipts
      .where((r) => r.donor.email == currentUser.email)
      .toList(growable: false);

  /// Confirms the exchange and issues two separate receipts:
  /// one for each asset, naming its giver as the donor.
  List<ExchangeTaxReceipt> completeExchange(ExchangeTransaction exchange) {
    if (exchange.status == ExchangeStatus.completed) return const [];

    final now = DateTime.now();
    exchange.status = ExchangeStatus.completed;
    exchange.completedAt = now;

    final receiptForA = ExchangeTaxReceipt(
      receiptNumber: _nextReceiptNumber(now),
      exchangeId: exchange.id,
      donor: exchange.partyA,
      recipient: exchange.partyB,
      asset: exchange.assetFromA,
      issuedAt: now,
    );
    final receiptForB = ExchangeTaxReceipt(
      receiptNumber: _nextReceiptNumber(now),
      exchangeId: exchange.id,
      donor: exchange.partyB,
      recipient: exchange.partyA,
      asset: exchange.assetFromB,
      issuedAt: now,
    );

    _receipts.insertAll(0, [receiptForA, receiptForB]);
    notifyListeners();
    return [receiptForA, receiptForB];
  }

  String _nextReceiptNumber(DateTime date) {
    _receiptCounter++;
    return 'MG-EXC-${date.year}-$_receiptCounter';
  }
}
