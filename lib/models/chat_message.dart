enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final MessageRole role;
  String content;
  final String? thinking;
  final List<Scene> scenes;
  final DateTime timestamp;
  final bool isStreaming;
  final String? videoPath;
  final String? style;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.thinking,
    this.scenes = const [],
    DateTime? timestamp,
    this.isStreaming = false,
    this.videoPath,
    this.style,
  }) : timestamp = timestamp ?? DateTime.now();

  String get contentWithoutThinking {
    if (thinking == null || thinking!.isEmpty) return content;
    return content.replaceAll('<think>$thinking</think>', '').trim();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'thinking': thinking,
      'scenes': scenes.map((s) => s.toMap()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'videoPath': videoPath,
      'style': style,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => MessageRole.user,
      ),
      content: map['content'] as String,
      thinking: map['thinking'] as String?,
      scenes: (map['scenes'] as List?)
              ?.map((s) => Scene.fromMap(Map<String, dynamic>.from(s)))
              .toList() ??
          [],
      timestamp: DateTime.parse(map['timestamp'] as String),
      videoPath: map['videoPath'] as String?,
      style: map['style'] as String?,
    );
  }
}
