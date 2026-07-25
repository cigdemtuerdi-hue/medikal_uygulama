enum ChatSender { recipient, donor, system }

class ChatMessage {
  const ChatMessage({
    required this.sender,
    required this.text,
    required this.sentAt,
    this.wasRedacted = false,
  });

  final ChatSender sender;
  final String text;
  final DateTime sentAt;

  /// True if personal contact info was masked before delivery.
  final bool wasRedacted;
}

/// A delivery-coordination thread tied to a reserved item. Parties see
/// only privacy-safe display names — never emails, phones, or addresses.
class ChatConversation {
  ChatConversation({
    required this.itemId,
    required this.itemTitle,
    required this.donorDisplayName,
    required this.recipientDisplayName,
    required this.messages,
  });

  final String itemId;
  final String itemTitle;
  final String donorDisplayName;
  final String recipientDisplayName;
  final List<ChatMessage> messages;
}
