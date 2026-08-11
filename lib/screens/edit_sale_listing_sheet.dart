import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/listing.dart';
import '../services/listing_api_service.dart';
import '../widgets/listing_location_fields.dart';
import '../widgets/listing_photo_picker.dart';

const _categoryKeys = <String>[
  'wheelchair',
  'walker',
  'hospitalBed',
  'oxygenEquipment',
  'nebulizer',
  'commode',
  'showerChair',
  'woundCare',
  'other',
];

const _conditionKeys = <String>['new', 'likeNew', 'good', 'fair'];
const _commissionRate = 0.17;

/// Owner edit form for a sale listing (returns updated [Listing] on save).
class EditSaleListingSheet extends StatefulWidget {
  const EditSaleListingSheet({super.key, required this.listing});

  final Listing listing;

  @override
  State<EditSaleListingSheet> createState() => _EditSaleListingSheetState();
}

class _EditSaleListingSheetState extends State<EditSaleListingSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _sizeNote;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _postal;
  late final TextEditingController _price;

  late String _category;
  String? _condition;
  late List<String> _existingPhotos;
  final _newPhotos = <ListingPhotoDraft>[];
  bool _submitting = false;
  bool _loadingExisting = true;

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    _title = TextEditingController(text: listing.title);
    _description = TextEditingController(text: listing.description);
    _sizeNote = TextEditingController(text: listing.sizeNote ?? '');
    _city = TextEditingController(text: listing.city ?? '');
    _state = TextEditingController(text: listing.state ?? '');
    _postal = TextEditingController(text: listing.postalCode ?? '');
    final cents = listing.priceCents;
    _price = TextEditingController(
      text: cents == null ? '' : (cents / 100).toStringAsFixed(2),
    );
    _category = _categoryKeys.contains(listing.category)
        ? listing.category
        : _categoryKeys.first;
    _condition = listing.condition;
    if (_condition != null && !_conditionKeys.contains(_condition)) {
      _condition = 'good';
    }
    _existingPhotos = List<String>.from(listing.displayPhotos);
    _hydrateExistingPhotoBytes();
  }

  Future<void> _hydrateExistingPhotoBytes() async {
    // Existing paths stay as remote URLs; picker only manages new uploads.
    if (mounted) setState(() => _loadingExisting = false);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _sizeNote.dispose();
    _city.dispose();
    _state.dispose();
    _postal.dispose();
    _price.dispose();
    super.dispose();
  }

  int? get _priceCents {
    final raw = _price.text.trim().replaceAll(',', '');
    if (raw.isEmpty) return null;
    final dollars = double.tryParse(raw);
    if (dollars == null || dollars < 1) return null;
    return (dollars * 100).round();
  }

  Future<String> _uploadPhoto(ListingPhotoDraft draft) async {
    final result = await ListingApiService.instance.uploadPhoto(
      bytes: draft.bytes,
      contentType: draft.contentType,
    );
    final path = result.data;
    if (!result.success || path == null) throw Exception(result.message);
    return path;
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);
    if (_title.text.trim().isEmpty) {
      _notify(loc.t('shop.titleRequired'));
      return;
    }
    final cents = _priceCents;
    if (cents == null) {
      _notify(loc.t('shop.priceRequired'));
      return;
    }
    if (_newPhotos.any((p) => p.isPending)) {
      _notify(loc.t('shop.photosPending'));
      return;
    }
    if (_newPhotos.any((p) => p.error != null)) {
      _notify(loc.t('shop.photosFailed'));
      return;
    }

    final photos = <String>[
      ..._existingPhotos,
      for (final photo in _newPhotos)
        if (photo.uploadedPath != null) photo.uploadedPath!,
    ];
    if (photos.isEmpty) {
      _notify(loc.t('photos.required'));
      return;
    }

    setState(() => _submitting = true);
    final result = await ListingApiService.instance.updateListing(
      widget.listing.id,
      title: _title.text.trim(),
      category: _category,
      description: _description.text.trim(),
      condition: _condition,
      sizeNote: _sizeNote.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      postalCode: _postal.text.trim(),
      priceCents: cents,
      photos: photos,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!result.success || result.data == null) {
      _notify(result.message);
      return;
    }
    Navigator.of(context).pop(result.data);
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _categoryLabel(AppLocalizations loc, String key) {
    if (key == 'woundCare') return loc.t('shop.category.woundCare');
    if (key == 'other') return loc.t('dme.type.other');
    return loc.t('dme.type.$key');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final cents = _priceCents;
    final commission =
        cents == null ? null : (cents * _commissionRate).round();
    final net = cents == null || commission == null ? null : cents - commission;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.t('shop.editListing'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(loc.t('shop.editSubtitle'), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text(
              loc.t('photos.title'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (_loadingExisting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (_existingPhotos.isNotEmpty)
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingPhotos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final path = _existingPhotos[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              ListingApiService.instance.photoUrlFor(path),
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => ColoredBox(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: const SizedBox(
                                  width: 88,
                                  height: 88,
                                  child: Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Material(
                              color: Colors.black54,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => setState(
                                  () => _existingPhotos.removeAt(index),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              if (_existingPhotos.length < 5) ...[
                const SizedBox(height: 8),
                ListingPhotoPicker(
                  photos: _newPhotos,
                  onChanged: (next) => setState(() {
                    _newPhotos
                      ..clear()
                      ..addAll(next);
                  }),
                  onUpload: _uploadPhoto,
                  maxPhotos: 5 - _existingPhotos.length,
                  enabled: !_submitting,
                ),
              ],
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: loc.t('shop.titleLabel')),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _category,
              decoration:
                  InputDecoration(labelText: loc.t('shop.categoryLabel')),
              items: [
                for (final key in _categoryKeys)
                  DropdownMenuItem(
                    value: key,
                    child: Text(_categoryLabel(loc, key)),
                  ),
              ],
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value != null) setState(() => _category = value);
                    },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _condition,
              decoration:
                  InputDecoration(labelText: loc.t('shop.conditionLabel')),
              items: [
                for (final key in _conditionKeys)
                  DropdownMenuItem(
                    value: key,
                    child: Text(loc.t('shop.condition.$key')),
                  ),
              ],
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _condition = value),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _price,
              decoration:
                  InputDecoration(labelText: loc.t('shop.priceLabel')),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: (_) => setState(() {}),
            ),
            if (cents != null && commission != null && net != null) ...[
              const SizedBox(height: 8),
              Text(
                loc.t('shop.commissionNetLine', {
                  'commission': formatUsdCents(commission),
                  'net': formatUsdCents(net),
                }),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _sizeNote,
              decoration: InputDecoration(labelText: loc.t('shop.sizeLabel')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              decoration:
                  InputDecoration(labelText: loc.t('shop.descriptionLabel')),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 10),
            ListingLocationFields(
              cityController: _city,
              stateController: _state,
              postalController: _postal,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(loc.t('shop.saveEdits')),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
