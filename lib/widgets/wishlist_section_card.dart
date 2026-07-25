import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/localized_labels.dart';
import '../models/donation_models.dart';
import '../models/wishlist_models.dart';
import '../services/onboarding_document_service.dart';
import '../services/wishlist_service.dart';
import 'document_upload_card.dart';
import 'urgent_need_badge.dart';
import 'urgent_required_features.dart';

/// Editable wishlist / "Add to Wishlist" list for Profile and Recipient screens.
class WishlistSectionCard extends StatelessWidget {
  const WishlistSectionCard({
    super.key,
    this.showAddButton = true,
  });

  final bool showAddButton;

  Future<void> _showAddDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final labelController = TextEditingController();
    final featuresController = TextEditingController();
    final documentService = OnboardingDocumentService();
    DmeType? selectedType;
    var isUrgentNeed = false;
    String? verificationDocPath;
    String? featuresError;

    final result = await showDialog<WishlistAddResult>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(loc.t('wishlist.addDialogTitle')),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(loc.t('wishlist.addDialogBody')),
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
                        onChanged: (value) {
                          setLocal(() {
                            selectedType = value;
                            if (value != null &&
                                labelController.text.trim().isEmpty) {
                              labelController.text = locDmeType(loc, value);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: labelController,
                        decoration: InputDecoration(
                          labelText: loc.t('wishlist.itemLabel'),
                          hintText: loc.t('wishlist.itemHint'),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 8),
                      UrgentNeedRequestToggle(
                        value: isUrgentNeed,
                        onChanged: (value) {
                          setLocal(() {
                            isUrgentNeed = value;
                            featuresError = null;
                            if (!value) {
                              verificationDocPath = null;
                              featuresController.clear();
                            }
                          });
                        },
                      ),
                      if (isUrgentNeed) ...[
                        const SizedBox(height: 12),
                        UrgentRequiredFeaturesField(
                          controller: featuresController,
                          errorText: featuresError,
                        ),
                        const SizedBox(height: 12),
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
                            final path =
                                await documentService.pickDoctorReport();
                            if (path != null) {
                              setLocal(() => verificationDocPath = path);
                            }
                          },
                          onPickFromCamera: () async {
                            final path =
                                await documentService.pickDoctorReport();
                            if (path != null) {
                              setLocal(() => verificationDocPath = path);
                            }
                          },
                          onPickFile: () async {
                            final path =
                                await documentService.pickDoctorReport();
                            if (path != null) {
                              setLocal(() => verificationDocPath = path);
                            }
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.t('urgent.expiryNote'),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.deepOrange.shade800,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.t('common.cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    if (isUrgentNeed &&
                        featuresController.text.trim().isEmpty) {
                      setLocal(
                        () => featuresError =
                            loc.t('urgent.featuresRequiredError'),
                      );
                      return;
                    }
                    final label = labelController.text.trim().isEmpty &&
                            selectedType != null
                        ? locDmeType(loc, selectedType!)
                        : labelController.text;
                    final outcome = WishlistService.instance.addEntry(
                      label: label,
                      dmeType: selectedType,
                      queryText: labelController.text,
                      isUrgentNeed: isUrgentNeed,
                      verificationDocPath: verificationDocPath,
                      verificationDocLabel:
                          documentService.fileLabel(verificationDocPath),
                      requiredFeaturesDescription: isUrgentNeed
                          ? featuresController.text
                          : null,
                    );
                    Navigator.pop(context, outcome);
                  },
                  child: Text(loc.t('wishlist.add')),
                ),
              ],
            );
          },
        );
      },
    );

    labelController.dispose();
    featuresController.dispose();
    if (!context.mounted || result == null) return;

    final message = switch (result) {
      WishlistAddResult.added => loc.t('wishlist.addedSnack'),
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

    return ListenableBuilder(
      listenable: WishlistService.instance,
      builder: (context, _) {
        final entries = WishlistService.instance.entries;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.t('wishlist.sectionTitle'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.t('wishlist.sectionSubtitle'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (showAddButton)
                      FilledButton.tonalIcon(
                        onPressed: () => _showAddDialog(context),
                        icon: const Icon(Icons.playlist_add),
                        label: Text(loc.t('wishlist.add')),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (entries.isEmpty)
                  Text(
                    loc.t('wishlist.empty'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  ...entries.map(
                    (entry) {
                      final status = entry.effectiveVerificationStatus();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: entry.isActivelyUrgent()
                              ? Colors.red.withValues(alpha: 0.12)
                              : Colors.blue.withValues(alpha: 0.1),
                          child: Icon(
                            entry.dmeType == DmeType.wheelchair
                                ? Icons.accessible
                                : entry.category == DonationCategory.woundCare
                                    ? Icons.healing
                                    : Icons.favorite_border,
                            color: entry.isActivelyUrgent()
                                ? Colors.red.shade700
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(child: Text(entry.displayText)),
                            if (entry.isActivelyUrgent()) ...[
                              const SizedBox(width: 8),
                              UrgentNeedBadge(
                                status: status,
                                compact: true,
                                showCountdownHours: entry.hoursRemaining(),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.dmeType != null
                                  ? locDmeType(loc, entry.dmeType!)
                                  : loc.t('wishlist.customItem'),
                            ),
                            if (entry.isActivelyUrgent() &&
                                entry.hasDonorRequirements) ...[
                              const SizedBox(height: 6),
                              UrgentDonorRequirementsPanel(
                                description:
                                    entry.requiredFeaturesDescription!,
                                compact: true,
                              ),
                            ],
                          ],
                        ),
                        isThreeLine: entry.isActivelyUrgent() &&
                            entry.hasDonorRequirements,
                        trailing: IconButton(
                          tooltip: loc.t('wishlist.remove'),
                          onPressed: () {
                            WishlistService.instance.removeEntry(entry.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.t('wishlist.removedSnack')),
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
