import '../models/donation_models.dart';
import '../models/fda_safety_models.dart';

/// Simulated FDA recall lookup for MedGift listing safety checks.
class FdaSafetyService {
  FdaSafetyService._();

  static final FdaSafetyService instance = FdaSafetyService._();

  /// Demo recall list — enter these brand/model values to trigger a block.
  static const List<FdaRecallNotice> activeRecalls = [
    FdaRecallNotice(
      brand: 'Acme Med',
      model: 'RecallChair 2000',
      recallId: 'FDA-RES-2024-1187',
      summary:
          'Class I recall: frame weld failure risk during transfer. Do not redistribute.',
    ),
    FdaRecallNotice(
      brand: 'Philips Respironics',
      model: 'DreamStation',
      recallId: 'FDA-RES-2021-0451',
      summary:
          'Class I recall: PE-PUR foam degradation may release particulates.',
    ),
    FdaRecallNotice(
      brand: 'SafePath',
      model: 'NebulaX Pro',
      recallId: 'FDA-RES-2023-0092',
      summary:
          'Class II recall: overheating reported on continuous duty cycles.',
    ),
  ];

  int _generation = 0;

  /// Fast background simulation. Cancels superseded in-flight checks via generation.
  Future<FdaSafetyCheckResult> checkListing({
    required String? brand,
    required String? model,
    DmeType? dmeType,
    WoundCareType? woundCareType,
  }) async {
    final gen = ++_generation;
    final brandTrim = brand?.trim() ?? '';
    final modelTrim = model?.trim() ?? '';

    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (gen != _generation) {
      return const FdaSafetyCheckResult(status: FdaSafetyStatus.checking);
    }

    final recall = _matchRecall(brandTrim, modelTrim);
    if (recall != null) {
      return FdaSafetyCheckResult(
        status: FdaSafetyStatus.recall,
        recall: recall,
        checkedLabel: '${recall.brand} ${recall.model}',
      );
    }

    final categoryLabel = dmeType?.name ?? woundCareType?.name ?? 'item';
    final label = [
      if (brandTrim.isNotEmpty) brandTrim,
      if (modelTrim.isNotEmpty) modelTrim,
      if (brandTrim.isEmpty && modelTrim.isEmpty) categoryLabel,
    ].join(' ');

    return FdaSafetyCheckResult(
      status: FdaSafetyStatus.verified,
      checkedLabel: label,
    );
  }

  FdaRecallNotice? _matchRecall(String brand, String model) {
    if (brand.isEmpty && model.isEmpty) return null;
    final b = brand.toLowerCase();
    final m = model.toLowerCase();

    for (final notice in activeRecalls) {
      final nb = notice.brand.toLowerCase();
      final nm = notice.model.toLowerCase();
      final brandOk = b.isEmpty || nb.contains(b) || b.contains(nb);
      final modelOk = m.isEmpty || nm.contains(m) || m.contains(nm);
      // Require model match when model provided; brand+model when both provided.
      if (m.isNotEmpty && modelOk && (b.isEmpty || brandOk)) {
        return notice;
      }
      if (m.isEmpty && b.isNotEmpty && brandOk && nb == b) {
        // Brand-only exact match against a single-brand recall entry is too broad;
        // only flag when brand uniquely identifies a recall model string in input.
        continue;
      }
    }
    return null;
  }
}
