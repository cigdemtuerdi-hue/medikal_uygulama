import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/recipient_models.dart';
import '../services/ai_matching_service.dart';
import '../widgets/ai_matching_indicator.dart';

class RecipientProfileScreen extends StatefulWidget {
  const RecipientProfileScreen({super.key});

  @override
  State<RecipientProfileScreen> createState() => _RecipientProfileScreenState();
}

class _RecipientProfileScreenState extends State<RecipientProfileScreen> {
  final _matchingService = AiMatchingService();

  static const _recipient = RecipientProfile(
    id: 'rec-001',
    name: 'Maria S.',
    initials: 'MS',
    city: 'Cleveland',
    state: 'OH',
    zipCode: '44114',
    phone: '(216) 555-0142',
    email: 'maria.recipient@email.com',
    itemsNeeded: [
      NeededItem(label: 'Transport Wheelchair', quantity: 1),
      NeededItem(label: 'Wound Dressing Kits', quantity: 2),
      NeededItem(label: 'Rollator Walker', quantity: 1),
    ],
  );

  late AiMatchingSummary _matching = _matchingService.matchForRecipient(_recipient);

  void _refreshMatching() {
    setState(() {
      _matching = _matchingService.matchForRecipient(_recipient);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient / Recipient Profile'),
        actions: [
          IconButton(
            onPressed: _refreshMatching,
            icon: const Icon(Icons.sync_outlined),
            tooltip: 'Refresh AI Matching',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 500;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isWide)
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ProfileColumn(recipient: _recipient),
                                const SizedBox(width: 32),
                                Expanded(child: _NeedsColumn(recipient: _recipient)),
                              ],
                            ),
                          )
                        else ...[
                          _ProfileColumn(recipient: _recipient),
                          const SizedBox(height: 28),
                          _NeedsColumn(recipient: _recipient),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Divider(height: 1),
                        ),
                        AiMatchingIndicator(summary: _matching),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileColumn extends StatelessWidget {
  const _ProfileColumn({required this.recipient});

  final RecipientProfile recipient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
            child: Text(
              recipient.initials,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            recipient.name,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Recipient',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 20),
          _InfoLine(
            icon: Icons.location_on_outlined,
            text: '${recipient.city}, ${recipient.state} ${recipient.zipCode}',
          ),
          const SizedBox(height: 10),
          _InfoLine(icon: Icons.phone_outlined, text: recipient.phone),
          const SizedBox(height: 10),
          _InfoLine(icon: Icons.email_outlined, text: recipient.email),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _NeedsColumn extends StatelessWidget {
  const _NeedsColumn({required this.recipient});

  final RecipientProfile recipient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items Needed', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        ...recipient.itemsNeeded.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  item.displayText,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
