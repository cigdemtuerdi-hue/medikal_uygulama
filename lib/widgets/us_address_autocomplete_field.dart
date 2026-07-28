import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/address_search_result.dart';
import '../models/us_address_models.dart';
import '../services/address_autocomplete_service.dart';

class UsAddressAutocompleteField extends StatefulWidget {
  const UsAddressAutocompleteField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.onAddressSelected,
    this.onManualFallback,
    this.displayZipOnlyOnSelect = false,
  });

  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final ValueChanged<UsAddressSuggestion>? onAddressSelected;
  final VoidCallback? onManualFallback;
  final bool displayZipOnlyOnSelect;

  @override
  State<UsAddressAutocompleteField> createState() =>
      _UsAddressAutocompleteFieldState();
}

class _UsAddressAutocompleteFieldState extends State<UsAddressAutocompleteField> {
  bool _manualFallback = false;

  void _activateManualFallback() {
    if (_manualFallback) return;
    setState(() => _manualFallback = true);
    widget.onManualFallback?.call();
    _showManualFallbackMessage();
  }

  void _showManualFallbackMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AddressAutocompleteMessages.apiUnavailable),
      ),
    );
  }

  Future<List<UsAddressSuggestion>> _fetchSuggestions(String pattern) async {
    final trimmed = pattern.trim();
    if (trimmed.isEmpty) return const [];

    // ZIP-first: Geocoding returns a concrete city/state row that Places
    // Autocomplete often omits for bare 5-digit postal codes.
    if (trimmed.length == 5 && int.tryParse(trimmed) != null) {
      final zipMatch =
          await AddressAutocompleteService.instance.findByZip(trimmed);
      if (zipMatch != null) {
        return [zipMatch];
      }
    }

    final result = await AddressAutocompleteService.instance.search(trimmed);
    if (result.manualFallback) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _activateManualFallback();
      });
      return const [];
    }
    return result.suggestions;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller.text,
      validator: widget.validator,
      builder: (field) {
        if (_manualFallback) {
          return TextFormField(
            controller: widget.controller,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.edit_location_alt_outlined),
              helperText: AddressAutocompleteMessages.apiUnavailable,
              errorText: field.errorText,
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: field.didChange,
          );
        }

        return TypeAheadField<UsAddressSuggestion>(
          controller: widget.controller,
          debounceDuration: const Duration(milliseconds: 250),
          hideOnEmpty: false,
          hideOnLoading: false,
          suggestionsCallback: _fetchSuggestions,
          onSelected: (suggestion) async {
            final resolved =
                await AddressAutocompleteService.instance.resolve(suggestion);
            if (!mounted) return;

            if (resolved == null) {
              _activateManualFallback();
              return;
            }

            final displayText = widget.displayZipOnlyOnSelect
                ? (resolved.zipCode.isNotEmpty
                    ? resolved.zipCode
                    : resolved.primaryLine)
                : resolved.primaryLine;
            widget.controller.text = displayText;
            field.didChange(displayText);
            widget.onAddressSelected?.call(resolved);
          },
          builder: (context, textController, focusNode) {
            return TextField(
              controller: textController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.labelText,
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.location_on_outlined),
                errorText: field.errorText,
              ),
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.streetAddress,
              onChanged: field.didChange,
            );
          },
          itemBuilder: (context, suggestion) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.skyBlue.withValues(alpha: 0.45),
                child: const Icon(
                  Icons.place_outlined,
                  color: AppTheme.primaryDeepBlue,
                  size: 20,
                ),
              ),
              title: Text(
                suggestion.primaryLine,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(suggestion.secondaryLine),
            );
          },
          loadingBuilder: (context) => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          emptyBuilder: (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(AppLocalizations.of(context).t('empty.addressTitle')),
          ),
          errorBuilder: (context, error) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _activateManualFallback();
            });
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text(AddressAutocompleteMessages.apiUnavailable),
            );
          },
        );
      },
    );
  }
}
