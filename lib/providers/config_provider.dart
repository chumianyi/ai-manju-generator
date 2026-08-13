import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_config.dart';
import '../services/storage_service.dart';

class ConfigProvider extends ChangeNotifier {
  AppConfig _config = AppConfig();
  bool _loaded = false;

  AppConfig get config => _config;
  bool get loaded => _loaded;
  List<AIModelConfig> get models => _config.models;
  AIModelConfig? get languageModel => _config.languageModel;
  AIModelConfig? get videoModel => _config.videoModel;
  AIModelConfig? get imageModel => _config.imageModel;
  int get contextWindow => _config.contextWindow;
  String get defaultVideoRatio => _config.defaultVideoRatio;
  String get defaultStyle => _config.defaultStyle;

  List<AIModelConfig> get languageModels =>
      models.where((m) => m.type == '语言模型').toList();
  List<AIModelConfig> get videoModels =>
      models.where((m) => m.type == '视频模型').toList();
  List<AIModelConfig> get imageModels =>
      models.where((m) => m.type == '图片模型').toList();

  Future<void> load() async {
    _config = await StorageService.loadConfig();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    await StorageService.saveConfig(_config);
  }

  Future<void> addModel(AIModelConfig model) async {
    final newModels = [..._config.models, model];
    _config = _config.copyWith(models: newModels);
    if (model.type == '语言模型' && _config.selectedLanguageModelId == null) {
      _config = _config.copyWith(selectedLanguageModelId: model.id);
    } else if (model.type == '视频模型' &&
        _config.selectedVideoModelId == null) {
      _config = _config.copyWith(selectedVideoModelId: model.id);
    } else if (model.type == '图片模型' &&
        _config.selectedImageModelId == null) {
      _config = _config.copyWith(selectedImageModelId: model.id);
    }
    await _save();
    notifyListeners();
  }

  Future<void> updateModel(AIModelConfig model) async {
    final newModels = _config.models.map((m) {
      return m.id == model.id ? model : m;
    }).toList();
    _config = _config.copyWith(models: newModels);
    await _save();
    notifyListeners();
  }

  Future<void> deleteModel(String id) async {
    final newModels = _config.models.where((m) => m.id != id).toList();
    _config = _config.copyWith(
      models: newModels,
      selectedLanguageModelId:
          _config.selectedLanguageModelId == id ? null : _config.selectedLanguageModelId,
      selectedVideoModelId:
          _config.selectedVideoModelId == id ? null : _config.selectedVideoModelId,
      selectedImageModelId:
          _config.selectedImageModelId == id ? null : _config.selectedImageModelId,
    );
    await _save();
    notifyListeners();
  }

  Future<void> selectLanguageModel(String? id) async {
    _config = _config.copyWith(selectedLanguageModelId: id);
    await _save();
    notifyListeners();
  }

  Future<void> selectVideoModel(String? id) async {
    _config = _config.copyWith(selectedVideoModelId: id);
    await _save();
    notifyListeners();
  }

  Future<void> selectImageModel(String? id) async {
    _config = _config.copyWith(selectedImageModelId: id);
    await _save();
    notifyListeners();
  }

  Future<void> setContextWindow(int value) async {
    _config = _config.copyWith(contextWindow: value);
    await _save();
    notifyListeners();
  }

  Future<void> setDefaultVideoRatio(String ratio) async {
    _config = _config.copyWith(defaultVideoRatio: ratio);
    await _save();
    notifyListeners();
  }

  Future<void> setDefaultStyle(String style) async {
    _config = _config.copyWith(defaultStyle: style);
    await _save();
    notifyListeners();
  }

  AIModelConfig createEmptyModel(String type) {
    return AIModelConfig(
      id: const Uuid().v4(),
      name: '新${type}配置',
      type: type,
      protocol: 'OpenAI 兼容',
      baseUrl: 'https://api.openai.com/v1',
      apiKey: '',
      modelName: '',
      customHeaders: {},
      maxTokens: 4096,
      temperature: 0.7,
      isThinkingModel: false,
    );
  }
}
