import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/localized_labels.dart';
import '../models/available_donation_item.dart';
import '../models/delivery_models.dart';
import '../models/donation_models.dart';
import '../models/fda_safety_models.dart';
import '../services/available_items_service.dart';
import '../services/donation_service.dart';
import '../services/fda_safety_service.dart';
import '../services/listing_photo_publish_helper.dart';
import '../services/ngo_partner_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/direct_ngo_donate_picker.dart';
import '../widgets/disaster_emergency_widgets.dart';
import '../widgets/disaster_relief_hub_card.dart';
import '../widgets/fda_safety_compliance_card.dart';
import '../widgets/fda_safety_guidelines.dart';
import '../widgets/handoff_option_badge.dart';
import '../widgets/liability_waiver_widgets.dart';
import '../widgets/listing_created_dialog.dart';
import '../widgets/listing_photo_picker.dart';
import '../widgets/urgent_need_badge.dart';
import '../widgets/urgent_required_features.dart';

class WoundCareDonateScreen extends StatefulWidget {
  const WoundCareDonateScreen({super.key});

  @override
  State<WoundCareDonateScreen> createState() => _WoundCareDonateScreenState();
}

class _WoundCareDonateScreenState extends State<WoundCareDonateScreen> {
  final _formKey = GlobalKey<FormState>();
  WoundCareType _selectedType = WoundCareType.sterileDressings;
  ItemCondition _condition = ItemCondition.excellent;
  HandoffOption _handoffOption = HandoffOption.meetupPossible;
  bool _sealedPackaging = true;
  final _zipController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _expiryController = TextEditingController();
  int _quantity = 1;
  bool _isSubmitting = false;
  bool _waiverAccepted = false;
  bool _priorityToUrgent = false;
  bool _donateToNgo = false;
  bool _allocateToDisaster = false;
  String? _selectedNgoId;
  String? _waiverError;
  final List<ListingPhotoDraft> _photos = [];
  FdaSafetyCheckResult _fdaResult = const FdaSafetyCheckResult(
    status: FdaSafetyStatus.idle,
  );
  int _fdaCheckToken = 0;

