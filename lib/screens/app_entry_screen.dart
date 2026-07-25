import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../models/user_onboarding_models.dart';
import '../services/onboarding_service.dart';
import '../widgets/ai_support_chat_widget.dart';
import 'app_shell.dart';
import 'onboarding/role_selection_screen.dart';

class AppEntryScreen extends StatefulWidget {
  const AppEntryScreen({super.key});

  @override
  State<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends State<AppEntryScreen> {
  final _onboardingService = OnboardingService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppEntryDestination>(
      future: _resolveDestination(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return switch (snapshot.data!) {
          AppEntryDestination.onboarding =>
            const AiSupportHost(child: RoleSelectionScreen()),
          AppEntryDestination.donorApp => const AiSupportHost(
              child: AppShell(initialTab: AppTab.home),
            ),
          AppEntryDestination.recipientApp => const AiSupportHost(
              child: AppShell(initialTab: AppTab.recipient),
            ),
          AppEntryDestination.ngoApp => const AiSupportHost(
              child: AppShell(initialTab: AppTab.ngoPortal),
            ),
        };
      },
    );
  }

  Future<AppEntryDestination> _resolveDestination() async {
    final isComplete = await _onboardingService.isOnboardingComplete();
    if (!isComplete) return AppEntryDestination.onboarding;

    final role = await _onboardingService.loadRole();
    return switch (role) {
      UserRole.recipient => AppEntryDestination.recipientApp,
      UserRole.donor => AppEntryDestination.donorApp,
      UserRole.ngoPartner => AppEntryDestination.ngoApp,
      null => AppEntryDestination.onboarding,
    };
  }
}

enum AppEntryDestination {
  onboarding,
  donorApp,
  recipientApp,
  ngoApp,
}
