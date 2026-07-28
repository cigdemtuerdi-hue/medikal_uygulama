import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../models/user_onboarding_models.dart';
import '../services/auth_session_service.dart';
import '../services/ngo_partner_service.dart';
import '../services/onboarding_service.dart';
import '../widgets/ai_support_chat_widget.dart';
import 'app_shell.dart';
import 'auth_landing_screen.dart';

/// Boot router: signed-in members go straight into the app (no login loop).
class AppEntryScreen extends StatefulWidget {
  const AppEntryScreen({super.key});

  @override
  State<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends State<AppEntryScreen> {
  final _onboardingService = OnboardingService();
  final _session = AuthSessionService.instance;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EntryDestination>(
      future: _resolveDestination(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return switch (snapshot.data ?? _EntryDestination.authLanding) {
          _EntryDestination.authLanding =>
            const AiSupportHost(child: AuthLandingScreen()),
          _EntryDestination.donorApp => const AiSupportHost(
              child: AppShell(initialTab: AppTab.home),
            ),
          _EntryDestination.recipientApp => const AiSupportHost(
              child: AppShell(initialTab: AppTab.recipient),
            ),
          _EntryDestination.ngoApp => const AiSupportHost(
              child: AppShell(initialTab: AppTab.ngoPortal),
            ),
        };
      },
    );
  }

  Future<_EntryDestination> _resolveDestination() async {
    await _session.ensureLoaded();
    final isComplete = await _onboardingService.isOnboardingComplete();
    final profile = isComplete ? await _onboardingService.loadProfile() : null;
    final role = profile?.role ?? await _onboardingService.loadRole();

    final canAutoEnter = _session.isLoggedIn ||
        (isComplete && profile != null && !_session.explicitlyLoggedOut);

    if (!canAutoEnter) {
      return _EntryDestination.authLanding;
    }

    if (profile != null && !_session.isLoggedIn) {
      await _session.startSession(email: profile.email, role: profile.role);
    }

    final effectiveRole = profile?.role ?? role ?? _session.role;
    if (effectiveRole == null) {
      return _EntryDestination.authLanding;
    }

    if (effectiveRole == UserRole.ngoPartner && profile != null) {
      NgoPartnerService.instance.activateSessionFromProfile(profile);
    }

    return _destinationForRole(effectiveRole);
  }

  _EntryDestination _destinationForRole(UserRole role) {
    return switch (role) {
      UserRole.donor => _EntryDestination.donorApp,
      UserRole.recipient => _EntryDestination.recipientApp,
      UserRole.ngoPartner => _EntryDestination.ngoApp,
    };
  }
}

enum _EntryDestination {
  authLanding,
  donorApp,
  recipientApp,
  ngoApp,
}
