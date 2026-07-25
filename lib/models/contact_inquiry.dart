enum InquirySubject { sponsorship, partnership, general }

enum InquiryStatus { unread, read, replied }

extension InquirySubjectLabel on InquirySubject {
  String get label => switch (this) {
        InquirySubject.sponsorship => 'Sponsorship',
        InquirySubject.partnership => 'Partnership',
        InquirySubject.general => 'General',
      };
}

extension InquiryStatusLabel on InquiryStatus {
  String get label => switch (this) {
        InquiryStatus.unread => 'Unread',
        InquiryStatus.read => 'Read',
        InquiryStatus.replied => 'Replied',
      };
}

/// A sponsorship / partnership inquiry submitted from the landing footer.
class ContactInquiry {
  ContactInquiry({
    required this.id,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.submittedAt,
    this.routedToEmail = 'partnerships@medgift.us',
    this.status = InquiryStatus.unread,
    this.readAt,
    this.repliedAt,
    this.emailDelivered = false,
    this.emailDeliveryNote,
  });

  final String id;
  final String name;
  final String email;
  final InquirySubject subject;
  final String message;
  final DateTime submittedAt;
  final String routedToEmail;

  InquiryStatus status;
  DateTime? readAt;
  DateTime? repliedAt;

  /// True when the admin email notification was accepted by the mail gateway.
  bool emailDelivered;
  String? emailDeliveryNote;
}
