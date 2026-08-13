import 'dart:convert';

class AIModelConfig {
  final String id;
  final String name;
  final String type;
  final String protocol;
  final String baseUrl;
  final String apiKey;
  final String modelName;
  final Map<String, String> customHeaders;
  final int maxTokens;
  final double temperature;
  final bool isThinkingModel;

  AIModelConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.protocol,
    required this.baseUrl,
    required this.apiKey,
    required this.modelName,
    this.customHeaders = const {},
    this.maxTokens = 4096,
    this.temperature = 0.7,
    this.isThinkingModel = false,
  });

  AIModelConfig copyWith({
    String? id,
    String? name,
    String? type,
    String? protocol,
    String? baseUrl,
    String? apiKey,
    String? modelName,
    Map<String, String>? customHeaders,
    int? maxTokens,
    double? temperature,
    bool? isThinkingModel,
  }) {
    return AIModelConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      protocol: protocol ?? this.protocol,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
      customHeaders: customHeaders ?? this.customHeaders,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      isThinkingModel: isThinkingModel ?? this.isThinkingModel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'protocol': protocol,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'modelName': modelName,
      'customHeaders': customHeaders,
      'maxTokens': maxTokens,
      'temperature': temperature,
      'isThinkingModel': isThinkingModel,
    };
  }

  factory AIModelConfig.fromMap(Map<String, dynamic> map) {
    return AIModelConfig(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      protocol: map['protocol'] as String,
      baseUrl: map['baseUrl'] as String,
      apiKey: map['apiKey'] as String,
      modelName: map['modelName'] as String,
      customHeaders: Map<String, String>.from(map['customHeaders'] ?? {}),
      maxTokens: map['maxTokens'] as int? ?? 4096,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
      isThinkingModel: map['isThinkingModel'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AIModelConfig.fromJson(String source) =>
      AIModelConfig.fromMap(jsonDecode(source));
}

class AppConfig {
  final List<AIModelConfig> models;
  final String? selectedLanguageModelId;
  final String? selectedVideoModelId;
  final String? selectedImageModelId;
  final int contextWindow;
  final String defaultVideoRatio;
  final String defaultStyle;

  AppConfig({
    this.models = const [],
    this.selectedLanguageModelId,
    this.selectedVideoModelId,
    this.selectedImageModelId,
    this.contextWindow = 128000,
    this.defaultVideoRatio = '9:16',
    this.defaultStyle = '日漫风格',
  });

  AppConfig copyWith({
    List<AIModelConfig>? models,
    String? selectedLanguageModelId,
    String? selectedVideoModelId,
    String? selectedImageModelId,
    int? contextWindow,
    String? defaultVideoRatio,
    String? defaultStyle,
  }) {
    return AppConfig(
      models: models ?? this.models,
      selectedLanguageModelId:
          selectedLanguageModelId ?? this.selectedLanguageModelId,
      selectedVideoModelId: selectedVideoModelId ?? this.selectedVideoModelId,
      selectedImageModelId: selectedImageModelId ?? this.selectedImageModelId,
      contextWindow: contextWindow ?? this.contextWindow,
      defaultVideoRatio: defaultVideoRatio ?? this.defaultVideoRatio,
      defaultStyle: defaultStyle ?? this.defaultStyle,
    );
  }

  AIModelConfig? get languageModel {
    if (selectedLanguageModelId == null) return null;
    try {
      return models.firstWhere((m) => m.id == selectedLanguageModelId);
    } catch (_) {
      return null;
    }
  }

  AIModelConfig? get videoModel {
    if (selectedVideoModelId == null) return null;
    try {
      return models.firstWhere((m) => m.id == selectedVideoModelId);
    } catch (_) {
      return null;
    }
  }

  AIModelConfig? get imageModel {
    if (selectedImageModelId == null) return null;
    try {
      return models.firstWhere((m) => m.id == selectedImageModelId);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'models': models.map((m) => m.toMap()).toList(),
      'selectedLanguageModelId': selectedLanguageModelId,
      'selectedVideoModelId': selectedVideoModelId,
      'selectedImageModelId': selectedImageModelId,
      'contextWindow': contextWindow,
      'defaultVideoRatio': defaultVideoRatio,
      'defaultStyle': defaultStyle,
    };
  }

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      models: (map['models'] as List?)
              ?.map((m) => AIModelConfig.fromMap(Map<String, dynamic>.from(m)))
              .toList() ??
          [],
      selectedLanguageModelId: map['selectedLanguageModelId'],
      selectedVideoModelId: map['selectedVideoModelId'],
      selectedImageModelId: map['selectedImageModelId'],
      contextWindow: map['contextWindow'] as int? ?? 128000,
      defaultVideoRatio: map['defaultVideoRatio'] as String? ?? '9:16',
      defaultStyle: map['defaultStyle'] as String? ?? '日漫风格',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppConfig.fromJson(String source) =>
      AppConfig.fromMap(jsonDecode(source));
}
