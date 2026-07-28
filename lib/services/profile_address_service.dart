import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_address.dart';
import '../models/recipient_models.dart';
import '../models/us_address_models.dart';
import '../models/user_onboarding_models.dart';
import '../services/donation_service.dart';
import '../services/onboarding_service.dart';

class ProfileAddressService {
  ProfileAddressService._();

  static final ProfileAddressService instance = ProfileAddressService._();

  static const _savedPrefix = 'saved_profile_address_';

  static const RecipientProfile matchedRecipient = RecipientProfile(
    id: 'rec-001',
    name: 'Maria S.',
    initials: 'MS',
    city: 'Eastvale',
    state: 'CA',
    zipCode: '92880',
    phone: '(951) 555-0142',
    email: 'maria.recipient@email.com',
    itemsNeeded: [
      NeededItem(label: 'Transport Wheelchair', quantity: 1),
      NeededItem(label: 'Wound Dressing Kits', quantity: 2),
    ],
  );

  Future<ProfileAddress> loadCurrentAddress() async {
    final role = await OnboardingService().loadRole();
    if (role == UserRole.recipient) {
      return loadRecipientAddress();
    }
    return loadDonorAddress();
  }

  Future<ProfileAddress> loadDonorAddress() async {
    final saved = await _loadSavedAddress('donor');
    if (saved != null) return saved;

    final onboarding = await OnboardingService().loadProfile();
    if (onboarding != null &&
        (onboarding.role == UserRole.donor ||
            onboarding.role == UserRole.ngoPartner)) {
      return ProfileAddress(
        roleLabel: onboarding.role == UserRole.ngoPartner
            ? 'Verified NGO Partner'
            : 'Donor',
        zipCode: onboarding.zipCode,
        city: onboarding.city,
        state: onboarding.state,
        name: onboarding.fullName,
      );
    }

    final donor = DonationService.donorProfile;
    return ProfileAddress(
      roleLabel: 'Donor',
      zipCode: donor.zipCode,
      name: donor.name,
    );
  }

  Future<ProfileAddress> loadRecipientAddress() async {
    final saved = await _loadSavedAddress('recipient');
    if (saved != null) return saved;

    final onboarding = await OnboardingService().loadProfile();
    if (onboarding != null && onboarding.role == UserRole.recipient) {
      return ProfileAddress(
        roleLabel: 'Recipient',
        zipCode: onboarding.zipCode,
        city: onboarding.city,
        state: onboarding.state,
        name: onboarding.fullName,
      );
    }

    final recipient = matchedRecipient;
    return ProfileAddress(
      roleLabel: 'Recipient',
      zipCode: recipient.zipCode,
      city: recipient.city,
      state: recipient.state,
      name: recipient.name,
    );
  }

  Future<void> saveAddress(ProfileAddress address) async {
    final roleKey = address.roleLabel.toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    for (final entry in address.toStorageMap().entries) {
      await prefs.setString('$_savedPrefix${roleKey}_${entry.key}', entry.value);
    }

    final onboarding = await OnboardingService().loadProfile();
    if (onboarding != null) {
      await OnboardingService().saveProfile(
        onboarding.copyWith(
          zipCode: address.zipCode,
          city: address.city ?? onboarding.city,
          state: address.state ?? onboarding.state,
        ),
      );
    }
  }

  ProfileAddress fromSuggestion(
    UsAddressSuggestion suggestion, {
    required String roleLabel,
    String? name,
  }) {
    return ProfileAddress(
      roleLabel: roleLabel,
      zipCode: suggestion.zipCode,
      city: suggestion.city.isNotEmpty ? suggestion.city : null,
      state: suggestion.state.isNotEmpty ? suggestion.state : null,
      streetAddress: suggestion.streetAddress,
      fullAddressLine: suggestion.primaryLine,
      name: name,
    );
  }

  Future<ProfileAddress?> _loadSavedAddress(String roleKey) async {
    final prefs = await SharedPreferences.getInstance();
    final zip = prefs.getString('$_savedPrefix${roleKey}_zipCode');
    if (zip == null || zip.isEmpty) return null;

    final map = <String, String>{'zipCode': zip};
    final keyPrefix = '$_savedPrefix${roleKey}_';
    for (final key in prefs.getKeys()) {
      if (key.startsWith(keyPrefix)) {
        final field = key.substring(keyPrefix.length);
        if (field == 'zipCode') continue;
        final value = prefs.getString(key);
        if (value != null) map[field] = value;
      }
    }

    return ProfileAddress.fromStorageMap(
      map,
      roleLabel: roleKey == 'recipient' ? 'Recipient' : 'Donor',
    );
  }
}
