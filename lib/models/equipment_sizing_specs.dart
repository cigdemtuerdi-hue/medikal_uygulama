/// Medical-equipment sizing / technical parameters for DME listings.
class EquipmentSizingSpecs {
  const EquipmentSizingSpecs({
    this.seatWidthInches,
    this.weightCapacityLbs,
    this.widthInches,
    this.depthInches,
    this.heightInches,
    this.seatToFloorInches,
    this.wheelSizeInches,
    this.minUserHeightInches,
    this.maxUserHeightInches,
    this.notes,
  });

  /// Seat / sling width (wheelchairs, rollators with seat).
  final double? seatWidthInches;

  /// Maximum user weight capacity in pounds.
  final double? weightCapacityLbs;

  /// Overall width of the device.
  final double? widthInches;

  /// Overall depth / length of the device.
  final double? depthInches;

  /// Overall height of the device.
  final double? heightInches;

  /// Seat-to-floor height (transfer clearance).
  final double? seatToFloorInches;

  /// Rear / drive wheel diameter when applicable.
  final double? wheelSizeInches;

  /// Suggested minimum user height.
  final double? minUserHeightInches;

  /// Suggested maximum user height.
  final double? maxUserHeightInches;

  final String? notes;

  bool get hasAnyValue =>
      seatWidthInches != null ||
      weightCapacityLbs != null ||
      widthInches != null ||
      depthInches != null ||
      heightInches != null ||
      seatToFloorInches != null ||
      wheelSizeInches != null ||
      minUserHeightInches != null ||
      maxUserHeightInches != null ||
      (notes != null && notes!.trim().isNotEmpty);

  /// Rough doorway fit check: device width under a standard 32" door.
  bool? get fitsStandardDoorway {
    final width = widthInches ?? seatWidthInches;
    if (width == null) return null;
    return width <= 32;
  }
}
