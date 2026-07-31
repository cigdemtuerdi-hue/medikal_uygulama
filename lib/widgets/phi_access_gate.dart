import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/user_onboarding_models.dart';
import '../services/auth_session_service.dart';
import '../services/onboarding_service.dart';

/// Role-based gate for screens that may expose patient / health context.
class PhiAccessGate extends StatelessWidget {
  const PhiAccessGate({
    super.key,
    required this.child,
    this.allowedRoles = const {
      UserRole.recipient,
      UserRole.ngoPartner,
    },
  });

  final Widget child;
  final Set<UserRole> allowedRoles;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GateResult>(
      future: _resolve(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final result = snapshot.data ?? const _GateResult(allowed: false);
        if (result.allowed) return child;

        final loc = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(loc.t('hipaa.rbacTitle'))),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                loc.t('hipaa.rbacDenied'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<_GateResult> _resolve() async {
    final session = AuthSessionService.instance;
    await session.ensureLoaded();
    if (session.isIdleExpired) {
      await session.clearSession(dueToIdle: true);
      return const _GateResult(allowed: false);
    }

    var role = session.role;
    role ??= await OnboardingService().loadRole();
    if (role == null) return const _GateResult(allowed: false);
    return _GateResult(allowed: allowedRoles.contains(role));
  }
}

class _GateResult {
  const _GateResult({required this.allowed});
  final bool allowed;
}
