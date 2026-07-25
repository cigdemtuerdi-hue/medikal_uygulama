import 'package:flutter/foundation.dart';

import '../models/available_donation_item.dart';
import '../models/donation_models.dart';
import '../models/urgent_need_models.dart';
import '../models/wishlist_models.dart';
import 'profile_address_service.dart';
import 'urgent_need_service.dart';

/// Wishlist + Instant Match: when a new listing arrives, matching recipients
/// get an in-app alert and a simulated email notification.
class WishlistService extends ChangeNotifier {
  WishlistService._() {
    _seedFromRecipientProfile();
  }

  static final WishlistService instance = WishlistService._();

  final List<WishlistEntry> _entries = [];
  final List<InstantMatchAlert> _alerts = [];
  final Set<String> _matchedPairs = {};
  bool _alertsEnabled = true;

  List<WishlistEntry> get entries {
    _expireUrgentEntries(notify: false);
    return List.unmodifiable(
      UrgentNeedService.instance.sortedWishlistEntries(_entries),
    );
  }

  /// Actively urgent wishlist requests only (for Urgent Wishlist tab).
  List<WishlistEntry> get urgentEntries {
    _expireUrgentEntries(notify: false);
    return List.unmodifiable(
      UrgentNeedService.instance.sortedWishlistEntries(
        _entries.where((e) => e.isActivelyUrgent()),
      ),
    );
  }

  List<InstantMatchAlert> get alerts => List.unmodifiable(_alerts);
  List<InstantMatchAlert> get unreadAlerts =>
      _alerts.where((a) => !a.read).toList();
  bool get alertsEnabled => _alertsEnabled;
  int get unreadCount => unreadAlerts.length;

  void _seedFromRecipientProfile() {
    final recipient = ProfileAddressService.matchedRecipient;
    var i = 0;
    for (final need in recipient.itemsNeeded) {
      i++;
      final lower = need.label.toLowerCase();
      DmeType? dmeType;
      var category = DonationCategory.dme;
      if (lower.contains('wheelchair')) {
        dmeType = DmeType.wheelchair;
      } else if (lower.contains('walker') || lower.contains('rollator')) {
        dmeType = DmeType.walker;
      } else if (lower.contains('oxygen')) {
        dmeType = DmeType.oxygenEquipment;
      } else if (lower.contains('wound') ||
          lower.contains('dressing') ||
          lower.contains('gauze')) {
        category = DonationCategory.woundCare;
      }

      final isDemoUrgent = i == 1;
      final flaggedAt = DateTime.now();
      _entries.add(
        WishlistEntry(
          id: 'wish-seed-$i',
          label: need.label,
          quantity: need.quantity,
          createdAt: flaggedAt,
          category: category,
          dmeType: dmeType,
          queryText: need.label,
          isUrgentNeed: isDemoUrgent,
          urgentExpiresAt: isDemoUrgent
              ? UrgentNeedRules.expiresAtFrom(flaggedAt)
              : null,
          verificationStatus: isDemoUrgent
              ? UrgentVerificationStatus.verified
              : UrgentVerificationStatus.none,
          verificationDocLabel: isDemoUrgent ? 'discharge-note-demo.pdf' : null,
          verificationDocPath: isDemoUrgent ? 'demo/discharge-note.pdf' : null,
          requiredFeaturesDescription: isDemoUrgent
              ? 'Must be a foldable transport wheelchair, seat width 16–18 in, '
                  'weight capacity ≥ 250 lb, working brakes, intact footrests, '
                  'and clean/sanitized for home use. Manual push preferred; '
                  'electric power chairs are not needed for this request.'
              : null,
        ),
      );
    }
  }

  void setAlertsEnabled(bool enabled) {
    if (_alertsEnabled == enabled) return;
    _alertsEnabled = enabled;
    notifyListeners();
  }

  /// Converts expired urgent wishlist entries back to standard requests.
  void applyUrgentExpirations({DateTime? now}) {
    _expireUrgentEntries(now: now, notify: true);
  }

