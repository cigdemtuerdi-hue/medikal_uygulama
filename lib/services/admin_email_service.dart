import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/contact_inquiry.dart';

class EmailDeliveryResult {
  const EmailDeliveryResult({
    required this.delivered,
    required this.note,
  });

  final bool delivered;
  final String note;
}

/// Sends Contact Us / Sponsorship form payloads to the admin mailbox.
///
/// When `ADMIN_EMAIL_ENDPOINT` is set (Formspree / webhook), a real HTTP
/// POST is made. Otherwise the notification is queued in demo mode so the
/// in-app admin panel still receives the message.
class AdminEmailService {
  AdminEmailService._();

  static final AdminEmailService instance = AdminEmailService._();

  Future<EmailDeliveryResult> sendInquiryNotification(
    ContactInquiry inquiry,
  ) async {
    final endpoint = AppConfig.adminEmailEndpoint;
    final adminEmail = AppConfig.adminNotifyEmail;

    final payload = {
      'to': adminEmail,
      'reply_to': inquiry.email,
      '_replyto': inquiry.email,
      'subject':
          '[MedGift ${inquiry.subject.label}] ${inquiry.name} · ${inquiry.id}',
      'name': inquiry.name,
      'email': inquiry.email,
      'inquiry_subject': inquiry.subject.label,
      'message': inquiry.message,
      'inquiry_id': inquiry.id,
      'submitted_at': inquiry.submittedAt.toIso8601String(),
      'body': _buildPlainBody(inquiry, adminEmail),
    };

    if (endpoint.isEmpty) {
      debugPrint(
        'ADMIN EMAIL (demo): to=$adminEmail\n${payload['body']}',
      );
      return EmailDeliveryResult(
        delivered: true,
        note: 'Queued to $adminEmail (demo mode — set ADMIN_EMAIL_ENDPOINT '
            'in .env for live delivery)',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return EmailDeliveryResult(
          delivered: true,
          note: 'Email notification sent to $adminEmail',
        );
      }

      return EmailDeliveryResult(
        delivered: false,
        note: 'Email gateway returned HTTP ${response.statusCode}',
      );
    } catch (error) {
      debugPrint('Admin email delivery failed: $error');
      return EmailDeliveryResult(
        delivered: false,
        note: 'Email delivery failed — message still saved in admin inbox',
      );
    }
  }

  String _buildPlainBody(ContactInquiry inquiry, String adminEmail) {
    return '''
New MedGift Contact Us / Sponsorship inquiry

To: $adminEmail
Reference: ${inquiry.id}
Submitted: ${inquiry.submittedAt.toIso8601String()}

Name: ${inquiry.name}
Email: ${inquiry.email}
Subject: ${inquiry.subject.label}

Message:
${inquiry.message}
''';
  }
}
