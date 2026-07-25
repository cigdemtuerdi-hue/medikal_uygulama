import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_onboarding_models.dart';
import '../../widgets/language_menu_button.dart';
import '../../widgets/medgift_logo.dart';
import '../../widgets/partnership_footer.dart';
import 'profile_creation_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _selectRole(BuildContext context, UserRole role) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileCreationScreen(role: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: const [LanguageMenuButton()],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                children: [
                  const Center(
                    child: MedGiftBrand(
                      showLabel: true,
                      logoSize: 72,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    loc.t('onboarding.welcomeTitle'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDeepBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.t('onboarding.selectRole'),
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _RoleOptionCard(
                    title: loc.t('onboarding.donorTitle'),
                    subtitle: loc.t('onboarding.role.donor.desc'),
                    icon: Icons.volunteer_activism_outlined,
                    color: AppTheme.primaryBlue,
                    onTap: () => _selectRole(context, UserRole.donor),
                  ),
                  const SizedBox(height: 16),
                  _RoleOptionCard(
                    title: loc.t('onboarding.recipientTitle'),
                    subtitle: loc.t('onboarding.role.recipient.desc'),
                    icon: Icons.favorite_outline,
                    color: AppTheme.accentTeal,
                    onTap: () => _selectRole(context, UserRole.recipient),
                  ),
                  const SizedBox(height: 16),
                  _RoleOptionCard(
                    title: loc.t('onboarding.ngoTitle'),
                    subtitle: loc.t('onboarding.role.ngo.desc'),
                    icon: Icons.account_balance_outlined,
                    color: const Color(0xFF1565C0),
                    onTap: () => _selectRole(context, UserRole.ngoPartner),
                  ),
                  const PartnershipFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  const _RoleOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withValues(alpha: 0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