  bool _expireUrgentEntries({DateTime? now, required bool notify}) {
    final clock = now ?? DateTime.now();
    var changed = false;
    for (var i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      if (!entry.isUrgentNeed) continue;
      if (entry.urgentExpiresAt == null) continue;
      if (!clock.isAfter(entry.urgentExpiresAt!)) continue;
      _entries[i] = entry.copyWith(
        isUrgentNeed: false,
        verificationStatus: UrgentVerificationStatus.expired,
      );
      changed = true;
    }
    if (changed && notify) notifyListeners();
    return changed;
  }

  /// `added`, `duplicate`, `empty` (blank label), or `missingFeatures` (urgent).
  WishlistAddResult addEntry({
    required String label,
    int quantity = 1,
    DonationCategory category = DonationCategory.dme,
    DmeType? dmeType,
    String? queryText,
    bool isUrgentNeed = false,
    String? verificationDocPath,
    String? verificationDocLabel,
    String? requiredFeaturesDescription,
  }) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return WishlistAddResult.empty;

    final features = requiredFeaturesDescription?.trim() ?? '';
    if (isUrgentNeed && features.isEmpty) {
      return WishlistAddResult.missingFeatures;
    }

    final duplicate = _entries.any(
      (e) =>
          e.label.toLowerCase() == trimmed.toLowerCase() &&
          e.dmeType == dmeType &&
          e.category == category,
    );
    if (duplicate) return WishlistAddResult.duplicate;

    final now = DateTime.now();
    final hasProof = verificationDocPath != null &&
        verificationDocPath.trim().isNotEmpty;
    final status = !isUrgentNeed
        ? UrgentVerificationStatus.none
        : (hasProof
            ? UrgentVerificationStatus.verified
            : UrgentVerificationStatus.pending);

