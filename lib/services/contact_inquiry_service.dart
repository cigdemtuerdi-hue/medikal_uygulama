import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/contact_inquiry.dart';
import 'admin_email_service.dart';

/// Dual-channel inquiry pipeline:
/// 1) Admin email notification (Formspree / webhook or demo queue)
/// 2) In-app Admin Inquiries / Messages inbox with status tracking
class ContactInquiryService extends ChangeNotifier {
  ContactInquiryService._();

  static final ContactInquiryService instance = ContactInquiryService._();

  static String get adminEmail => AppConfig.adminNotifyEmail;

  final List<ContactInquiry> _inbox = [];
  int _counter = 0;

  /// Newest first (chronological reverse — standard inbox order).
  List<ContactInquiry> get inbox => List.unmodifiable(_inbox);

  int get unreadCount =>
      _inbox.where((i) => i.status == InquiryStatus.unread).length;

  Future<ContactInquiry> submit({
    required String name,
    required String email,
    required InquirySubject subject,
    required String message,
  }) async {
    _counter++;
    final inquiry = ContactInquiry(
      id: 'INQ-${DateTime.now().year}-${_counter.toString().padLeft(4, '0')}',
      name: name.trim(),
      email: email.trim(),
      subject: subject,
      message: message.trim(),
      submittedAt: DateTime.now(),
      routedToEmail: adminEmail,
    );

    final delivery =
        await AdminEmailService.instance.sendInquiryNotification(inquiry);
    inquiry.emailDelivered = delivery.delivered;
    inquiry.emailDeliveryNote = delivery.note;

    _inbox.insert(0, inquiry);
    notifyListeners();
    return inquiry;
  }

  void markRead(String id) {
    final inquiry = _find(id);
    if (inquiry == null) return;
    if (inquiry.status == InquiryStatus.unread) {
      inquiry.status = InquiryStatus.read;
      inquiry.readAt = DateTime.now();
      notifyListeners();
    }
  }

  void markReplied(String id) {
    final inquiry = _find(id);
    if (inquiry == null) return;
    inquiry.status = InquiryStatus.replied;
    inquiry.repliedAt = DateTime.now();
    inquiry.readAt ??= inquiry.repliedAt;
    notifyListeners();
  }

  void markUnread(String id) {
    final inquiry = _find(id);
    if (inquiry == null) return;
    inquiry.status = InquiryStatus.unread;
    inquiry.readAt = null;
    inquiry.repliedAt = null;
    notifyListeners();
  }

  ContactInquiry? _find(String id) {
    for (final inquiry in _inbox) {
      if (inquiry.id == id) return inquiry;
    }
    return null;
  }
}
