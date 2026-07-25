import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/item_lifecycle_models.dart';
import '../services/donation_service.dart' show formatDonationDate;
import '../services/item_lifecycle_service.dart';

/// Stylish Item Journey timeline + circular impact summary.
class ItemJourneyCard extends StatelessWidget {
  const ItemJourneyCard({
    super.key,
    required this.record,
  });

  final ItemLifecycleRecord record;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final co2 = ItemLifecycleService.instance.co2SavedKgFor(record);
    final co2Label = co2 == co2.roundToDouble()
        ? co2.round().toString()
        : co2.toStringAsFixed(0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.t('passItOn.journeyTitle'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              loc.t('passItOn.journeySubtitle'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentTeal.withValues(alpha: 0.16),
                    AppTheme.primaryBlue.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                loc.t('passItOn.impactSummary', {
                  'lives': record.livesImpacted,
                  'co2': co2Label,
                }),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(
                  icon: Icons.favorite,
                  label: loc.t('passItOn.livesImpacted', {
                    'count': record.livesImpacted,
                  }),
                  color: Colors.pink.shade700,
                ),
                _StatChip(
                  icon: Icons.cloud_done_outlined,
                  label: loc.t('passItOn.co2Saved', {'value': co2Label}),
                  color: const Color(0xFF2E7D32),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...List.generate(record.events.length, (index) {
              final event = record.events[index];
              final isLast = index == record.events.length - 1;
              return _JourneyStep(
                event: event,
                isLast: isLast,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({
    required this.event,
    required this.isLast,
  });

  final ItemJourneyEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final color = switch (event.type) {
      ItemJourneyEventType.donated => AppTheme.primaryBlue,
      ItemJourneyEventType.used => AppTheme.accentTeal,
      ItemJourneyEventType.passedOn => Colors.deepOrange.shade700,
      ItemJourneyEventType.received => Colors.green.shade700,
    };
    final icon = switch (event.type) {
      ItemJourneyEventType.donated => Icons.volunteer_activism_outlined,
      ItemJourneyEventType.used => Icons.accessibility_new,
      ItemJourneyEventType.passedOn => Icons.replay_circle_filled,
      ItemJourneyEventType.received => Icons.handshake_outlined,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 36,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.grey.shade300,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _eventHeadline(loc, event),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _eventMeta(loc, event),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _eventHeadline(AppLocalizations loc, ItemJourneyEvent event) {
    final location = event.locationLabel;
    return switch (event.type) {
      ItemJourneyEventType.donated => location == null
          ? loc.t('passItOn.eventDonated', {'name': event.actorName})
          : loc.t('passItOn.eventDonatedAt', {
              'name': event.actorName,
              'place': location,
            }),
      ItemJourneyEventType.used => location == null
          ? loc.t('passItOn.eventUsed', {
              'name': event.actorName,
              'duration': event.durationLabel ?? loc.t('passItOn.durationUnknown'),
            })
          : loc.t('passItOn.eventUsedFor', {
              'name': event.actorName,
              'purpose': location,
              'duration': event.durationLabel ?? loc.t('passItOn.durationUnknown'),
            }),
      ItemJourneyEventType.passedOn => loc.t('passItOn.eventPassedOn', {
          'name': event.actorName,
        }),
      ItemJourneyEventType.received => event.isPresent
          ? loc.t('passItOn.eventPassedToPresent', {'name': event.actorName})
          : loc.t('passItOn.eventReceived', {'name': event.actorName}),
    };
  }

  String _eventMeta(AppLocalizations loc, ItemJourneyEvent event) {
    final date = formatDonationDate(event.at);
    if (event.isPresent) {
      return loc.t('passItOn.metaPresent', {'date': date});
    }
    return date;
  }
}
