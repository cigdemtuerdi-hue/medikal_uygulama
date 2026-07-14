import 'package:flutter/material.dart';

import '../models/donation_models.dart';
import '../services/donation_service.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedGift US'),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('United States'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Donate DME & Wound Care Supplies',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect surplus medical equipment with US nonprofits, clinics, and disaster relief partners.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            const ComplianceBanner(),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: const [
                    StatCard(
                      label: 'Items donated (30d)',
                      value: '1,284',
                      icon: Icons.inventory_2_outlined,
                    ),
                    StatCard(
                      label: 'Partner organizations',
                      value: '312',
                      icon: Icons.apartment_outlined,
                    ),
                    StatCard(
                      label: 'AI scans completed',
                      value: '4,907',
                      icon: Icons.document_scanner_outlined,
                    ),
                    StatCard(
                      label: 'States served',
                      value: '48',
                      icon: Icons.map_outlined,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            const SectionHeader(
              title: 'Quick Actions',
              subtitle: 'Start a donation or match with an open request',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.accessible),
                  label: const Text('Donate DME'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(Icons.healing),
                  label: const Text('Donate Wound Care'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('AI Equipment Scan'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const SectionHeader(title: 'Recent Donations'),
            const SizedBox(height: 12),
            ...DonationService.recentDonations.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    item.category == DonationCategory.dme
                        ? Icons.accessible
                        : Icons.healing,
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.quantity} item(s) · ZIP ${item.zipCode} · '
                    '${conditionLabel(item.condition)}',
                  ),
                  trailing: item.aiConfidence != null
                      ? Chip(label: Text('AI ${(item.aiConfidence! * 100).round()}%'))
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
