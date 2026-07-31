import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/compliance_api_service.dart';

/// Opens a short summary dialog; full legal text lives on [/hipaa-privacy-notice].
Future<void> showHipaaNoticeDialog(BuildContext context) {
  final loc = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Row(
          children: [
            const Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryDeepBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.t('hipaa.modalTitle'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDeepBlue,
                    ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('hipaa.modalIntro'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.t('hipaa.modalSummary'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(AppRoutes.hipaaPrivacyNotice);
            },
            child: Text(loc.t('hipaa.readFullNotice')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.t('waiver.close')),
          ),
        ],
      );
    },
  );
}

/// Explicit HIPAA consent checkbox — unchecked by default.
class HipaaConsentCheckbox extends StatelessWidget {
  const HipaaConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      loc.t('hipaa.checkboxBefore'),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                    InkWell(
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.hipaaPrivacyNotice),
                      child: Text(
                        loc.t('hipaa.checkboxNoticeLink'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    Text(
                      loc.t('hipaa.checkboxAnd'),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                    InkWell(
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.privacyPolicy),
                      child: Text(
                        loc.t('hipaa.checkboxPrivacyLink'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    Text(
                      loc.t('hipaa.checkboxAfter'),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

/// Full Notice of Privacy Practices page (`/hipaa-privacy-notice`).
class HipaaPrivacyNoticeScreen extends StatelessWidget {
  const HipaaPrivacyNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('hipaa.pageTitle')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('hipaa.pageTitle'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDeepBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.t('hipaa.versionLabel', {
                    'version': ComplianceApiService.hipaaNoticeVersion,
                  }),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  loc.t('hipaa.pageIntro'),
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 24),
                _section(theme, loc.t('hipaa.sectionUsesTitle'), loc.t('hipaa.sectionUsesBody')),
                _section(theme, loc.t('hipaa.sectionRightsTitle'), loc.t('hipaa.sectionRightsBody')),
                _section(theme, loc.t('hipaa.sectionSecurityTitle'), loc.t('hipaa.sectionSecurityBody')),
                _section(theme, loc.t('hipaa.sectionContactTitle'), loc.t('hipaa.sectionContactBody')),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.privacyPolicy),
                  icon: const Icon(Icons.policy_outlined),
                  label: Text(loc.t('hipaa.viewPrivacyPolicy')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(ThemeData theme, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryDeepBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

/// Lightweight Privacy Policy page linked from the HIPAA consent checkbox.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('privacy.pageTitle'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('privacy.pageTitle'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDeepBlue,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.t('privacy.pageBody'),
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.hipaaPrivacyNotice),
                  child: Text(loc.t('hipaa.readFullNotice')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
