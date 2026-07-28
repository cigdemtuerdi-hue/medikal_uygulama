import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/profile_address.dart';
import '../services/ai_vision_service.dart';
import '../services/auth_session_service.dart';
import '../services/available_items_service.dart';
import '../services/donation_service.dart';
import '../services/emergency_mode_service.dart';
import '../services/exchange_service.dart';
import '../services/ngo_partner_service.dart';
import '../services/profile_address_service.dart';
import '../services/profile_image_service.dart';
import '../services/wishlist_service.dart';
import '../widgets/address_update_card.dart';
import '../widgets/common_widgets.dart';
import '../widgets/corporate_esg_badge_cards.dart';
import '../widgets/disaster_relief_hub_card.dart';
import '../widgets/donation_history_card.dart';
import '../widgets/exchange_receipt_card.dart';
import '../widgets/impact_esg_dashboard_card.dart';
import '../widgets/instant_match_banner.dart';
import '../widgets/language_menu_button.dart';
import '../widgets/pass_it_on_entry_card.dart';
import '../widgets/profile_avatar_image.dart';
import '../widgets/verified_ngo_badge.dart';
import '../widgets/wishlist_section_card.dart';
import 'admin_inquiries_screen.dart';
import 'dme_product_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileImageService = ProfileImageService();
  final _addressService = ProfileAddressService.instance;
  final _exchangeService = ExchangeService.instance;
  String? _profileImagePath;
  ProfileAddress? _savedAddress;
  bool _loadingAddress = true;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadAddress();
    _exchangeService.addListener(_onExchangeChanged);
    WishlistService.instance.addListener(_onExchangeChanged);
  }

  @override
  void dispose() {
    _exchangeService.removeListener(_onExchangeChanged);
    WishlistService.instance.removeListener(_onExchangeChanged);
    super.dispose();
  }

  void _openMatchedItem(String itemId) {
    final item = AvailableItemsService.instance.findById(itemId);
    if (item == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DmeProductDetailScreen(item: item),
      ),
    );
  }

  void _onExchangeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAddress() async {
    final address = await _addressService.loadCurrentAddress();
    if (!mounted) return;
    setState(() {
      _savedAddress = address;
      _loadingAddress = false;
    });
  }

  Future<void> _loadProfileImage() async {
    final imagePath = await _profileImageService.getSavedImagePath();
    if (!mounted) return;
    setState(() => _profileImagePath = imagePath);
  }

  Future<void> _showImageSourceSheet() async {
    final loc = AppLocalizations.of(context);

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('profile.imageWebOnly'))),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        final sheetLoc = AppLocalizations.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(sheetLoc.t('profile.pickGallery')),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(sheetLoc.t('profile.pickCamera')),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null || !mounted) return;

    final savedImage = await _profileImageService.pickAndSaveImage(source);
    if (!mounted) return;

    if (savedImage == null) return;

    await _loadProfileImage();
  }

  Future<void> _logOut() async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.t('auth.logOut')),
        content: Text(loc.t('auth.logOutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.t('auth.logOut')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await AuthSessionService.instance.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.entry,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final donor = DonationService.donorProfile;
    final address = _savedAddress;
    final displayZip = address?.zipCode ?? donor.zipCode;
    final displayLocation =
        address?.shortLabel ?? loc.t('common.zipPrefix', {'zip': displayZip});
    final totalDeductions = DonationService.totalTaxDeductionsUsd;
    final donationCount = DonationService.totalDonationCount;
    final isWide = MediaQuery.sizeOf(context).width > 900;
    final avatarImage = profileAvatarImage(_profileImagePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('profile.appBarTitle')),
        actions: [
          const LanguageMenuButton(),
          IconButton(
            onPressed: _logOut,
            icon: const Icon(Icons.logout),
            tooltip: loc.t('auth.logOut'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryDeepBlue,
                          AppTheme.primaryBlue,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _showImageSourceSheet,
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white24,
                            backgroundImage: avatarImage,
                            child: avatarImage == null
                                ? const Icon(Icons.person, size: 36, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                donor.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (NgoPartnerService.instance.hasVerifiedSession ||
                                  NgoPartnerService.instance.sessionPartner !=
                                      null) ...[
                                const SizedBox(height: 8),
                                const VerifiedNgoBadge(compact: true),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                donor.email,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loc.t('profile.memberSince', {
                                  'since': donor.memberSince,
                                  'location': displayLocation,
                                }),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white60,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _showImageSourceSheet,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          child: Text(loc.t('profile.editProfile')),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: SectionHeader(
                      title: loc.t('benefits.sectionTitle'),
                      subtitle: loc.t('benefits.sectionSubtitle'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: isWide
                        ? Row(
                            children: [
                              Expanded(
                                child: _ProfileStatTile(
                                  icon: Icons.volunteer_activism_outlined,
                                  label: loc.t('profile.statTotalDonations'),
                                  value: '$donationCount',
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ProfileStatTile(
                                  icon: Icons.savings_outlined,
                                  label: loc.t('profile.statTotalDeductions'),
                                  value: formatUsd(totalDeductions),
                                  color: AppTheme.accentTeal,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ProfileStatTile(
                                  icon: Icons.receipt_long_outlined,
                                  label: loc.t('profile.statReceipts'),
                                  value: '$donationCount',
                                  color: const Color(0xFF6A1B9A),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _ProfileStatTile(
                                icon: Icons.volunteer_activism_outlined,
                                label: loc.t('profile.statTotalDonations'),
                                value: '$donationCount',
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(height: 12),
                              _ProfileStatTile(
                                icon: Icons.savings_outlined,
                                label: loc.t('profile.statTotalDeductions'),
                                value: formatUsd(totalDeductions),
                                color: AppTheme.accentTeal,
                              ),
                              const SizedBox(height: 12),
                              _ProfileStatTile(
                                icon: Icons.receipt_long_outlined,
                                label: loc.t('profile.statReceipts'),
                                value: '$donationCount',
                                color: const Color(0xFF6A1B9A),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const ImpactEsgDashboardCard(),
            const SizedBox(height: 16),
            const PassItOnEntryCard(),
            const SizedBox(height: 24),
            CorporateEsgBadgesSection(
              organizationName: donor.name,
              organizationId: 'donor-${donor.email.hashCode.abs()}',
            ),
            const SizedBox(height: 24),
            if (_loadingAddress)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_savedAddress != null)
              AddressUpdateCard(
                initialAddress: _savedAddress!,
                onSaved: (updated) => setState(() => _savedAddress = updated),
              ),
            const SizedBox(height: 24),
            const ComplianceBanner(),
            if (_exchangeService.receipts.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionHeader(
                title: loc.t('profile.exchangeReceiptsTitle'),
                subtitle: loc.t('profile.exchangeReceiptsSubtitle', {
                  'count': _exchangeService.receipts.length,
                }),
              ),
              const SizedBox(height: 16),
              ..._exchangeService.receipts.map(
                (receipt) => ExchangeReceiptCard(receipt: receipt),
              ),
            ],
            const SizedBox(height: 24),
            SectionHeader(
              title: loc.t('profile.donationHistoryTitle'),
              subtitle: loc.t('profile.donationHistorySubtitle', {
                'count': donationCount,
              }),
              action: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.file_download_outlined),
                label: Text(loc.t('profile.exportAll')),
              ),
            ),
            const SizedBox(height: 16),
            ...DonationService.donationHistory.map(
              (record) => DonationHistoryCard(record: record),
            ),
            const SizedBox(height: 16),
            InstantMatchBanner(onOpenItem: _openMatchedItem),
            const SizedBox(height: 16),
            const WishlistSectionCard(),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: Text(loc.t('profile.matchAlertsTitle')),
                    subtitle: Text(
                      loc.t('profile.matchAlertsSubtitle', {
                        'location': address?.shortLabel ??
                            loc.t('common.zipPrefix', {'zip': displayZip}),
                      }),
                    ),
                    trailing: Switch(
                      value: WishlistService.instance.alertsEnabled,
                      onChanged: WishlistService.instance.setAlertsEnabled,
                    ),
                  ),
                  const Divider(height: 1),
                  ListenableBuilder(
                    listenable: EmergencyModeService.instance,
                    builder: (context, _) {
                      return SwitchListTile(
                        secondary: Icon(
                          Icons.crisis_alert,
                          color: EmergencyModeService.instance.enabled
                              ? const Color(0xFFC62828)
                              : null,
                        ),
                        title: Text(loc.t('disaster.modeToggle')),
                        subtitle: Text(loc.t('disaster.modeHint')),
                        value: EmergencyModeService.instance.enabled,
                        onChanged: EmergencyModeService.instance.setEnabled,
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(loc.t('profile.hipaaTitle')),
                    subtitle: Text(loc.t('profile.hipaaSubtitle')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: Text(loc.t('profile.taxGuideTitle')),
                    subtitle: Text(loc.t('profile.taxGuideSubtitle')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: Text(loc.t('profile.adminInquiriesTitle')),
                    subtitle: Text(loc.t('profile.adminInquiriesSubtitle')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminInquiriesScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const DisasterReliefHubCard(),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  const _ProfileStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
