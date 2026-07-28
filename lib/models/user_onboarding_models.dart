enum UserRole {
  donor,
  recipient,
  ngoPartner;

  String get label => switch (this) {
        UserRole.donor => 'Donor',
        UserRole.recipient => 'Recipient',
        UserRole.ngoPartner => 'Verified NGO / Non-Profit',
      };

  String get description => switch (this) {
        UserRole.donor =>
          'Donate DME & wound care supplies, receive tax receipts.',
        UserRole.recipient =>
          'Request support for the medical equipment you need.',
        UserRole.ngoPartner =>
          'Register as a Verified NGO Partner — bulk requests and warehouse intake.',
      };
}

class UserOnboardingProfile {
  const UserOnboardingProfile({
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.zipCode,
    required this.email,
    required this.phone,
    required this.idDocumentPath,
    this.city,
    this.state,
    this.doctorReportPath,
    this.conditionVideoPath,
    this.organizationName,
    this.organizationEin,
  });

  final UserRole role;
  final String firstName;
  final String lastName;
  final String zipCode;
  final String email;
  final String phone;
  final String idDocumentPath;
  final String? city;
  final String? state;
  final String? doctorReportPath;
  final String? conditionVideoPath;
  final String? organizationName;
  final String? organizationEin;

  String get fullName => '$firstName $lastName';

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  UserOnboardingProfile copyWith({
    UserRole? role,
    String? firstName,
    String? lastName,
    String? zipCode,
    String? email,
    String? phone,
    String? idDocumentPath,
    String? city,
    String? state,
    String? doctorReportPath,
    String? conditionVideoPath,
    String? organizationName,
    String? organizationEin,
  }) {
    return UserOnboardingProfile(
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      zipCode: zipCode ?? this.zipCode,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      idDocumentPath: idDocumentPath ?? this.idDocumentPath,
      city: city ?? this.city,
      state: state ?? this.state,
      doctorReportPath: doctorReportPath ?? this.doctorReportPath,
      conditionVideoPath: conditionVideoPath ?? this.conditionVideoPath,
      organizationName: organizationName ?? this.organizationName,
      organizationEin: organizationEin ?? this.organizationEin,
    );
  }

  Map<String, String> toStorageMap() {
    final map = <String, String>{
      'role': role.name,
      'firstName': firstName,
      'lastName': lastName,
      'zipCode': zipCode,
      'email': email,
      'phone': phone,
      'idDocumentPath': idDocumentPath,
    };

    if (city != null) map['city'] = city!;
    if (state != null) map['state'] = state!;
    if (doctorReportPath != null) map['doctorReportPath'] = doctorReportPath!;
    if (conditionVideoPath != null) {
      map['conditionVideoPath'] = conditionVideoPath!;
    }
    if (organizationName != null) map['organizationName'] = organizationName!;
    if (organizationEin != null) map['organizationEin'] = organizationEin!;

    return map;
  }

  factory UserOnboardingProfile.fromStorageMap(Map<String, String> map) {
    return UserOnboardingProfile(
      role: UserRole.values.byName(map['role']!),
      firstName: map['firstName']!,
      lastName: map['lastName']!,
      zipCode: map['zipCode']!,
      email: map['email']!,
      phone: map['phone']!,
      idDocumentPath: map['idDocumentPath']!,
      city: map['city'],
      state: map['state'],
      doctorReportPath: map['doctorReportPath'],
      conditionVideoPath: map['conditionVideoPath'],
      organizationName: map['organizationName'],
      organizationEin: map['organizationEin'],
    );
  }
}
