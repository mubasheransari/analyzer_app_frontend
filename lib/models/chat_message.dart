class ChatSource {
  final String sourceType;
  final String sourceId;
  final String title;

  ChatSource({required this.sourceType, required this.sourceId, required this.title});

  factory ChatSource.fromJson(Map<String, dynamic> json) {
    return ChatSource(
      sourceType: json['source_type'] as String,
      sourceId: json['source_id'] as String,
      title: json['title'] as String,
    );
  }
}

/// A single message shown in the chat UI. `sources` and `usedLiveData` are
/// only ever set on assistant messages, populated from the backend's
/// response so the UI can show where an answer came from.
class ChatUiMessage {
  final String role; // "user" | "assistant"
  final String content;
  final List<ChatSource> sources;
  final bool usedLiveData;
  final bool isLoading;

  ChatUiMessage({
    required this.role,
    required this.content,
    this.sources = const [],
    this.usedLiveData = false,
    this.isLoading = false,
  });

  bool get isUser => role == 'user';
}
