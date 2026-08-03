import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localized_labels.dart';
import '../models/donation_models.dart';
import '../models/urgent_need_models.dart';
import '../models/wishlist_models.dart';
import '../services/donation_service.dart';
import '../services/listing_photo_publish_helper.dart';
import '../services/onboarding_document_service.dart';
import '../services/urgent_need_service.dart';
import '../services/wishlist_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/document_upload_card.dart';
import '../widgets/listing_photo_picker.dart';
import '../widgets/request_tracking_card.dart';
import '../widgets/urgent_need_badge.dart';
import '../widgets/urgent_required_features.dart';

/// Side-rail tab that collects every actively urgent request in one place.
class UrgentWishlistScreen extends StatefulWidget {
  const UrgentWishlistScreen({super.key});

  @override
  State<UrgentWishlistScreen> createState() => _UrgentWishlistScreenState();
}

class _UrgentWishlistScreenState extends State<UrgentWishlistScreen> {
  @override
  void initState() {
    super.initState();
    UrgentNeedService.instance.refreshExpirations();
  }

  Future<void> _showAddUrgentDialog() async {
    final loc = AppLocalizations.of(context);
    final labelController = TextEditingController();
    final featuresController = TextEditingController();
    final documentService = OnboardingDocumentService();
    DmeType? selectedType;
    String? verificationDocPath;
    String? featuresError;
    final photos = <ListingPhotoDraft>[];
    var submitting = false;

    final result = await showDialog<WishlistAddResult>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(loc.t('urgent.addDialogTitle')),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(loc.t('urgent.addDialogBody')),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<DmeType?>(
                        initialValue: selectedType,
                        decoration: InputDecoration(
                          labelText: loc.t('wishlist.categoryOptional'),
                        ),
                        items: [
                          DropdownMenuItem<DmeType?>(
                            value: null,
                            child: Text(loc.t('wishlist.customItem')),
                          ),
                          ...DmeType.values.map(
                            (type) => DropdownMenuItem<DmeType?>(
                              value: type,
                              child: Text(locDmeType(loc, type)),
                            ),
                          ),
                        ],
                        onChanged: submitting
                            ? null
                            : (value) {
                                setLocal(() {
                                  selectedType = value;
                                  if (value != null &&
                                      labelController.text.trim().isEmpty) {
                                    labelController.text =
                                        locDmeType(loc, value);
                                  }
                                });
                              },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: labelController,
                        enabled: !submitting,
                        decoration: InputDecoration(
                          labelText: loc.t('wishlist.itemLabel'),
                          hintText: loc.t('wishlist.itemHint'),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 12),
                      ListingPhotoPicker(
                        photos: photos,
                        enabled: !submitting,
                        hintKey: 'photos.requestHint',
                        onUpload: ListingPhotoPublishHelper.upload,
                        onChanged: (next) => setLocal(() {
                          photos
                            ..clear()
                            ..addAll(next);
                        }),
                      ),
                      const SizedBox(height: 16),
                      UrgentRequiredFeaturesField(
                        controller: featuresController,
                        errorText: featuresError,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loc.t('urgent.uploadHint'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      DocumentUploadCard(
                        title: loc.t('urgent.uploadTitle'),
                        subtitle: loc.t('urgent.uploadSubtitle'),
                        icon: Icons.medical_information_outlined,
                        isRequired: false,
                        isUploaded: verificationDocPath != null,
                        fileName:
                            documentService.fileLabel(verificationDocPath),
                        onPickFromGallery: () async {
                          final path = await documentService.pickDoctorReport();
                          if (path != null) {
                            setLocal(() => verificationDocPath = path);
                          }
                        },
                        onPickFromCamera: () async {
                          final path = await documentService.pickDoctorReport();
                          if (path != null) {
                            setLocal(() => verificationDocPath = path);
                          }
                        },
                        onPickFile: () async {
                          final path = await documentService.pickDoctorReport();
                          if (path != null) {
                            setLocal(() => verificationDocPath = path);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.t('urgent.expiryNote'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.deepOrange.shade800,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      submitting ? null : () => Navigator.pop(context),
                  child: Text(loc.t('common.cancel')),
                ),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (featuresController.text.trim().isEmpty) {
                            setLocal(
                              () => featuresError =
                                  loc.t('urgent.featuresRequiredError'),
                            );
                            return;
                          }
                          if (photos.any((p) => p.isPending)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.t('photos.pending'))),
                            );
                            return;
                          }
                          if (photos.any((p) => p.error != null)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.t('photos.failed'))),
                            );
                            return;
                          }
                          if (!ListingPhotoPublishHelper.hasUploadedPhoto(
                            photos,
                          )) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.t('photos.required')),
                              ),
                            );
                            return;
                          }

                          final label = labelController.text.trim().isEmpty &&
                                  selectedType != null
                              ? locDmeType(loc, selectedType!)
                              : labelController.text;
                          setLocal(() => submitting = true);

                          final apiResult =
                              await ListingPhotoPublishHelper.createIfSignedIn(
                            title: label.trim(),
                            category: selectedType?.name ?? 'other',
                            description: featuresController.text.trim(),
                            urgency: 'high',
                            photos: ListingPhotoPublishHelper.uploadedPaths(
                              photos,
                            ),
                          );

                          if (!context.mounted) return;
                          if (apiResult != null && !apiResult.success) {
                            setLocal(() => submitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(apiResult.message)),
                            );
                            return;
                          }

                          final outcome = WishlistService.instance.addEntry(
                            label: label,
                            dmeType: selectedType,
                            queryText: labelController.text,
                            isUrgentNeed: true,
                            verificationDocPath: verificationDocPath,
                            verificationDocLabel:
                                documentService.fileLabel(verificationDocPath),
                            requiredFeaturesDescription:
                                featuresController.text,
                          );
                          Navigator.pop(context, outcome);
                        },
                  child: Text(
                    submitting
                        ? loc.t('common.submitting')
                        : loc.t('urgent.addUrgentRequest'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    labelController.dispose();
    featuresController.dispose();
    if (!mounted || result == null) return;

    final message = switch (result) {
      WishlistAddResult.added => loc.t('urgent.addedSnack'),
      WishlistAddResult.duplicate => loc.t('wishlist.duplicateSnack'),
      WishlistAddResult.empty => loc.t('wishlist.emptyLabelSnack'),
      WishlistAddResult.missingFeatures =>
        loc.t('urgent.featuresRequiredError'),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('urgent.tabAppBar')),
        actions: [
          IconButton(
            tooltip: loc.t('common.refresh'),
            onPressed: () {
              UrgentNeedService.instance.refreshExpirations();
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUrgentDialog,
        icon: const Icon(Icons.priority_high),
        label: Text(loc.t('urgent.addUrgentRequest')),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: WishlistService.instance,
        builder: (context, _) {
          UrgentNeedService.instance.refreshExpirations();
          final urgentWishlist = WishlistService.instance.urgentEntries;
          final urgentPartners =
              UrgentNeedService.instance.sortedPartnerRequests(
            DonationService.openRequests.where((r) => r.isActivelyUrgent()),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: loc.t('urgent.tabTitle'),
                  subtitle: loc.t('urgent.tabSubtitle'),
                ),
                const SizedBox(height: 12),
                _UrgentSummaryStrip(
                  wishlistCount: urgentWishlist.length,
                  partnerCount: urgentPartners.length,
                ),
                const SizedBox(height: 28),
                Text(
                  loc.t('urgent.recipientSection', {
                    'count': urgentWishlist.length,
                  }),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.t('urgent.recipientSectionHint'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (urgentWishlist.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          loc.t('urgent.emptyWishlist'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  )
                else
                  ...urgentWishlist.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _UrgentWishlistRequestCard(entry: entry),
                    ),
                  ),
                const SizedBox(height: 28),
                Text(
                  loc.t('urgent.partnerSection', {
                    'count': urgentPartners.length,
                  }),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.t('urgent.partnerSectionHint'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (urgentPartners.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          loc.t('urgent.emptyPartners'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  )
                else
                  ...urgentPartners.map(
                    (request) => RequestTrackingCard(request: request),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UrgentSummaryStrip extends StatelessWidget {
  const _UrgentSummaryStrip({
    required this.wishlistCount,
    required this.partnerCount,
  });

  final int wishlistCount;
  final int partnerCount;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final total = wishlistCount + partnerCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade700,
            Colors.deepOrange.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('urgent.summaryTitle', {'count': total}),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.t('urgent.summaryBody'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 13,
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

class _UrgentWishlistRequestCard extends StatelessWidget {
  const _UrgentWishlistRequestCard({required this.entry});

  final WishlistEntry entry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final status = entry.effectiveVerificationStatus();
    final hours = entry.hoursRemaining();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.red.shade700, width: 5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.red.withValues(alpha: 0.12),
                    child: Icon(
                      entry.dmeType == DmeType.wheelchair
                          ? Icons.accessible
                          : entry.category == DonationCategory.woundCare
                              ? Icons.healing
                              : Icons.medical_services_outlined,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.displayText,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.dmeType != null
                              ? locDmeType(loc, entry.dmeType!)
                              : loc.t('wishlist.customItem'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  UrgentNeedBadge(
                    status: status,
                    compact: true,
                    showCountdownHours: hours,
                  ),
                ],
              ),
              if (entry.hasDonorRequirements) ...[
                const SizedBox(height: 14),
                UrgentDonorRequirementsPanel(
                  description: entry.requiredFeaturesDescription!,
                ),
              ],
              if (entry.verificationDocLabel != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        loc.t('urgent.proofAttached', {
                          'file': entry.verificationDocLabel!,
                        }),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              if (status == UrgentVerificationStatus.pending) ...[
                const SizedBox(height: 8),
                Text(
                  loc.t('urgent.pendingHelp'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.deepOrange.shade800,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    WishlistService.instance.removeEntry(entry.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.t('wishlist.removedSnack')),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(loc.t('wishlist.remove')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
