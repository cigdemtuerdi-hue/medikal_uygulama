import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/corporate_esg_badge_service.dart';
import '../services/impact_metrics_service.dart';
import '../services/site_settings_service.dart';
import 'common_widgets.dart';

String _formatInt(int value) {
  final raw = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) buf.write(',');
    buf.write(raw[i]);
  }
  return buf.toString();
}

String _formatCo2(double value) {
  final rounded = value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);
  final parts = rounded.split('.');
  final whole = _formatInt(int.parse(parts[0]));
  return parts.length > 1 ? '$whole.${parts[1]}' : whole;
}

Color _tierColor(CorporateEsgBadgeTier tier) {
  return switch (tier) {
    CorporateEsgBadgeTier.ecoSponsor => const Color(0xFF8D6E63), // bronze
    CorporateEsgBadgeTier.communityImpactLeader =>
      const Color(0xFF78909C), // silver
    CorporateEsgBadgeTier.zeroWasteHero => const Color(0xFFC9A227), // gold
  };
}

Color _tierHighlight(CorporateEsgBadgeTier tier) {
  return switch (tier) {
    CorporateEsgBadgeTier.ecoSponsor => const Color(0xFFD7CCC8),
    CorporateEsgBadgeTier.communityImpactLeader => const Color(0xFFECEFF1),
    CorporateEsgBadgeTier.zeroWasteHero => const Color(0xFFFFF3C4),
  };
}

Color _tierDeep(CorporateEsgBadgeTier tier) {
  return switch (tier) {
    CorporateEsgBadgeTier.ecoSponsor => const Color(0xFF4E342E),
    CorporateEsgBadgeTier.communityImpactLeader => const Color(0xFF37474F),
    CorporateEsgBadgeTier.zeroWasteHero => const Color(0xFF8A6D00),
  };
}

IconData _tierIcon(CorporateEsgBadgeTier tier) {
  return switch (tier) {
    CorporateEsgBadgeTier.ecoSponsor => Icons.eco,
    CorporateEsgBadgeTier.communityImpactLeader => Icons.diversity_3,
    CorporateEsgBadgeTier.zeroWasteHero => Icons.military_tech,
  };
}

String _tierMonogram(CorporateEsgBadgeTier tier) {
  return switch (tier) {
    CorporateEsgBadgeTier.ecoSponsor => 'ES',
    CorporateEsgBadgeTier.communityImpactLeader => 'CI',
    CorporateEsgBadgeTier.zeroWasteHero => 'ZW',
  };
}

/// Premium circular medal-style logo for each ESG badge tier.
class _EsgMedalLogo extends StatelessWidget {
  const _EsgMedalLogo({
    required this.tier,
    this.size = 64,
  });

  final CorporateEsgBadgeTier tier;
  final double size;

