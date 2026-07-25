import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

/// App-wide locale state with persistence + RTL helpers.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController._() : super(const Locale('en'));

  static final LocaleController instance = LocaleController._();

  static const _prefsKey = 'app_locale';

  bool get isRtl => AppLocalizations.isRtlLanguageCode(value.languageCode);

  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null &&
        code.isNotEmpty &&
        AppLocalizations.supportedLocales
            .any((l) => l.languageCode == code)) {
      value = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == value) return;
    // Reload JSON tables so updated lang files are picked up.
    clearLocalizationCache();
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
