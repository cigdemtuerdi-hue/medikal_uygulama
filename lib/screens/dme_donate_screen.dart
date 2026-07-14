import 'package:flutter/material.dart';

import '../models/donation_models.dart';
import '../services/donation_service.dart';
import '../widgets/common_widgets.dart';

class DmeDonateScreen extends StatefulWidget {
  const DmeDonateScreen({super.key});

  @override
  State<DmeDonateScreen> createState() => _DmeDonateScreenState();
}

class _DmeDonateScreenState extends State<DmeDonateScreen> {
  final _formKey = GlobalKey<FormState>();
  DmeType _selectedType = DmeType.wheelchair;
  ItemCondition _condition = ItemCondition.good;
  final _zipController = TextEditingController();
  final _notesController = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _zipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('DME donation draft saved. Matching with US partners...'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donate DME Equipment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Durable Medical Equipment (DME)',
                subtitle:
                    'Wheelchairs, hospital beds, oxygen devices, and other reusable medical equipment.',
              ),
              const SizedBox(height: 16),
              const ComplianceBanner(),
              const SizedBox(height: 24),
              DropdownButtonFormField<DmeType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Equipment type'),
                items: DmeType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(dmeTypeLabel(type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 16),
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
                        hintText: 'e.g. 94102',
                      ),
                      keyboardType: TextInputType.number,
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
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
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
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (model, serial, accessories)',
                  hintText: 'Include FDA label photo if available',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Submit DME Donation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
