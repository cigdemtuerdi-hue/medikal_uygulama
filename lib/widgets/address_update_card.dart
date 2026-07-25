import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/profile_address.dart';
import '../models/us_address_models.dart';
import '../services/profile_address_service.dart';
import '../widgets/us_address_autocomplete_field.dart';

class AddressUpdateCard extends StatefulWidget {
  const AddressUpdateCard({
    super.key,
    required this.initialAddress,
    required this.onSaved,
  });

  final ProfileAddress initialAddress;
  final ValueChanged<ProfileAddress> onSaved;

  @override
  State<AddressUpdateCard> createState() => _AddressUpdateCardState();
}

class _AddressUpdateCardState extends State<AddressUpdateCard> {
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _addressService = ProfileAddressService.instance;

  ProfileAddress? _draft;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _applyAddress(widget.initialAddress);
  }

  @override
  void didUpdateWidget(covariant AddressUpdateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAddress != widget.initialAddress) {
      _applyAddress(widget.initialAddress);
    }
  }

  void _applyAddress(ProfileAddress address) {
    _draft = address;
    _addressController.text = address.formattedAddress;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  String _localizedRole(AppLocalizations loc, String roleLabel) {
    return roleLabel.toLowerCase() == 'recipient'
        ? loc.t('address.roleRecipient')
        : loc.t('address.roleDonor');
  }

  Future<void> _saveAddress() async {
    final loc = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    final draft = _draft;
    if (draft == null || draft.zipCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('address.snackInvalid'))),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _addressService.saveAddress(draft);
      if (!mounted) return;
      widget.onSaved(draft);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('address.snackSaved', {'zip': draft.zipCode})),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onAddressSelected(UsAddressSuggestion suggestion) {
    setState(() {
      _draft = _addressService.fromSuggestion(
        suggestion,
        roleLabel: widget.initialAddress.roleLabel,
        name: widget.initialAddress.name,
      );
    });
  }

  String? _validateAddress(String? value) {
    final loc = AppLocalizations.of(context);
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return loc.t('address.validationEmpty');
    }

    final zipOnly = RegExp(r'^\d{5}$');
    if (zipOnly.hasMatch(trimmed)) return null;
    if (trimmed.length < 5) {
      return loc.t('address.validationShort');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final draft = _draft ?? widget.initialAddress;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_location_alt_outlined,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.t('address.cardTitle'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          loc.t('address.cardSubtitle', {
                            'role': _localizedRole(loc, draft.roleLabel),
                          }),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              UsAddressAutocompleteField(
                controller: _addressController,
                labelText: loc.t('address.fieldLabel'),
                hintText: loc.t('address.fieldHint'),
                validator: _validateAddress,
                onAddressSelected: _onAddressSelected,
                onManualFallback: () {
                  final text = _addressController.text.trim();
                  if (RegExp(r'^\d{5}$').hasMatch(text)) {
                    setState(() {
                      _draft = widget.initialAddress.copyWith(
                        zipCode: text,
                        fullAddressLine: null,
                        streetAddress: null,
                      );
                    });
                  }
                },
              ),
              if (!AppConfig.hasGoogleMapsApiKey) ...[
                const SizedBox(height: 8),
                Text(
                  AppConfig.missingApiKeyMessage,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.orange.shade800,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.skyBlue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.pin_drop_outlined, color: AppTheme.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.t('address.currentLocation'),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            draft.shortLabel,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (draft.streetAddress != null &&
                              draft.streetAddress!.isNotEmpty)
                            Text(
                              draft.streetAddress!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveAddress,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving ? loc.t('common.saving') : loc.t('address.save'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
