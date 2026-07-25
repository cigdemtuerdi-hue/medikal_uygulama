import 'package:flutter/foundation.dart';

import '../models/available_donation_item.dart';
import '../models/chat_models.dart';

/// In-app delivery chat. Personal contact info (phone numbers, emails,
/// street addresses) is automatically masked before a message is delivered,
/// so parties can only coordinate through the app.
class SecureChatService extends ChangeNotifier {
  SecureChatService._();

  static final SecureChatService instance = SecureChatService._();

  final Map<String, ChatConversation> _conversations = {};

  static final _phonePattern = RegExp(
    r'(\+?1[\s.-]?)?(\(?\d{3}\)?[\s.-]?)\d{3}[\s.-]?\d{4}',
  );
  static final _emailPattern = RegExp(
    r'[\w.+-]+@[\w-]+\.[\w.]+',
  );
  static final _streetAddressPattern = RegExp(
    r'\b\d{1,6}\s+(?:[A-Za-z0-9.]+\s){0,3}'
    r'(street|st|avenue|ave|road|rd|boulevard|blvd|drive|dr|lane|ln|court|ct|way|circle|cir)\.?\b',
    caseSensitive: false,
  );

  /// Returns the conversation for a reserved item, creating it (with a
  /// system welcome message) on first open.
  ChatConversation conversationFor(AvailableDonationItem item) {
    return _conversations.putIfAbsent(item.id, () {
      return ChatConversation(
        itemId: item.id,
        itemTitle: item.title,
        donorDisplayName: 'Donor (${item.donorAreaLabel})',
        recipientDisplayName: 'You',
        messages: [
          ChatMessage(
            sender: ChatSender.system,
            text: 'This chat is for coordinating pickup or delivery of '
                '"${item.title}". For your safety, personal contact details '
                '(phone, email, street address) are hidden automatically. '
                'Keep all communication in the app.',
            sentAt: DateTime.now(),
          ),
          ChatMessage(
            sender: ChatSender.donor,
            text: 'Hi! Thanks for reserving this item. When would you like '
                'to arrange the handoff? I am usually available on weekday '
                'evenings and Saturday mornings.',
            sentAt: DateTime.now(),
          ),
        ],
      );
    });
  }

  /// Masks contact info; returns the safe text and whether anything changed.
  (String, bool) sanitize(String text) {
    var redacted = false;
    var result = text;

    for (final pattern in [_phonePattern, _emailPattern, _streetAddressPattern]) {
      if (pattern.hasMatch(result)) {
        redacted = true;
        result = result.replaceAll(pattern, '[hidden for privacy]');
      }
    }
    return (result, redacted);
  }

  /// Sends a recipient message (after masking) and simulates a donor reply.
  ChatMessage sendRecipientMessage(AvailableDonationItem item, String text) {
    final conversation = conversationFor(item);
    final (safeText, redacted) = sanitize(text.trim());

    final message = ChatMessage(
      sender: ChatSender.recipient,
      text: safeText,
      sentAt: DateTime.now(),
      wasRedacted: redacted,
    );
    conversation.messages.add(message);
    notifyListeners();

    _scheduleDonorReply(conversation);
    return message;
  }

  void _scheduleDonorReply(ChatConversation conversation) {
    final replyIndex =
        conversation.messages.where((m) => m.sender == ChatSender.donor).length;
    final replies = [
      'Sounds good. I can meet at a public spot near my ZIP area — the '
          'library parking lot works well.',
      'Great, that time works for me. The item will be cleaned and ready.',
      'Perfect. See you then! You can message me here if anything changes.',
    ];
    final replyText = replies[(replyIndex - 1).clamp(0, replies.length - 1)];

    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      conversation.messages.add(
        ChatMessage(
          sender: ChatSender.donor,
          text: replyText,
          sentAt: DateTime.now(),
        ),
      );
      notifyListeners();
    });
  }
}
