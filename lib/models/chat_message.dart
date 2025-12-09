class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final double? confidence;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.confidence,
  }) : timestamp = timestamp ?? DateTime.now();
}