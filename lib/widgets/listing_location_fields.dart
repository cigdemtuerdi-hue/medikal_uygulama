import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/address_autocomplete_service.dart';

/// Location row for listing forms: ZIP first, then auto-filled city/state.
///
/// Typing a valid 5-digit ZIP resolves city + state via offline catalog,
/// MedGift `/api/geo/zip`, then Zippopotam — no Google Places overlay needed
/// (works inside modal bottom sheets).
class ListingLocationFields extends StatefulWidget {
  const ListingLocationFields({
    super.key,
    required this.cityController,
    required this.stateController,
    required this.postalController,
    this.enabled = true,
    this.cityLabel,
    this.stateLabel,
    this.zipLabel,
  });

  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController postalController;
  final bool enabled;
  final String? cityLabel;
  final String? stateLabel;
  final String? zipLabel;

  @override
  State<ListingLocationFields> createState() => _ListingLocationFieldsState();
}

class _ListingLocationFieldsState extends State<ListingLocationFields> {
  Timer? _debounce;
  bool _lookingUp = false;
  String? _resolvedLabel;
  String? _errorKey;
  int _lookupGen = 0;

  @override
  void initState() {
    super.initState();
    widget.postalController.addListener(_onPostalControllerTick);
    final existing = widget.postalController.text.trim();
    if (existing.length == 5) {
      _lookupZip(existing);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.postalController.removeListener(_onPostalControllerTick);
    super.dispose();
  }

  void _onPostalControllerTick() {
    // Also catch paste / autofill that may not fire [onChanged] the same way.
    final zip = widget.postalController.text.trim();
    if (zip.length == 5 && int.tryParse(zip) != null) {
      _scheduleLookup(zip);
    }
  }

  void _scheduleLookup(String zip) {
    _debounce?.cancel();
    setState(() {
      _lookingUp = true;
      _errorKey = null;
    });
    final gen = ++_lookupGen;
    _debounce = Timer(const Duration(milliseconds: 150), () {
      _lookupZip(zip, gen: gen);
    });
  }

  Future<void> _lookupZip(String zip, {int? gen}) async {
    final token = gen ?? ++_lookupGen;
    final match = await AddressAutocompleteService.instance.findByZip(zip);
    if (!mounted || token != _lookupGen) return;
    if (match == null) {
      setState(() {
        _lookingUp = false;
        _resolvedLabel = null;
        _errorKey = 'empty.addressTitle';
      });
      return;
    }

    _setControllerText(widget.cityController, match.city);
    _setControllerText(widget.stateController, match.state);
    setState(() {
      _lookingUp = false;
      _errorKey = null;
      _resolvedLabel = '${match.city}, ${match.state} ${match.zipCode}';
    });
  }

  void _setControllerText(TextEditingController controller, String text) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onZipChanged(String value) {
    final zip = value.trim();
    if (zip.length != 5 || int.tryParse(zip) == null) {
      _debounce?.cancel();
      setState(() {
        _lookingUp = false;
        _resolvedLabel = null;
        _errorKey = null;
      });
      return;
    }
    _scheduleLookup(zip);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.postalController,
          enabled: widget.enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          decoration: InputDecoration(
            labelText: widget.zipLabel ?? loc.t('shop.zipLabel'),
            hintText: '92606',
            border: const OutlineInputBorder(),
            suffixIcon: _lookingUp
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.location_on_outlined),
          ),
          onChanged: _onZipChanged,
        ),
        if (_resolvedLabel != null) ...[
          const SizedBox(height: 8),
          Material(
            color: AppTheme.skyBlue.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.primaryDeepBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _resolvedLabel!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDeepBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_errorKey != null) ...[
          const SizedBox(height: 6),
          Text(
            loc.t(_errorKey!),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: widget.cityController,
                enabled: widget.enabled,
                decoration: InputDecoration(
                  labelText: widget.cityLabel ?? loc.t('shop.cityLabel'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.stateController,
                enabled: widget.enabled,
                maxLength: 2,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: InputDecoration(
                  labelText: widget.stateLabel ?? loc.t('shop.stateLabel'),
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
