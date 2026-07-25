/// Data printed on a MedGift donation label (PDF with QR code).
class DonationLabelData {
  const DonationLabelData({
    required this.itemId,
    required this.title,
    required this.categoryLabel,
    required this.conditionLabel,
    required this.quantity,
    required this.donorAreaLabel,
    this.brand,
    this.model,
  });

  final String itemId;
  final String title;
  final String categoryLabel;
  final String conditionLabel;
  final int quantity;
  final String donorAreaLabel;
  final String? brand;
  final String? model;

  String get pdfFileName => 'MedGift-Label-$itemId.pdf';
}

/// A completed delivery, confirmed by scanning the label QR code.
class DeliveryConfirmation {
  const DeliveryConfirmation({
    required this.itemId,
    required this.itemTitle,
    required this.confirmedBy,
    required this.confirmedAt,
  });

  final String itemId;
  final String itemTitle;
  final String confirmedBy;
  final DateTime confirmedAt;
}
