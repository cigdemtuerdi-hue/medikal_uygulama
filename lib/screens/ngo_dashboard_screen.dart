import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/ngo_partner_models.dart';
import '../services/ngo_partner_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/verified_ngo_badge.dart';

/// Non-Profit Portal dashboard for verified NGO partners.
class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Demo portal always has a session partner for walkthrough.
    NgoPartnerService.instance.ensureDemoSession();
  }

  Future<void> _openBulkRequestDialog() async {
    final loc = AppLocalizations.of(context);
    final itemController = TextEditingController();
    final notesController = TextEditingController();
    var quantity = 10;
    var urgency = 'High';
    var category = 'DME';

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(loc.t('ngo.bulkDialogTitle')),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(loc.t('ngo.bulkDialogBody')),
                      const SizedBox(height: 14),
                      TextField(
                        controller: itemController,
                        decoration: InputDecoration(
                          labelText: loc.t('ngo.bulkItemLabel'),
                          hintText: loc.t('ngo.bulkItemHint'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: InputDecoration(
                          labelText: loc.t('ngo.bulkCategoryLabel'),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'DME',
                            child: Text(loc.t('common.categoryDme')),
                          ),
                          DropdownMenuItem(
                            value: 'Wound Care',
                            child: Text(loc.t('common.categoryWoundCare')),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setLocal(() => category = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: urgency,
                        decoration: InputDecoration(
                          labelText: loc.t('ngo.bulkUrgencyLabel'),
                        ),
                        items: [
                          for (final u in ['Critical', 'High', 'Medium'])
                            DropdownMenuItem(value: u, child: Text(u)),
                        ],
                        onChanged: (v) {
                          if (v != null) setLocal(() => urgency = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(loc.t('ngo.bulkQtyLabel')),
                          const Spacer(),
                          IconButton(
                            onPressed: quantity > 1
                                ? () => setLocal(() => quantity--)
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Text('$quantity'),
                          IconButton(
                            onPressed: () => setLocal(() => quantity++),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: loc.t('ngo.bulkNotesLabel'),
                          hintText: loc.t('ngo.bulkNotesHint'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(loc.t('common.cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    if (itemController.text.trim().isEmpty) return;
                    NgoPartnerService.instance.addBulkRequest(
                      itemNeeded: itemController.text,
                      unitsRequested: quantity,
                      categoryLabel: category,
                      urgency: urgency,
                      notes: notesController.text,
                    );
                    Navigator.pop(context, true);
                  },
                  child: Text(loc.t('ngo.bulkSubmit')),
                ),
              ],
            );
          },
        );
      },
    );

    itemController.dispose();
    notesController.dispose();
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.t('ngo.bulkSuccessSnack'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('ngo.appBarTitle'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBulkRequestDialog,
        icon: const Icon(Icons.playlist_add),
        label: Text(loc.t('ngo.bulkCta')),
      ),
      body: ListenableBuilder(
        listenable: NgoPartnerService.instance,
        builder: (context, _) {
          final service = NgoPartnerService.instance;
          final partner = service.sessionPartner;
          final bulk = service.bulkRequestsForSession;
          final inbound = service.sessionDirectDonations;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: loc.t('ngo.dashboardTitle'),
                  subtitle: loc.t('ngo.dashboardSubtitle'),
                ),
                const SizedBox(height: 12),
                if (partner != null) _NgoHeaderCard(partner: partner),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatTile(
                      label: loc.t('ngo.statBulk'),
                      value: '${bulk.length}',
                      color: AppTheme.primaryBlue,
                      icon: Icons.inventory_2_outlined,
                    ),
                    _StatTile(
                      label: loc.t('ngo.statDirect'),
                      value: '${inbound.length}',
                      color: AppTheme.accentTeal,
                      icon: Icons.local_shipping_outlined,
                    ),
                    _StatTile(
                      label: loc.t('ngo.statPartners'),
                      value: '${service.verifiedPartners.length}',
                      color: const Color(0xFF1565C0),
                      icon: Icons.hub_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  loc.t('ngo.bulkSectionTitle'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.t('ngo.bulkSectionSubtitle'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (bulk.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(loc.t('ngo.bulkEmpty')),
                    ),
                  )
                else
                  ...bulk.map((r) => _BulkRequestCard(request: r)),
                const SizedBox(height: 28),
                Text(
                  loc.t('ngo.directSectionTitle'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.t('ngo.directSectionSubtitle'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (inbound.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(loc.t('ngo.directEmpty')),
                    ),
                  )
                else
                  ...inbound.map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.accentTeal.withValues(alpha: 0.15),
                          child: const Icon(
                            Icons.volunteer_activism,
                            color: AppTheme.accentTeal,
                          ),
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          loc.t('ngo.directItemMeta', {
                            'area': item.donorAreaLabel,
                            'qty': item.quantityAvailable,
                          }),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NgoHeaderCard extends StatelessWidget {
  const _NgoHeaderCard({required this.partner});

  final NgoPartner partner;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    partner.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const VerifiedNgoBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${partner.locationLabel} · EIN ${partner.ein}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              loc.t('ngo.warehouseLabel', {
                'warehouse': partner.warehouseDisplay,
              }),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: color,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _BulkRequestCard extends StatelessWidget {
  const _BulkRequestCard({required this.request});

  final NgoBulkRequest request;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final progress = request.progress.clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.itemNeeded,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Chip(
                  label: Text(request.urgency),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.orange.withValues(alpha: 0.12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              loc.t('ngo.bulkCardMeta', {
                'category': request.categoryLabel,
                'qty': request.unitsRequested,
              }),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (request.notes != null) ...[
              const SizedBox(height: 6),
              Text(request.notes!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Text(
              loc.t('requestCard.unitsProgress', {
                'fulfilled': request.unitsFulfilled,
                'requested': request.unitsRequested,
              }),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
