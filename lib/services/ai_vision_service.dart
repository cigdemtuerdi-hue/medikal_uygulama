import 'dart:typed_data';

import '../models/donation_models.dart';

/// Simulates OpenAI GPT-4o Vision responses for the web MVP.
/// Replace with a real API call when backend credentials are available.
class AiVisionService {
  static const _analysisDelay = Duration(milliseconds: 2400);

  Future<AiVisionResult> analyzeImage(Uint8List imageBytes, String fileName) async {
    await Future<void>.delayed(_analysisDelay);

    final lowerName = fileName.toLowerCase();
    final catalog = _catalogByPreset.values.toList();

    for (final entry in _keywordPresetMap.entries) {
      if (lowerName.contains(entry.key)) {
        return _catalogByPreset[entry.value]!;
      }
    }

    final index = imageBytes.length % catalog.length;
    return catalog[index];
  }

  Future<AiVisionResult> analyzePreset(AiScanPreset preset) async {
    await Future<void>.delayed(_analysisDelay);
    return _catalogByPreset[preset]!;
  }

  String presetLabel(AiScanPreset preset) {
    return switch (preset) {
      AiScanPreset.invacareWheelchair => 'Invacare Wheelchair',
      AiScanPreset.driveRollator => 'Drive Rollator Walker',
      AiScanPreset.woundDressingKit => '3M Wound Dressing Kit',
      AiScanPreset.oxygenConcentrator => 'Philips Oxygen Concentrator',
    };
  }

  static const _keywordPresetMap = {
    'wheel': AiScanPreset.invacareWheelchair,
    'chair': AiScanPreset.invacareWheelchair,
    'walker': AiScanPreset.driveRollator,
    'rollator': AiScanPreset.driveRollator,
    'bandage': AiScanPreset.woundDressingKit,
    'gauze': AiScanPreset.woundDressingKit,
    'dressing': AiScanPreset.woundDressingKit,
    'tegaderm': AiScanPreset.woundDressingKit,
    'oxygen': AiScanPreset.oxygenConcentrator,
    'concentrator': AiScanPreset.oxygenConcentrator,
    'respironics': AiScanPreset.oxygenConcentrator,
  };

  static const _catalogByPreset = {
    AiScanPreset.invacareWheelchair: AiVisionResult(
      brand: 'Invacare',
      model: 'Tracer SX5',
      productName: 'Manual Transport Wheelchair',
      category: 'DME · Mobility Equipment',
      estimatedRetailValueUsd: 1850,
      suggestedCondition: ItemCondition.good,
      confidence: 0.94,
      fdaNote:
          'FDA Class I device. Confirm brake function, upholstery integrity, and tire condition before donation.',
      recommendation:
          'High-match item for rural health alliances and veterans care programs.',
      isDme: true,
      taxDeductionNote:
          'IRS Publication 561: deduct fair market value of used DME in good condition. Keep this scan receipt with your donation record.',
    ),
    AiScanPreset.driveRollator: AiVisionResult(
      brand: 'Drive Medical',
      model: 'Nitro Euro Style',
      productName: '4-Wheel Rollator Walker with Seat',
      category: 'DME · Mobility Equipment',
      estimatedRetailValueUsd: 329.99,
      suggestedCondition: ItemCondition.good,
      confidence: 0.92,
      fdaNote:
          'Inspect hand brakes, wheel bearings, and folding mechanism. Missing accessories reduce fair market value.',
      recommendation:
          'Eligible for nonprofit pickup within 50-mile radius of donor ZIP code.',
      isDme: true,
      taxDeductionNote:
          'Estimated retail value reflects current US marketplace pricing for comparable used units.',
    ),
    AiScanPreset.woundDressingKit: AiVisionResult(
      brand: '3M',
      model: 'Tegaderm + Kerlix Combo Pack',
      productName: 'Sterile Wound Dressing Assortment',
      category: 'Wound Care · Consumable Supplies',
      estimatedRetailValueUsd: 89.50,
      suggestedCondition: ItemCondition.excellent,
      confidence: 0.89,
      fdaNote:
          'Donate only unopened, sterile packaging within expiration date per USP <797> guidance.',
      recommendation:
          'Route to community wound clinics and disaster relief partners accepting sealed supplies.',
      isDme: false,
      taxDeductionNote:
          'Consumable medical supplies qualify when donated to 501(c)(3) organizations; retain purchase receipt if available.',
    ),
    AiScanPreset.oxygenConcentrator: AiVisionResult(
      brand: 'Philips Respironics',
      model: 'EverFlo Q',
      productName: 'Home Oxygen Concentrator (5 LPM)',
      category: 'DME · Respiratory Equipment',
      estimatedRetailValueUsd: 1249,
      suggestedCondition: ItemCondition.good,
      confidence: 0.91,
      fdaNote:
          'FDA Class II device. Verify flow rate accuracy, filter status, and hours meter reading.',
      recommendation:
          'Priority match for disaster relief and home health nonprofits with licensed technicians.',
      isDme: true,
      taxDeductionNote:
          'High-value DME donations may require written appraisal above IRS thresholds; consult your tax advisor.',
    ),
  };
}

String formatUsd(double value) {
  return '\$${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)}';
}
