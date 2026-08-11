import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/emergency_mode_service.dart';
import '../services/site_settings_service.dart';


List<String> _disasterHashtags(AppLocalizations loc) {
  return loc
      .t('disaster.announcementHashtags')
      .split(RegExp(r'\s+'))
      .map((t) => t.trim())
      .where((t) => t.startsWith('#'))
      .toList(growable: false);
}

Widget _hashtagWrap(AppLocalizations loc, {bool onDark = false}) {
  final tags = _disasterHashtags(loc);
  if (tags.isEmpty) return const SizedBox.shrink();
  final fg = onDark ? Colors.white : const Color(0xFFB71C1C);
  final bg = onDark
      ? Colors.white.withValues(alpha: 0.16)
      : const Color(0xFFB71C1C).withValues(alpha: 0.08);
  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final tag in tags)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: fg.withValues(alpha: 0.55)),
          ),
          child: Text(
            tag,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
    ],
  );
}

/// Full-width strip shown when Disaster & Emergency Response Mode is active.
class EmergencyResponseBanner extends StatefulWidget {
  const EmergencyResponseBanner({super.key});

  @override
  State<EmergencyResponseBanner> createState() =>
      _EmergencyResponseBannerState();
}

class _EmergencyResponseBannerState extends State<EmergencyResponseBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _openDetails() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const EmergencyAnnouncementSheet(),
    );
  }

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
            child: InkWell(
              onTap: _openDetails,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final opacity = 0.45 + (_pulse.value * 0.55);
                  return Opacity(opacity: opacity, child: child);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 12,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loc.t('disaster.tapForDetails'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Login / landing page emergency card — red pulsing callout.
class EmergencyLandingCallout extends StatefulWidget {
  const EmergencyLandingCallout({super.key});

  @override
  State<EmergencyLandingCallout> createState() =>
      _EmergencyLandingCalloutState();
}

class _EmergencyLandingCalloutState extends State<EmergencyLandingCallout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        EmergencyModeService.instance,
        SiteSettingsService.instance,
      ]),
      builder: (context, _) {
        final cms = SiteSettingsService.instance;
        final emergency = cms.settings.emergency;
        final enabled = cms.settings.flags.showEmergencyBanner &&
            (emergency.enabled || EmergencyModeService.instance.enabled);
        if (!enabled) return const SizedBox.shrink();

        final loc = AppLocalizations.of(context);
        return AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final glow = 0.35 + (_pulse.value * 0.65);
            return Opacity(opacity: glow, child: child);
          },
          child: Material(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const EmergencyAnnouncementSheet(),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFB71C1C), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.t('disaster.announcementEyebrow'),
                      style: const TextStyle(
                        color: Color(0xFFB71C1C),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.t('disaster.bannerTitle'),
                      style: const TextStyle(
                        color: Color(0xFFB71C1C),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.t('disaster.bannerBody'),
                      style: const TextStyle(
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.t('disaster.tapForDetails'),
                      style: const TextStyle(
                        color: Color(0xFFB71C1C),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _hashtagWrap(loc),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Full public announcement sheet.
class EmergencyAnnouncementSheet extends StatelessWidget {
  const EmergencyAnnouncementSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    Widget section(String text, {bool bold = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.45,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              loc.t('disaster.announcementEyebrow'),
              style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              loc.t('disaster.announcementHeadline'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFFB71C1C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            section(loc.t('disaster.announcementP1')),
            section(loc.t('disaster.announcementP2')),
            section(loc.t('disaster.announcementP3')),
            section(loc.t('disaster.announcementP4'), bold: true),
            const SizedBox(height: 4),
            section(loc.t('disaster.announcementSignoff')),
            section(loc.t('disaster.announcementOrg'), bold: true),
            section(loc.t('disaster.announcementContact')),
            const SizedBox(height: 8),
            Text(
              loc.t('disaster.hashtagsLabel'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFFB71C1C),
              ),
            ),
            const SizedBox(height: 8),
            _hashtagWrap(loc),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(loc.t('common.close')),
            ),
          ],
        ),
      ),
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
    final cms = SiteSettingsService.instance;
    const color = Color(0xFFC62828);

    return ListenableBuilder(
      listenable: cms,
      builder: (context, _) {
        final label = cms.text(
          cms.settings.emergency.crisisLabel,
          loc.t('disaster.crisisLabel'),
        );
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
            label,
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
      },
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