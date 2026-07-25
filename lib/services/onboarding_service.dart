import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_onboarding_models.dart';

class OnboardingService {
  static const _completeKey = 'onboarding_complete';
  static const _profilePrefix = 'onboarding_profile_';

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completeKey) ?? false;
  }

  Future<UserOnboardingProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('${_profilePrefix}role');
    if (role == null) return null;

    final map = <String, String>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_profilePrefix)) {
        final field = key.substring(_profilePrefix.length);
        final value = prefs.getString(key);
        if (value != null) {
          map[field] = value;
        }
      }
    }

    if (!map.containsKey('role')) return null;
    return UserOnboardingProfile.fromStorageMap(map);
  }

  Future<void> saveProfile(UserOnboardingProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in profile.toStorageMap().entries) {
      await prefs.setString('$_profilePrefix${entry.key}', entry.value);
    }
    await prefs.setBool(_completeKey, true);
  }

  Future<UserRole?> loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleName = prefs.getString('${_profilePrefix}role');
    if (roleName == null) return null;
    return UserRole.values.byName(roleName);
  }
}
