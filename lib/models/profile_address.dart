class ProfileAddress {
  const ProfileAddress({
    required this.roleLabel,
    required this.zipCode,
    this.city,
    this.state,
    this.name,
    this.streetAddress,
    this.fullAddressLine,
  });

  final String roleLabel;
  final String zipCode;
  final String? city;
  final String? state;
  final String? name;
  final String? streetAddress;
  final String? fullAddressLine;

  String get formattedAddress {
    if (fullAddressLine != null && fullAddressLine!.isNotEmpty) {
      return fullAddressLine!;
    }
    if (streetAddress != null && streetAddress!.isNotEmpty) {
      final parts = <String>[
        streetAddress!,
        if (city != null && city!.isNotEmpty) city!,
        if (state != null && state!.isNotEmpty) state!,
        zipCode,
        'USA',
      ];
      return parts.join(', ');
    }
    final parts = <String>[
      if (city != null && city!.isNotEmpty) city!,
      if (state != null && state!.isNotEmpty) state!,
      zipCode,
      'USA',
    ];
    return parts.join(', ');
  }

  String get shortLabel {
    if (city != null && state != null && city!.isNotEmpty && state!.isNotEmpty) {
      return '$city, $state $zipCode';
    }
    return zipCode;
  }

  /// ZIP-level address used for privacy-safe donor geocoding.
  String get zipOnlyAddress => '$zipCode, USA';

  ProfileAddress copyWith({
    String? roleLabel,
    String? zipCode,
    String? city,
    String? state,
    String? name,
    String? streetAddress,
    String? fullAddressLine,
  }) {
    return ProfileAddress(
      roleLabel: roleLabel ?? this.roleLabel,
      zipCode: zipCode ?? this.zipCode,
      city: city ?? this.city,
      state: state ?? this.state,
      name: name ?? this.name,
      streetAddress: streetAddress ?? this.streetAddress,
      fullAddressLine: fullAddressLine ?? this.fullAddressLine,
    );
  }

  Map<String, String> toStorageMap() {
    final map = <String, String>{
      'zipCode': zipCode,
    };
    if (city != null) map['city'] = city!;
    if (state != null) map['state'] = state!;
    if (streetAddress != null) map['streetAddress'] = streetAddress!;
    if (fullAddressLine != null) map['fullAddressLine'] = fullAddressLine!;
    if (name != null) map['name'] = name!;
    return map;
  }

  factory ProfileAddress.fromStorageMap(
    Map<String, String> map, {
    required String roleLabel,
  }) {
    return ProfileAddress(
      roleLabel: roleLabel,
      zipCode: map['zipCode'] ?? '',
      city: map['city'],
      state: map['state'],
      name: map['name'],
      streetAddress: map['streetAddress'],
      fullAddressLine: map['fullAddressLine'],
    );
  }
}
