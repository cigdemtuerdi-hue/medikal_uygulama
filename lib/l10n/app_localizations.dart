import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// JSON-file backed localizations (assets/lang/<code>.json).
class AppLocalizations {
  const AppLocalizations(this.locale, this._strings);

  final Locale locale;
  final Map<String, String> _strings;

  static const supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('tr'),
    Locale('zh'),
    Locale('ru'),
    Locale('ar'),
    Locale('ug'),
  ];

  /// Locales that use right-to-left text direction.
  static const rtlLanguageCodes = {'ar', 'ug'};

  static bool isRtlLanguageCode(String code) => rtlLanguageCodes.contains(code);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Translates [key]; falls back to the key itself if missing.
  /// Optional [args] replace `{name}` placeholders in the string.
  String t(String key, [Map<String, Object>? args]) {
    var value = _strings[key] ?? key;
    if (args != null) {
      args.forEach((name, arg) {
        value = value.replaceAll('{$name}', '$arg');
      });
    }
    return value;
  }
}

/// Clears cached language tables (useful after asset hot-reload in tests).
void clearLocalizationCache() {
  _AppLocalizationsDelegate._cache.clear();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  // Parsed string tables, keyed by language code. Once a language has been
  // loaded we can return a SynchronousFuture, which lets Localizations build
  // in the same frame (and keeps widget tests deterministic).
  static final Map<String, Map<String, String>> _cache = {};

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    final code = isSupported(locale) ? locale.languageCode : 'en';
    final cached = _cache[code];
    if (cached != null) {
      return SynchronousFuture(AppLocalizations(Locale(code), cached));
    }
    return _loadFromAsset(code);
  }

  Future<AppLocalizations> _loadFromAsset(String code) async {
    final raw = await rootBundle.loadString('assets/lang/$code.json');
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final strings =
        decoded.map((key, value) => MapEntry(key, value.toString()));
    _cache[code] = strings;
    return AppLocalizations(Locale(code), strings);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
