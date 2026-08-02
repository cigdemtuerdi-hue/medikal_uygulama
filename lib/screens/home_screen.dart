import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localized_labels.dart';
import '../models/donation_models.dart';
import '../services/donation_service.dart';
import '../services/site_settings_service.dart';
import '../widgets/browse_equipment_entry_card.dart';
import '../widgets/common_widgets.dart';
import '../widgets/corporate_esg_badge_cards.dart';
import '../widgets/impact_esg_dashboard_card.dart';
import '../widgets/language_menu_button.dart';
import '../widgets/partnership_footer.dart';
import '../widgets/pass_it_on_entry_card.dart';
import '../widgets/sales_entry_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cms = SiteSettingsService.instance;

    return ListenableBuilder(
      listenable: cms,
      builder: (context, _) {
        final s = cms.settings;
        final f = s.flags;
        final h = s.home;
        final title = cms.text(h.title, loc.t('home.title'));
        final subtitle = cms.text(h.subtitle, loc.t('home.subtitle'));
        final location =
            cms.text(h.locationLabel, loc.t('common.unitedStates'));

        return Scaffold(
          appBar: AppBar(
            title: Text(
              cms.text(s.brand.displayName, loc.t('app.title')),
            ),
            actions: [
              const LanguageMenuButton(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.location_on_outlined),
                label: Text(location),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                if (f.showComplianceBanner) ...[
                  const ComplianceBanner(),
                  const SizedBox(height: 16),
                ],
                if (f.showBrowseEntry) ...[
                  const BrowseEquipmentEntryCard(),
                  const SizedBox(height: 16),
                ],
                // Fallback when Quick Actions are hidden in CMS.
                if (!f.showQuickActions) ...[
                  const SalesEntryCard(),
                  const SizedBox(height: 16),
                ],
                if (f.showPassItOnEntry) ...[
                  const PassItOnEntryCard(),
                  const SizedBox(height: 24),
                ],
                if (f.showImpactCard) ...[
                  const ImpactEsgDashboardCard(),
                  const SizedBox(height: 24),
                ],
                if (f.showHomeStats) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount =
                          constraints.maxWidth > 900 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.4,
                        children: [
                          StatCard(
                            label: cms.text(
                              h.statItemsLabel,
                              loc.t('home.statItemsDonated'),
                            ),
                            value: cms.text(h.statItemsValue, '1,284'),
                            icon: Icons.inventory_2_outlined,
                          ),
                          StatCard(
                            label: cms.text(
                              h.statOrgsLabel,
                              loc.t('home.statPartnerOrgs'),
                            ),
                            value: cms.text(h.statOrgsValue, '312'),
                            icon: Icons.apartment_outlined,
                          ),
                          StatCard(
                            label: cms.text(
                              h.statAiLabel,
                              loc.t('home.statAiScans'),
                            ),
                            value: cms.text(h.statAiValue, '4,907'),
                            icon: Icons.document_scanner_outlined,
                          ),
                          StatCard(
                            label: cms.text(
                              h.statStatesLabel,
                              loc.t('home.statStatesServed'),
                            ),
                            value: cms.text(h.statStatesValue, '48'),
                            icon: Icons.map_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
                if (f.showQuickActions) ...[
                  SectionHeader(
                    title: cms.text(
                      h.quickActionsTitle,
                      loc.t('home.quickActions'),
                    ),
                    subtitle: cms.text(
                      h.quickActionsSubtitle,
                      loc.t('home.quickActionsSubtitle'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.dme);
                        },
                        icon: const Icon(Icons.accessible),
                        label: Text(
                          cms.text(h.donateDmeLabel, loc.t('home.donateDme')),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.woundCare);
                        },
                        icon: const Icon(Icons.healing),
                        label: Text(
                          cms.text(
                            h.donateWoundCareLabel,
                            loc.t('home.donateWoundCare'),
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.recipient);
                        },
                        icon: const Icon(Icons.near_me_outlined),
                        label: Text(
                          cms.text(
                            h.browseCtaLabel,
                            loc.t('browseEquipment.entryTitle'),
                          ),
                        ),
                      ),
                      // Keep Sale with other CTAs — not a bottom FAB over MeGi.
                      FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.shop);
                        },
                        icon: const Icon(Icons.storefront_outlined),
                        label: Text(loc.t('shop.entryTitle')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.t('shop.entryBody'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 32),
                ],
                if (f.showRecentDonations) ...[
                  SectionHeader(
                    title: cms.text(
                      h.recentTitle,
                      loc.t('home.recentDonations'),
                    ),
                  ),
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
                          loc.t('home.recentItemSubtitle', {
                            'qty': item.quantity,
                            'zip': item.zipCode,
                            'condition': locCondition(loc, item.condition),
                          }),
                        ),
                        trailing: item.aiConfidence != null
                            ? Chip(
                                label: Text(
                                  loc.t(
                                    'common.aiPercent',
                                    {
                                      'percent':
                                          (item.aiConfidence! * 100).round(),
                                    },
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                if (f.showSponsors) const CorporateSponsorsSection(),
                if (f.showPartnershipFooter) const PartnershipFooter(),
              ],
            ),
          ),
        );
      },
    );
  }
}