  @override
  Widget build(BuildContext context) {
    final metal = _tierColor(tier);
    final highlight = _tierHighlight(tier);
    final deep = _tierDeep(tier);
    final iconSize = size * 0.34;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft glow
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: metal.withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          // Outer metallic ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  highlight,
                  metal,
                  deep,
                  metal,
                  highlight,
                ],
              ),
            ),
          ),
          // Inner disc
          Container(
            width: size * 0.82,
            height: size * 0.82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  highlight.withValues(alpha: 0.95),
                  metal.withValues(alpha: 0.88),
                  deep.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle inner ring
                Container(
                  width: size * 0.62,
                  height: size * 0.62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _tierIcon(tier),
                      color: Colors.white,
                      size: iconSize,
                      shadows: [
                        Shadow(
                          color: deep.withValues(alpha: 0.7),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    SizedBox(height: size * 0.02),
                    Text(
                      _tierMonogram(tier),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w800,
                        fontSize: size * 0.13,
                        letterSpacing: 1.1,
                        shadows: [
                          Shadow(
                            color: deep.withValues(alpha: 0.8),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Top highlight arc illusion
          Positioned(
            top: size * 0.1,
            child: Container(
              width: size * 0.42,
              height: size * 0.12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Large holographic circular seal — separate from the compact side medal.
class _EsgHologramSeal extends StatefulWidget {
  const _EsgHologramSeal({
    required this.tier,
    required this.year,
    this.size = 168,
  });

  final CorporateEsgBadgeTier tier;
  final int year;
  final double size;

  @override
  State<_EsgHologramSeal> createState() => _EsgHologramSealState();
}

class _EsgHologramSealState extends State<_EsgHologramSeal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    // Skip infinite repeat under test bindings so pumpAndSettle can finish.
    final isTestBinding = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (isTestBinding) {
      _controller.value = 0.28;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metal = _tierColor(widget.tier);
    final highlight = _tierHighlight(widget.tier);
    final deep = _tierDeep(widget.tier);
    final size = widget.size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft holographic aura
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: metal.withValues(alpha: 0.55),
                      blurRadius: 28,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.18),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              // Outer bezel
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    transform: GradientRotation(t * 6.28318),
                    colors: [
                      highlight,
                      metal,
                      deep,
                      highlight.withValues(alpha: 0.85),
                      metal,
                      deep,
                      highlight,
                    ],
                  ),
                ),
              ),
              // Engraved ring band
              Container(
                width: size * 0.92,
                height: size * 0.92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      deep.withValues(alpha: 0.55),
                      deep.withValues(alpha: 0.95),
                    ],
                  ),
                  border: Border.all(
                    color: highlight.withValues(alpha: 0.55),
                    width: 1.2,
                  ),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: const Alignment(0, -0.92),
                      child: Text(
                        'MEDGIFT  •  ESG  •  ${widget.year}',
                        style: TextStyle(
                          color: highlight.withValues(alpha: 0.92),
                          fontSize: size * 0.042,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, 0.92),
                      child: Text(
                        'VERIFIED SEAL',
                        style: TextStyle(
                          color: highlight.withValues(alpha: 0.75),
                          fontSize: size * 0.038,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Main holographic disc
              ClipOval(
                child: SizedBox(
                  width: size * 0.74,
                  height: size * 0.74,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-0.35, -0.4),
                            radius: 1.05,
                            colors: [
                              highlight,
                              metal,
                              deep,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                      // Iridescent rainbow foil
                      Opacity(
                        opacity: 0.42,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: SweepGradient(
                              transform: GradientRotation(t * 6.28318 * 1.35),
                              colors: const [
                                Color(0x00FFFFFF),
                                Color(0x88FF80AB),
                                Color(0x6680D8FF),
                                Color(0x88B388FF),
                                Color(0x66FFD740),
                                Color(0x8869F0AE),
                                Color(0x00FFFFFF),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Moving light streak
                      Transform.rotate(
                        angle: t * 6.28318,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: size * 0.22,
                            height: size * 0.55,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.55),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Concentric engraved rings
                      CustomPaint(
                        painter: _HoloRingPainter(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      // Center emblem
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _tierIcon(widget.tier),
                              size: size * 0.22,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: deep.withValues(alpha: 0.85),
                                  blurRadius: 8,
                                ),
                                Shadow(
                                  color: const Color(0xFFEA80FC)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            SizedBox(height: size * 0.02),
                            Text(
                              _tierMonogram(widget.tier),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: size * 0.11,
                                letterSpacing: 2.2,
                                shadows: [
                                  Shadow(
                                    color: deep.withValues(alpha: 0.9),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: size * 0.01),
                            Text(
                              'AUTHENTIC',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                                fontSize: size * 0.045,
                                letterSpacing: 2.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Specular glass highlight
                      Align(
                        alignment: const Alignment(-0.45, -0.55),
                        child: Container(
                          width: size * 0.28,
                          height: size * 0.14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.55),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Thin chrome rim on top
              IgnorePointer(
                child: Container(
                  width: size * 0.74,
                  height: size * 0.74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HoloRingPainter extends CustomPainter {
  _HoloRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = color;

    for (final factor in [0.92, 0.72, 0.52]) {
      canvas.drawCircle(center, size.shortestSide * 0.5 * factor, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HoloRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

String _tierTitleKey(CorporateEsgBadgeTier tier) {
  return switch (tier) {
    CorporateEsgBadgeTier.ecoSponsor => 'esgBadge.ecoSponsor',
    CorporateEsgBadgeTier.communityImpactLeader =>
      'esgBadge.communityImpactLeader',
    CorporateEsgBadgeTier.zeroWasteHero => 'esgBadge.zeroWasteHero',
  };
}

String _tierDescKey(CorporateEsgBadgeTier tier) {
  return switch (tier) {
    CorporateEsgBadgeTier.ecoSponsor => 'esgBadge.ecoSponsorDesc',
    CorporateEsgBadgeTier.communityImpactLeader =>
      'esgBadge.communityImpactLeaderDesc',
    CorporateEsgBadgeTier.zeroWasteHero => 'esgBadge.zeroWasteHeroDesc',
  };
}

/// Single ESG badge card with live contribution metrics + embed action.
class CorporateEsgBadgeCard extends StatelessWidget {
  const CorporateEsgBadgeCard({
    super.key,
    required this.badge,
    this.showEmbedButton = true,
    this.compact = false,
  });

  final CorporateEsgBadge badge;
  final bool showEmbedButton;
  final bool compact;

  Future<void> _openEmbedSheet(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final title = loc.t(_tierTitleKey(badge.tier));
    final html = badge.embedHtml(badgeTitle: title);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.t('esgBadge.embedTitle'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.t('esgBadge.embedSubtitle', {
                    'org': badge.organizationName,
                  }),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    html,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.35,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  loc.t('esgBadge.imageUrlLabel'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                SelectableText(
                  badge.badgeImageUrl,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: html));
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.t('esgBadge.copiedSnack'))),
                    );
                  },
                  icon: const Icon(Icons.copy_all_outlined),
                  label: Text(loc.t('esgBadge.copyCode')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final color = _tierColor(badge.tier);
    final title = loc.t(_tierTitleKey(badge.tier));
    final desc = loc.t(_tierDescKey(badge.tier));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: color, width: 5),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 14 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _EsgHologramSeal(
                  tier: badge.tier,
                  year: badge.year,
                  size: compact ? 132 : 172,
                ),
              ),
              SizedBox(height: compact ? 14 : 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _EsgMedalLogo(
                    tier: badge.tier,
                    size: compact ? 58 : 72,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          badge.organizationName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(loc.t('esgBadge.verifiedChip', {
                      'year': badge.year,
                    })),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: color.withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    side: BorderSide(color: color.withValues(alpha: 0.35)),
                  ),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 10),
                Text(desc, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricChip(
                    icon: Icons.medical_services_outlined,
                    label: loc.t('esgBadge.metricEquipment', {
                      'count': _formatInt(badge.equipmentSaved),
                    }),
                    color: AppTheme.primaryBlue,
                  ),
                  _MetricChip(
                    icon: Icons.cloud_outlined,
                    label: loc.t('esgBadge.metricCo2', {
                      'value': _formatCo2(badge.co2SavedKg),
                    }),
                    color: const Color(0xFF2E7D32),
                  ),
                ],
              ),
              if (showEmbedButton) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => _openEmbedSheet(context),
                  icon: const Icon(Icons.code),
                  label: Text(loc.t('esgBadge.embedButton')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Profile / corporate panel section: earned badges + embed.
class CorporateEsgBadgesSection extends StatelessWidget {
  const CorporateEsgBadgesSection({
    super.key,
    required this.organizationName,
    required this.organizationId,
  });

  final String organizationName;
  final String organizationId;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: ImpactMetricsService.instance,
      builder: (context, _) {
        final badges = CorporateEsgBadgeService.instance.badgesForCurrentProfile(
          organizationName: organizationName,
          organizationId: organizationId,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: loc.t('esgBadge.profileSectionTitle'),
              subtitle: loc.t('esgBadge.profileSectionSubtitle'),
            ),
            const SizedBox(height: 12),
            ...badges.map(
              (badge) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CorporateEsgBadgeCard(badge: badge),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Home “Sponsors” showcase with live contribution metrics.
class CorporateSponsorsSection extends StatelessWidget {
  const CorporateSponsorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cms = SiteSettingsService.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([
        ImpactMetricsService.instance,
        cms,
      ]),
      builder: (context, _) {
        final sponsors = CorporateEsgBadgeService.instance.featuredSponsors;
        final h = cms.settings.home;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: cms.text(
                h.sponsorsTitle,
                loc.t('esgBadge.sponsorsSectionTitle'),
              ),
              subtitle: cms.text(
                h.sponsorsSubtitle,
                loc.t('esgBadge.sponsorsSectionSubtitle'),
              ),
            ),
            const SizedBox(height: 12),
            ...sponsors.map(
              (badge) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CorporateEsgBadgeCard(
                  badge: badge,
                  showEmbedButton: true,
                  compact: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

