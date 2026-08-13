enum SceneStatus { pending, generating, completed, failed }

class Scene {
  final int index;
  String prompt;
  String? videoPath;
  SceneStatus status;
  String? error;
  final String ratio;
  final String style;

  Scene({
    required this.index,
    required this.prompt,
    this.videoPath,
    this.status = SceneStatus.pending,
    this.error,
    this.ratio = '9:16',
    this.style = '日漫风格',
  });

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'prompt': prompt,
      'videoPath': videoPath,
      'status': status.name,
      'error': error,
      'ratio': ratio,
      'style': style,
    };
  }

  factory Scene.fromMap(Map<String, dynamic> map) {
    return Scene(
      index: map['index'] as int,
      prompt: map['prompt'] as String,
      videoPath: map['videoPath'] as String?,
      status: SceneStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SceneStatus.pending,
      ),
      error: map['error'] as String?,
      ratio: map['ratio'] as String? ?? '9:16',
      style: map['style'] as String? ?? '日漫风格',
    );
  }

  Scene copyWith({
    int? index,
    String? prompt,
    String? videoPath,
    SceneStatus? status,
    String? error,
    String? ratio,
    String? style,
  }) {
    return Scene(
      index: index ?? this.index,
      prompt: prompt ?? this.prompt,
      videoPath: videoPath ?? this.videoPath,
      status: status ?? this.status,
      error: error ?? this.error,
      ratio: ratio ?? this.ratio,
      style: style ?? this.style,
    );
  }
}