    _entries.insert(
      0,
      WishlistEntry(
        id: 'wish-${now.millisecondsSinceEpoch}',
        label: trimmed,
        quantity: quantity < 1 ? 1 : quantity,
        createdAt: now,
        category: category,
        dmeType: dmeType,
        queryText: (queryText ?? trimmed).trim(),
        isUrgentNeed: isUrgentNeed,
        urgentExpiresAt:
            isUrgentNeed ? UrgentNeedRules.expiresAtFrom(now) : null,
        verificationDocPath: verificationDocPath,
        verificationDocLabel: verificationDocLabel,
        verificationStatus: status,
        requiredFeaturesDescription: features.isEmpty ? null : features,
      ),
    );
    notifyListeners();
    return WishlistAddResult.added;
  }

  /// Builds a wishlist entry from the current browse search / filters.
  WishlistAddResult addFromSearch({
    required String query,
    DmeType? categoryFilter,
    bool isUrgentNeed = false,
    String? verificationDocPath,
    String? verificationDocLabel,
    String? requiredFeaturesDescription,
  }) {
    final q = query.trim();
    final label = categoryFilter != null
        ? _dmeTypeEnglishLabel(categoryFilter)
        : (q.isNotEmpty ? q : 'Requested item');

    return addEntry(
      label: label,
      dmeType: categoryFilter,
      category: DonationCategory.dme,
      queryText: q.isNotEmpty ? q : label,
      isUrgentNeed: isUrgentNeed,
      verificationDocPath: verificationDocPath,
      verificationDocLabel: verificationDocLabel,
      requiredFeaturesDescription: requiredFeaturesDescription,
    );
  }

  void removeEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Called when a donor publishes a new listing — Instant Match pipeline.
  List<InstantMatchAlert> evaluateNewListing(AvailableDonationItem item) {
    if (!_alertsEnabled || _entries.isEmpty) return const [];

    applyUrgentExpirations();
    final recipient = ProfileAddressService.matchedRecipient;
    final created = <InstantMatchAlert>[];

    final ordered = [..._entries];
    if (item.priorityToUrgentRequests) {
      ordered.sort((a, b) {
        final rankA = UrgentNeedRules.priorityRank(
          isActivelyUrgent: a.isActivelyUrgent(),
          status: a.effectiveVerificationStatus(),
        );
        final rankB = UrgentNeedRules.priorityRank(
          isActivelyUrgent: b.isActivelyUrgent(),
          status: b.effectiveVerificationStatus(),
        );
        return rankA.compareTo(rankB);
      });
    }

    for (final entry in ordered) {
      final pairKey = '${entry.id}|${item.id}';
      if (_matchedPairs.contains(pairKey)) continue;
      if (!_matches(entry, item)) continue;

      // Priority-to-urgent listings skip non-urgent wishlist hits when any
      // active urgent match exists for this item type/keywords.
      if (item.priorityToUrgentRequests &&
          !entry.isActivelyUrgent() &&
          ordered.any((e) => e.isActivelyUrgent() && _matches(e, item))) {
        continue;
      }

      _matchedPairs.add(pairKey);
      final alert = InstantMatchAlert(
        id: 'match-${DateTime.now().millisecondsSinceEpoch}-${entry.id}',
        wishlistEntryId: entry.id,
        itemId: item.id,
        itemTitle: item.title,
        wishlistLabel: entry.label,
        recipientName: recipient.name,
        recipientEmail: recipient.email,
        createdAt: DateTime.now(),
        priorityMatch:
            item.priorityToUrgentRequests && entry.isActivelyUrgent(),
      );
      _alerts.insert(0, alert);
      created.add(alert);
      _simulateEmail(alert);
    }

    if (created.isNotEmpty) notifyListeners();
    return created;
  }

  bool _matches(WishlistEntry entry, AvailableDonationItem item) {
    if (entry.dmeType != null) {
      if (item.dmeType == entry.dmeType) return true;
    }

    final needles = <String>[
      entry.label.toLowerCase(),
      if (entry.queryText != null && entry.queryText!.trim().isNotEmpty)
        entry.queryText!.trim().toLowerCase(),
    ];

    final haystack = [
      item.title,
      item.description,
      item.brand ?? '',
      item.model ?? '',
      if (item.dmeType != null) item.dmeType!.name,
    ].join(' ').toLowerCase();

    for (final needle in needles) {
      if (needle.length < 3) continue;
      final tokens = needle
          .split(RegExp(r'\s+'))
          .where((t) => t.length >= 3)
          .toList();
      if (tokens.isEmpty) continue;
      final hitCount = tokens.where(haystack.contains).length;
      if (hitCount >= (tokens.length == 1 ? 1 : (tokens.length / 2).ceil())) {
        return true;
      }
    }

    if (entry.category == DonationCategory.woundCare) {
      const woundTokens = [
        'wound',
        'dressing',
        'gauze',
        'bandage',
        'compression',
      ];
      if (woundTokens.any(haystack.contains)) return true;
    }

    return false;
  }

  void markAlertRead(String id) {
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index < 0) return;
    _alerts[index] = _alerts[index].copyWith(read: true);
    notifyListeners();
  }

  void markAllAlertsRead() {
    var changed = false;
    for (var i = 0; i < _alerts.length; i++) {
      if (!_alerts[i].read) {
        _alerts[i] = _alerts[i].copyWith(read: true);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void dismissAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void _simulateEmail(InstantMatchAlert alert) {
    debugPrint(
      'INSTANT MATCH EMAIL (demo)\n'
      'To: ${alert.recipientEmail} (${alert.recipientName})\n'
      'Subject: MedGift Instant Match — ${alert.itemTitle}\n'
      'Body: A new listing matches your wishlist item '
      '"${alert.wishlistLabel}": ${alert.itemTitle} (id ${alert.itemId}).\n'
      '${alert.priorityMatch ? "Priority Match: urgent need preferred.\n" : ""}'
      'Open the Recipient browse tab to reserve it.',
    );
  }

  static String _dmeTypeEnglishLabel(DmeType type) {
    return switch (type) {
      DmeType.wheelchair => 'Wheelchair',
      DmeType.walker => 'Walker / Rollator',
      DmeType.hospitalBed => 'Hospital Bed',
      DmeType.oxygenEquipment => 'Oxygen Equipment',
      DmeType.nebulizer => 'Nebulizer',
      DmeType.commode => 'Commode',
      DmeType.showerChair => 'Shower Chair',
      DmeType.other => 'Other DME',
    };
  }
}
