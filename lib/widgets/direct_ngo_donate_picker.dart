import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/ngo_partner_models.dart';
import '../services/ngo_partner_service.dart';
import 'verified_ngo_badge.dart';

/// Donor form: optionally route a listing directly to an NGO warehouse.
class DirectNgoDonatePicker extends StatelessWidget {
  const DirectNgoDonatePicker({
    super.key,
    required this.enabled,
    required this.selectedPartnerId,
    required this.onEnabledChanged,
    required this.onPartnerChanged,
  });

  final bool enabled;
  final String? selectedPartnerId;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String?> onPartnerChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final partners = NgoPartnerService.instance.verifiedPartners;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              onChanged: onEnabledChanged,
              secondary: Icon(
                Icons.account_balance_outlined,
                color: enabled ? const Color(0xFF1565C0) : null,
              ),
              title: Text(
                loc.t('ngo.directDonateToggle'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(loc.t('ngo.directDonateHint')),
            ),
            if (enabled) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedPartnerId ?? partners.first.id,
                decoration: InputDecoration(
                  labelText: loc.t('ngo.directDonateSelect'),
                ),
                items: [
                  for (final partner in partners)
                    DropdownMenuItem(
                      value: partner.id,
                      child: Text('${partner.name} — ${partner.locationLabel}'),
                    ),
                ],
                onChanged: onPartnerChanged,
              ),
              const SizedBox(height: 10),
              const VerifiedNgoBadge(compact: true),
              if (selectedPartnerId != null || partners.isNotEmpty) ...[
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final id = selectedPartnerId ?? partners.first.id;
                    final partner = NgoPartnerService.instance.findById(id);
                    if (partner == null) return const SizedBox.shrink();
                    return Text(
                      loc.t('ngo.directDonateWarehouse', {
                        'warehouse': partner.warehouseDisplay,
                      }),
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact chip showing direct NGO destination on listing cards.
class DirectNgoDestinationChip extends StatelessWidget {
  const DirectNgoDestinationChip({
    super.key,
    required this.partner,
  });

  final NgoPartner partner;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    const color = Color(0xFF1565C0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            loc.t('ngo.directChip', {'org': partner.name}),
            style: const TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
