import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/emergency_mode_service.dart';
import '../services/site_settings_service.dart';

/// Full-width strip shown when Disaster & Emergency Response Mode is active.
class EmergencyResponseBanner extends StatelessWidget {
  const EmergencyResponseBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        EmergencyModeService.instance,
        SiteSettingsService.instance,
      ]),
      builder: (context, _) {
        final cms = SiteSettingsService.instance;
        final flags = cms.settings.flags;
        final emergency = cms.settings.emergency;
        final enabled = flags.showEmergencyBanner &&
            (emergency.enabled || EmergencyModeService.instance.enabled);
        if (!enabled) {
          return const SizedBox.shrink();
        }

        final loc = AppLocalizations.of(context);
        final title = cms.text(
          emergency.bannerTitle,
          loc.t('disaster.bannerTitle'),
        );
        final body = cms.text(
          emergency.bannerBody,
          loc.t('disaster.bannerBody'),
        );
        return Material(
          color: const Color(0xFFB71C1C),
          elevation: 2,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          body,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Red crisis label for disaster-priority listings.
class CrisisReliefNeedBadge extends StatelessWidget {
  const CrisisReliefNeedBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    const color = Color(0xFFC62828);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.crisis_alert,
            size: compact ? 14 : 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            loc.t('disaster.crisisLabel'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 10 : 11,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

/// Donor toggle: route listing directly to disaster relief allocation.
class DisasterReliefAllocateToggle extends StatelessWidget {
  const DisasterReliefAllocateToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: EmergencyModeService.instance,
      builder: (context, _) {
        final enabled = EmergencyModeService.instance.enabled;
        return Card(
          color: value
              ? const Color(0xFFC62828).withValues(alpha: 0.06)
              : null,
          child: SwitchListTile(
            value: value && enabled,
            onChanged: enabled ? onChanged : null,
            secondary: Icon(
              Icons.volunteer_activism_outlined,
              color: (value && enabled) ? const Color(0xFFC62828) : null,
            ),
            title: Text(
              loc.t('disaster.allocateToggle'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: (value && enabled) ? const Color(0xFFB71C1C) : null,
              ),
            ),
            subtitle: Text(
              enabled
                  ? loc.t('disaster.allocateHint')
                  : loc.t('disaster.allocateDisabledHint'),
            ),
          ),
        );
      },
    );
  }
}