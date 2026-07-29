import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'partnership_footer.dart';

/// "Our Manifesto" — mission pillars + sponsorship CTA for Landing / About Us.
class MedGiftManifestoSection extends StatelessWidget {
  const MedGiftManifestoSection({
    super.key,
    this.showEyebrow = true,
  });

  final bool showEyebrow;

  void _openDetail(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String detailTitleKey,
    required String? bodyKey,
    required String? introKey,
    required List<String> bulletKeys,
  }) {
    final loc = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => _ManifestoDetailDialog(
        icon: icon,
        color: color,
        title: loc.t(detailTitleKey),
        body: bodyKey == null ? null : loc.t(bodyKey),
        intro: introKey == null ? null : loc.t(introKey),
        bullets: bulletKeys.map(loc.t).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final pillars = [
      (
        icon: Icons.recycling_outlined,
        color: const Color(0xFF2E7D32),
        title: loc.t('manifesto.pillar1Title'),
        body: loc.t('manifesto.pillar1Body'),
        onTap: () => _openDetail(
          context,
          icon: Icons.recycling_outlined,
          color: const Color(0xFF2E7D32),
          detailTitleKey: 'manifesto.detail1Title',
          bodyKey: 'manifesto.detail1Body',
          introKey: null,
          bulletKeys: const [],
        ),
      ),
      (
        icon: Icons.groups_outlined,
        color: AppTheme.primaryBlue,
        title: loc.t('manifesto.pillar2Title'),
        body: loc.t('manifesto.pillar2Body'),
        onTap: () => _openDetail(
          context,
          icon: Icons.groups_outlined,
          color: AppTheme.primaryBlue,
          detailTitleKey: 'manifesto.detail2Title',
          bodyKey: null,
          introKey: 'manifesto.detail2Intro',
          bulletKeys: const [
            'manifesto.detail2Bullet1',
            'manifesto.detail2Bullet2',
            'manifesto.detail2Bullet3',
          ],
        ),
      ),
      (
        icon: Icons.energy_savings_leaf_outlined,
        color: const Color(0xFF00897B),
        title: loc.t('manifesto.pillar3Title'),
        body: loc.t('manifesto.pillar3Body'),
        onTap: () => _openDetail(
          context,
          icon: Icons.energy_savings_leaf_outlined,
          color: const Color(0xFF00897B),
          detailTitleKey: 'manifesto.detail3Title',
          bodyKey: null,
          introKey: 'manifesto.detail3Intro',
          bulletKeys: const [
            'manifesto.detail3Bullet1',
            'manifesto.detail3Bullet2',
          ],
        ),
      ),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryDeepBlue,
                  Color(0xFF0B3D2E),
                  AppTheme.primaryBlue,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showEyebrow) ...[
                  Text(
                    loc.t('manifesto.eyebrow'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  loc.t('manifesto.title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  loc.t('manifesto.subtitle'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Text(
              loc.t('manifesto.lead'),
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: AppTheme.primaryDeepBlue.withValues(alpha: 0.92),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                for (var i = 0; i < pillars.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _PillarCard(
                    icon: pillars[i].icon,
                    color: pillars[i].color,
                    title: pillars[i].title,
                    body: pillars[i].body,
                    readMoreLabel: loc.t('manifesto.readMore'),
                    onTap: pillars[i].onTap,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('manifesto.ctaBody'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => openPartnershipInquiry(context),
                  icon: const Icon(Icons.volunteer_activism_outlined),
                  label: Text(loc.t('manifesto.ctaButton')),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.readMoreLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String readMoreLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  Icon(Icons.open_in_new, size: 18, color: color),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                readMoreLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManifestoDetailDialog extends StatelessWidget {
  const _ManifestoDetailDialog({
    required this.icon,
    required this.color,
    required this.title,
    required this.bullets,
    this.body,
    this.intro,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? body;
  final String? intro;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      title: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (body != null)
                Text(
                  body!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.55,
                      ),
                ),
              if (intro != null) ...[
                Text(
                  intro!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.55,
                      ),
                ),
                if (bullets.isNotEmpty) const SizedBox(height: 14),
              ],
              ...bullets.map(
                (bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle, size: 8, color: color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          bullet,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.5,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.t('manifesto.close')),
        ),
      ],
    );
  }
}