  @override
  void initState() {
    super.initState();
    _zipController.text = DonationService.donorProfile.zipCode;
    _brandController.addListener(_scheduleFdaCheck);
    _modelController.addListener(_scheduleFdaCheck);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleFdaCheck());
  }

  @override
  void dispose() {
    _brandController.removeListener(_scheduleFdaCheck);
    _modelController.removeListener(_scheduleFdaCheck);
    _zipController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  void _scheduleFdaCheck() {
    final token = ++_fdaCheckToken;
    setState(() {
      _fdaResult = const FdaSafetyCheckResult(status: FdaSafetyStatus.checking);
    });

    FdaSafetyService.instance
        .checkListing(
      brand: _brandController.text,
      model: _modelController.text,
      woundCareType: _selectedType,
    )
        .then((result) {
      if (!mounted || token != _fdaCheckToken) return;
      if (result.status == FdaSafetyStatus.checking) return;
      setState(() => _fdaResult = result);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final loc = AppLocalizations.of(context);

    if (_fdaResult.isRecall) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('fda.snackRecallBlocked')),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
      return;
    }

    if (!_waiverAccepted) {
      setState(() => _waiverError = loc.t('waiver.requiredError'));
      return;
    }
    setState(() => _waiverError = null);

    if (_photos.any((p) => p.isPending)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('photos.pending'))),
      );
      return;
    }
    if (_photos.any((p) => p.error != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('photos.failed'))),
      );
      return;
    }

    if (_fdaResult.status == FdaSafetyStatus.checking ||
        _fdaResult.status == FdaSafetyStatus.idle) {
      setState(() => _isSubmitting = true);
      final result = await FdaSafetyService.instance.checkListing(
        brand: _brandController.text,
        model: _modelController.text,
        woundCareType: _selectedType,
      );
      if (!mounted) return;
      setState(() {
        _fdaResult = result;
        _isSubmitting = false;
      });
      if (result.isRecall) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('fda.snackRecallBlocked')),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final zip = _zipController.text.trim();
    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();
    final title = locWoundCareType(loc, _selectedType);
    final description = _sealedPackaging
        ? loc.t('woundCare.defaultDescriptionSealed')
        : loc.t('woundCare.defaultDescriptionUnsealed');
    final photoPaths = ListingPhotoPublishHelper.uploadedPaths(_photos);
    final sizeNote = [
      if (brand.isNotEmpty) brand,
      if (model.isNotEmpty) model,
      if (_expiryController.text.trim().isNotEmpty)
        'exp ${_expiryController.text.trim()}',
    ].join(' · ');

    final apiResult = await ListingPhotoPublishHelper.createIfSignedIn(
      title: title,
      category: 'woundCare',
      description: description,
      condition: ListingPhotoPublishHelper.conditionKey(_condition),
      sizeNote: sizeNote.isEmpty ? null : sizeNote,
      quantity: _quantity,
      postalCode: zip,
      photos: photoPaths,
    );

    if (!mounted) return;

    if (apiResult != null && !apiResult.success) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiResult.message)),
      );
      return;
    }

    final itemId = apiResult?.data?.id ??
        'item-${DateTime.now().millisecondsSinceEpoch}';
    final ngoId = _donateToNgo
        ? (_selectedNgoId ??
            NgoPartnerService.instance.verifiedPartners.first.id)
        : null;
    final ngo = ngoId == null
        ? null
        : NgoPartnerService.instance.findById(ngoId);

    final matches = AvailableItemsService.instance.addListing(
      AvailableDonationItem(
        id: itemId,
        title: title,
        description: description,
        condition: _condition,
        donorZipCode: zip,
        brand: brand.isEmpty ? null : brand,
        model: model.isEmpty ? null : model,
        quantityAvailable: _quantity,
        handoffOption: _handoffOption,
        priorityToUrgentRequests: _priorityToUrgent,
        directNgoPartnerId: ngo?.id,
        directNgoPartnerName: ngo?.name,
        fdaSafetyVerified: true,
        disasterReliefAllocation: _allocateToDisaster,
      ),
    );

    final label = DonationLabelData(
      itemId: itemId,
      title: title,
      categoryLabel: loc.t('common.categoryWoundCare'),
      conditionLabel: locCondition(loc, _condition),
      quantity: _quantity,
      donorAreaLabel: loc.t('common.zipArea', {'zip': zip}),
    );

    _formKey.currentState!.reset();
    setState(() {
      _selectedType = WoundCareType.sterileDressings;
      _condition = ItemCondition.excellent;
      _handoffOption = HandoffOption.meetupPossible;
      _sealedPackaging = true;
      _quantity = 1;
      _waiverAccepted = false;
      _priorityToUrgent = false;
      _donateToNgo = false;
      _allocateToDisaster = false;
      _selectedNgoId = null;
      _waiverError = null;
      _photos.clear();
      _isSubmitting = false;
      _zipController.text = DonationService.donorProfile.zipCode;
      _brandController.clear();
      _modelController.clear();
      _expiryController.clear();
      _fdaResult = const FdaSafetyCheckResult(status: FdaSafetyStatus.idle);
    });
    _scheduleFdaCheck();

    await showDialog<void>(
      context: context,
      builder: (context) => ListingCreatedDialog(
        label: label,
        instantMatchCount: matches.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final recallBlocked = _fdaResult.isRecall;

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('woundCare.appBarTitle'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: loc.t('woundCare.sectionTitle'),
                subtitle: loc.t('woundCare.sectionSubtitle'),
              ),
              const SizedBox(height: 16),
              const ComplianceBanner(),
              const SizedBox(height: 16),
              const UrgentNeedsForDonorsCard(),
              const SizedBox(height: 24),
              DropdownButtonFormField<WoundCareType>(
                initialValue: _selectedType,
                decoration:
                    InputDecoration(labelText: loc.t('woundCare.supplyType')),
                items: WoundCareType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(locWoundCareType(loc, type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                    _scheduleFdaCheck();
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: InputDecoration(
                        labelText: loc.t('fda.brandLabel'),
                        hintText: loc.t('fda.brandHint'),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _modelController,
                      decoration: InputDecoration(
                        labelText: loc.t('fda.modelLabel'),
                        hintText: loc.t('fda.modelHint'),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FdaSafetyComplianceCard(result: _fdaResult),
              const FdaSafetyGuidelinesLink(),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.t('woundCare.sealedTitle')),
                subtitle: Text(loc.t('woundCare.sealedSubtitle')),
                value: _sealedPackaging,
                onChanged: (value) => setState(() => _sealedPackaging = value),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ItemCondition>(
                initialValue: _condition,
                decoration:
                    InputDecoration(labelText: loc.t('common.condition')),
                items: ItemCondition.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(locCondition(loc, c)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _condition = value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _zipController,
                      decoration: InputDecoration(
                        labelText: loc.t('common.pickupZip'),
                      ),
                      validator: (value) {
                        if (value == null || value.length != 5) {
                          return loc.t('common.zipValidation');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: InputDecoration(
                        labelText: loc.t('woundCare.expirationLabel'),
                        hintText: loc.t('woundCare.expirationHint'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: loc.t('woundCare.quantityLabel'),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: loc.t('a11y.decreaseQuantity'),
                      onPressed:
                          _quantity > 1 ? () => setState(() => _quantity--) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Semantics(
                      liveRegion: true,
                      label: loc.t('a11y.quantityValue', {
                        'count': '$_quantity',
                      }),
                      child: Text('$_quantity'),
                    ),
                    IconButton(
                      tooltip: loc.t('a11y.increaseQuantity'),
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ListingPhotoPicker(
                photos: _photos,
                enabled: !_isSubmitting,
                onUpload: ListingPhotoPublishHelper.upload,
                onChanged: (photos) => setState(() {
                  _photos
                    ..clear()
                    ..addAll(photos);
                }),
              ),
              const SizedBox(height: 24),
              HandoffOptionPicker(
                value: _handoffOption,
                onChanged: (value) => setState(() => _handoffOption = value),
              ),
              const SizedBox(height: 16),
              PriorityToUrgentToggle(
                value: _priorityToUrgent,
                onChanged: (value) =>
                    setState(() => _priorityToUrgent = value),
              ),
              const SizedBox(height: 16),
              DirectNgoDonatePicker(
                enabled: _donateToNgo,
                selectedPartnerId: _selectedNgoId,
                onEnabledChanged: (value) {
                  setState(() {
                    _donateToNgo = value;
                    if (value && _selectedNgoId == null) {
                      _selectedNgoId =
                          NgoPartnerService.instance.verifiedPartners.first.id;
                    }
                    if (!value) _selectedNgoId = null;
                  });
                },
                onPartnerChanged: (id) => setState(() => _selectedNgoId = id),
              ),
              const SizedBox(height: 16),
              DisasterReliefAllocateToggle(
                value: _allocateToDisaster,
                onChanged: (value) =>
                    setState(() => _allocateToDisaster = value),
              ),
              if (_allocateToDisaster) ...[
                const SizedBox(height: 12),
                const DisasterReliefHubCard(compact: true),
              ],
              const SizedBox(height: 24),
              LiabilityWaiverCheckbox(
                value: _waiverAccepted,
                errorText: _waiverError,
                onChanged: (value) {
                  setState(() {
                    _waiverAccepted = value ?? false;
                    if (_waiverAccepted) _waiverError = null;
                  });
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: (_isSubmitting || recallBlocked) ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.local_shipping_outlined),
                label: Text(
                  _isSubmitting
                      ? loc.t('common.submitting')
                      : loc.t('woundCare.submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
