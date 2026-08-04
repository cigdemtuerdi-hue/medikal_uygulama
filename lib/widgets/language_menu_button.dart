import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';

class _LangOption {
  const _LangOption({
    required this.locale,
    required this.flag,
    required this.nativeName,
    required this.code,
  });

  final Locale locale;
  final String flag;
  final String nativeName;
  final String code;
}

/// Language picker — visible chip in app bars and on landing screens.
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({
    super.key,
    this.compact = false,
  });

  /// When true, shows icon-only (for dense app bars).
  final bool compact;

  static const _options = <_LangOption>[
    _LangOption(
      locale: Locale('en'),
      flag: '🇺🇸',
      nativeName: 'English (EN)',
      code: 'EN',
    ),
    _LangOption(
      locale: Locale('es'),
      flag: '🇪🇸',
      nativeName: 'Español (ES)',
      code: 'ES',
    ),
    _LangOption(
      locale: Locale('tr'),
      flag: '🇹🇷',
      nativeName: 'Türkçe (TR)',
      code: 'TR',
    ),
    _LangOption(
      locale: Locale('zh'),
      flag: '🇨🇳',
      nativeName: '中文 (ZH)',
      code: 'ZH',
    ),
    _LangOption(
      locale: Locale('ru'),
      flag: '🇷🇺',
      nativeName: 'Русский (RU)',
      code: 'RU',
    ),
    _LangOption(
      locale: Locale('ar'),
      flag: '🇸🇦',
      nativeName: 'العربية (AR)',
      code: 'AR',
    ),
    _LangOption(
      locale: Locale('ug'),
      flag: '🏳️',
      nativeName: 'ئۇيغۇرچە (UG)',
      code: 'UG',
    ),
    _LangOption(
      locale: Locale('fr'),
      flag: '🇫🇷',
      nativeName: 'Français (FR)',
      code: 'FR',
    ),
    _LangOption(
      locale: Locale('de'),
      flag: '🇩🇪',
      nativeName: 'Deutsch (DE)',
      code: 'DE',
    ),
  ];

  _LangOption get _current {
    final code = LocaleController.instance.value.languageCode;
    return _options.firstWhere(
      (o) => o.locale.languageCode == code,
      orElse: () => _options.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final current = _current;

    return PopupMenuButton<Locale>(
      tooltip: loc.t('language.label'),
      initialValue: current.locale,
      onSelected: LocaleController.instance.setLocale,
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        for (final option in _options)
          PopupMenuItem(
            value: option.locale,
            child: Row(
              children: [
                if (current.locale.languageCode == option.locale.languageCode)
                  const Icon(Icons.check, size: 18)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(option.flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    option.nativeName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: compact
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.language,
                color: AppTheme.primaryDeepBlue,
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Material(
                color: AppTheme.skyBlue.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.language,
                        size: 20,
                        color: AppTheme.primaryDeepBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        current.flag,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        current.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDeepBlue,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.primaryDeepBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
