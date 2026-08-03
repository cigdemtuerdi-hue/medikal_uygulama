import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/address_autocomplete_service.dart';

/// City / state / ZIP row for listing forms.
///
/// Typing a valid 5-digit ZIP auto-fills city and state via the offline catalog
/// + Zippopotam (no Google Places overlay required — works inside bottom sheets).
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
  String? _lookupHint;
  int _lookupGen = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onZipChanged(String value) {
    final zip = value.trim();
    _debounce?.cancel();
    if (zip.length != 5 || int.tryParse(zip) == null) {
      setState(() {
        _lookingUp = false;
        _lookupHint = null;
      });
      return;
    }

    setState(() {
      _lookingUp = true;
      _lookupHint = null;
    });
    final gen = ++_lookupGen;
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      final match =
          await AddressAutocompleteService.instance.findByZip(zip);
      if (!mounted || gen != _lookupGen) return;
      if (match == null) {
        setState(() {
          _lookingUp = false;
          _lookupHint = 'empty.addressTitle';
        });
        return;
      }
      widget.cityController.text = match.city;
      widget.stateController.text = match.state;
      setState(() {
        _lookingUp = false;
        _lookupHint = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: widget.postalController,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: InputDecoration(
                  labelText: widget.zipLabel ?? loc.t('shop.zipLabel'),
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
            ),
          ],
        ),
        if (_lookupHint != null) ...[
          const SizedBox(height: 6),
          Text(
            loc.t(_lookupHint!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
