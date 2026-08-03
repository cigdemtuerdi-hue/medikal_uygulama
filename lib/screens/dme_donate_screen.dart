import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/localized_labels.dart';
import '../models/available_donation_item.dart';
import '../models/delivery_models.dart';
import '../models/donation_models.dart';
import '../models/equipment_sizing_specs.dart';
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
import '../widgets/us_address_autocomplete_field.dart';

class DmeDonateScreen extends StatefulWidget {
  const DmeDonateScreen({super.key});

  @override
  State<DmeDonateScreen> createState() => _DmeDonateScreenState();
}

class _DmeDonateScreenState extends State<DmeDonateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  DmeType _selectedType = DmeType.wheelchair;
  ItemCondition _condition = ItemCondition.good;
  HandoffOption _handoffOption = HandoffOption.pickupOnly;
  final _zipController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _notesController = TextEditingController();
  final _seatWidthController = TextEditingController();
  final _capacityController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController();
  final _heightController = TextEditingController();
  final _seatToFloorController = TextEditingController();
  final _wheelSizeController = TextEditingController();
  final _sizingNotesController = TextEditingController();
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
    _scrollController.dispose();
    _zipController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _notesController.dispose();
    _seatWidthController.dispose();
    _capacityController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _heightController.dispose();
    _seatToFloorController.dispose();
    _wheelSizeController.dispose();
    _sizingNotesController.dispose();
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
      dmeType: _selectedType,
    )
        .then((result) {
      if (!mounted || token != _fdaCheckToken) return;
      if (result.status == FdaSafetyStatus.checking) return;
      setState(() => _fdaResult = result);
    });
  }

  double? _parseOptional(TextEditingController controller) {
    final raw = controller.text.trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  EquipmentSizingSpecs? _buildSizing() {
    final specs = EquipmentSizingSpecs(
      seatWidthInches: _parseOptional(_seatWidthController),
      weightCapacityLbs: _parseOptional(_capacityController),
      widthInches: _parseOptional(_widthController),
      depthInches: _parseOptional(_depthController),
      heightInches: _parseOptional(_heightController),
      seatToFloorInches: _parseOptional(_seatToFloorController),
      wheelSizeInches: _parseOptional(_wheelSizeController),
      notes: _sizingNotesController.text.trim().isEmpty
          ? null
          : _sizingNotesController.text.trim(),
    );
    return specs.hasAnyValue ? specs : null;
  }

  void _clearSizingFields() {
    _seatWidthController.clear();
    _capacityController.clear();
    _widthController.clear();
    _depthController.clear();
    _heightController.clear();
    _seatToFloorController.clear();
    _wheelSizeController.clear();
    _sizingNotesController.clear();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null) return;

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
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }
    setState(() => _waiverError = null);

    if (!formState.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('dme.snackInvalidZip')),
        ),
      );
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

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
    if (!ListingPhotoPublishHelper.hasUploadedPhoto(_photos)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('photos.required'))),
      );
      return;
    }

    if (_fdaResult.status == FdaSafetyStatus.checking ||
        _fdaResult.status == FdaSafetyStatus.idle) {
      setState(() => _isSubmitting = true);
      final result = await FdaSafetyService.instance.checkListing(
        brand: _brandController.text,
        model: _modelController.text,
        dmeType: _selectedType,
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
    final title = locDmeType(loc, _selectedType);
    final description = _notesController.text.trim().isEmpty
        ? loc.t('dme.defaultDescription')
        : _notesController.text.trim();
    final photoPaths = ListingPhotoPublishHelper.uploadedPaths(_photos);
    final sizing = _buildSizing();
    final sizeNote = [
      if (brand.isNotEmpty) brand,
      if (model.isNotEmpty) model,
      if (sizing?.notes != null) sizing!.notes!,
      if (sizing?.seatWidthInches != null)
        'seat ${sizing!.seatWidthInches}"',
    ].join(' · ');

    final apiResult = await ListingPhotoPublishHelper.createIfSignedIn(
      title: title,
      category: _selectedType.name,
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
        dmeType: _selectedType,
        quantityAvailable: _quantity,
        sizing: sizing,
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
      categoryLabel: loc.t('common.categoryDme'),
      conditionLabel: locCondition(loc, _condition),
      quantity: _quantity,
      donorAreaLabel: loc.t('common.zipArea', {'zip': zip}),
    );

    formState.reset();
    setState(() {
      _selectedType = DmeType.wheelchair;
      _condition = ItemCondition.good;
      _handoffOption = HandoffOption.pickupOnly;
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
      _notesController.clear();
      _clearSizingFields();
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
      appBar: AppBar(title: Text(loc.t('dme.appBarTitle'))),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: loc.t('dme.sectionTitle'),
                subtitle: loc.t('dme.sectionSubtitle'),
              ),
              const SizedBox(height: 16),
              const ComplianceBanner(),
              const SizedBox(height: 16),
              const UrgentNeedsForDonorsCard(),
              const SizedBox(height: 24),
              DropdownButtonFormField<DmeType>(
                initialValue: _selectedType,
                decoration: InputDecoration(labelText: loc.t('dme.equipmentType')),
                items: DmeType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(locDmeType(loc, type)),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
                    child: UsAddressAutocompleteField(
                      controller: _zipController,
                      labelText: loc.t('common.pickupZip'),
                      hintText: loc.t('dme.zipHint'),
                      displayZipOnlyOnSelect: true,
                      validator: (value) {
                        final zip = value?.trim() ?? '';
                        if (zip.length != 5 || int.tryParse(zip) == null) {
                          return loc.t('common.zipValidation');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.t('common.quantity'),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: loc.t('a11y.decreaseQuantity'),
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
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
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: loc.t('dme.notesLabel'),
                  hintText: loc.t('dme.notesHint'),
                ),
              ),
              const SizedBox(height: 28),
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
              const SizedBox(height: 28),
              SectionHeader(
                title: loc.t('sizing.formTitle'),
                subtitle: loc.t('sizing.formSubtitle'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _seatWidthController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.t('sizing.seatWidth'),
                        hintText: loc.t('sizing.hintInches'),
                        suffixText: loc.t('sizing.unitIn'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _capacityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.t('sizing.weightCapacity'),
                        hintText: loc.t('sizing.hintLbs'),
                        suffixText: loc.t('sizing.unitLbs'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _widthController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.t('sizing.overallWidth'),
                        suffixText: loc.t('sizing.unitIn'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _depthController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.t('sizing.overallDepth'),
                        suffixText: loc.t('sizing.unitIn'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.t('sizing.overallHeight'),
                        suffixText: loc.t('sizing.unitIn'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _seatToFloorController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.t('sizing.seatToFloor'),
                        suffixText: loc.t('sizing.unitIn'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _wheelSizeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: loc.t('sizing.wheelSize'),
                  hintText: loc.t('sizing.wheelSizeHint'),
                  suffixText: loc.t('sizing.unitIn'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sizingNotesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: loc.t('sizing.notesLabel'),
                  hintText: loc.t('sizing.notesHint'),
                ),
              ),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: FilledButton.icon(
            onPressed: (_isSubmitting || recallBlocked) ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(
              _isSubmitting
                  ? loc.t('common.submitting')
                  : loc.t('dme.submit'),
            ),
          ),
        ),
      ),
    );
  }
}
