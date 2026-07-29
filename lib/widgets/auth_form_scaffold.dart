import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../widgets/a11y.dart';
import '../widgets/async_state_widgets.dart';
import '../widgets/language_menu_button.dart';
import '../widgets/medgift_logo.dart';

/// Shared chrome for auth forms (forgot / reset password).
///
/// Keeps branding, max-width, and scroll behavior consistent with
/// [AuthLandingScreen] while remaining keyboard-friendly on small screens.
class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: showBack && canPop
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        actions: const [LanguageMenuButton()],
      ),
      body: SafeArea(
        child: A11y.main(
          label: title,
          child: Center(
            child: ContentConstrained(
              maxWidth: AppBreakpoints.authMax,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: MedGiftBrand(showLabel: true, logoSize: 64),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDeepBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Accessible status banner for form success / error feedback.
class AuthStatusBanner extends StatelessWidget {
  const AuthStatusBanner({
    super.key,
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isError
        ? theme.colorScheme.errorContainer
        : AppTheme.skyBlue.withValues(alpha: 0.45);
    final fg = isError
        ? theme.colorScheme.onErrorContainer
        : AppTheme.primaryDeepBlue;

    return Semantics(
      liveRegion: true,
      container: true,
      label: message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          border: Border.all(
            color: isError
                ? theme.colorScheme.error.withValues(alpha: 0.35)
                : AppTheme.primaryBlue.withValues(alpha: 0.25),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: fg,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
