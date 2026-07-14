import 'package:flutter/material.dart';

import '../models/donation_models.dart';
import '../services/donation_service.dart';
import '../widgets/common_widgets.dart';

class WoundCareDonateScreen extends StatefulWidget {
  const WoundCareDonateScreen({super.key});

  @override
  State<WoundCareDonateScreen> createState() => _WoundCareDonateScreenState();
}

class _WoundCareDonateScreenState extends State<WoundCareDonateScreen> {
  final _formKey = GlobalKey<FormState>();
  WoundCareType _selectedType = WoundCareType.sterileDressings;
  ItemCondition _condition = ItemCondition.excellent;
  bool _sealedPackaging = true;
  final _zipController = TextEditingController();
  final _expiryController = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _zipController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wound care donation draft saved for clinic matching.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donate Wound Care Supplies')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Wound Care & Dressings',
                subtitle:
                    'Sterile bandages, gauze, compression wraps, and cleansers for US clinics.',
              ),
              const SizedBox(height: 16),
              const ComplianceBanner(),
              const SizedBox(height: 24),
              DropdownButtonFormField<WoundCareType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Supply type'),
                items: WoundCareType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(woundCareTypeLabel(type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Unopened / sealed packaging'),
                subtitle: const Text('Required for most wound care donations'),
                value: _sealedPackaging,
                onChanged: (value) => setState(() => _sealedPackaging = value),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ItemCondition>(
                initialValue: _condition,
                decoration: const InputDecoration(labelText: 'Condition'),
                items: ItemCondition.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(conditionLabel(c)),
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
                      decoration: const InputDecoration(
                        labelText: 'Pickup ZIP code',
                      ),
                      validator: (value) {
                        if (value == null || value.length != 5) {
                          return 'Enter a valid 5-digit US ZIP code';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: const InputDecoration(
                        labelText: 'Expiration (MM/YYYY)',
                        hintText: '12/2027',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Quantity (boxes/packs)'),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text('$_quantity'),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Submit Wound Care Donation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
