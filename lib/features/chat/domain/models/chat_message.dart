class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isTyping = false,
    this.imagePath,
  });

  final String text;
  final bool isUser;
  final bool isTyping;
  final String? imagePath;
}
