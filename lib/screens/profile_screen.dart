import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/ai_vision_service.dart';
import '../services/donation_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/donation_history_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final donor = DonationService.donorProfile;
    final totalDeductions = DonationService.totalTaxDeductionsUsd;
    final donationCount = DonationService.totalDonationCount;
    final isWide = MediaQuery.sizeOf(context).width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Tax Records'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryDeepBlue,
                          AppTheme.primaryBlue,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, size: 36, color: Colors.white),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                donor.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                donor.email,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Member since ${donor.memberSince} · ZIP ${donor.zipCode}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white60,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          child: const Text('Edit Profile'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: isWide
                        ? Row(
                            children: [
                              Expanded(
                                child: _ProfileStatTile(
                                  icon: Icons.volunteer_activism_outlined,
                                  label: 'Total Donations',
                                  value: '$donationCount',
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ProfileStatTile(
                                  icon: Icons.savings_outlined,
                                  label: 'Total Tax Deductions',
                                  value: formatUsd(totalDeductions),
                                  color: AppTheme.accentTeal,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ProfileStatTile(
                                  icon: Icons.receipt_long_outlined,
                                  label: '501(c)(3) Receipts',
                                  value: '$donationCount',
                                  color: const Color(0xFF6A1B9A),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _ProfileStatTile(
                                icon: Icons.volunteer_activism_outlined,
                                label: 'Total Donations',
                                value: '$donationCount',
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(height: 12),
                              _ProfileStatTile(
                                icon: Icons.savings_outlined,
                                label: 'Total Tax Deductions',
                                value: formatUsd(totalDeductions),
                                color: AppTheme.accentTeal,
                              ),
                              const SizedBox(height: 12),
                              _ProfileStatTile(
                                icon: Icons.receipt_long_outlined,
                                label: '501(c)(3) Receipts',
                                value: '$donationCount',
                                color: const Color(0xFF6A1B9A),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const ComplianceBanner(),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Donation History',
              subtitle:
                  'IRS-compliant records for $donationCount charitable donations to qualifying 501(c)(3) organizations',
              action: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Export All'),
              ),
            ),
            const SizedBox(height: 16),
            ...DonationService.donationHistory.map(
              (record) => DonationHistoryCard(record: record),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Donation Match Alerts'),
                    subtitle: Text(
                      'Notify me when clinics near ZIP ${donor.zipCode} need items',
                    ),
                    trailing: Switch(value: true, onChanged: (_) {}),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('HIPAA & Privacy'),
                    subtitle: const Text('We never store patient health information (PHI)'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Tax Deduction Guide'),
                    subtitle: const Text('IRS Publication 561 — determining fair market value'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  const _ProfileStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
