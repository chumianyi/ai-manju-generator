import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/scene.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/video_service.dart';
import '../services/merge_service.dart';
import 'config_provider.dart';

class ChatProvider extends ChangeNotifier {
  final ConfigProvider configProvider;
  List<ChatMessage> _messages = [];
  bool _isStreaming = false;
  bool _isGeneratingVideos = false;
  double _overallProgress = 0.0;
  String? _currentError;
  StreamSubscription? _streamSub;

  ChatProvider({required this.configProvider});

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isStreaming => _isStreaming;
  bool get isGeneratingVideos => _isGeneratingVideos;
  double get overallProgress => _overallProgress;
  String? get currentError => _currentError;
  bool get canGenerate =>
      configProvider.languageModel != null &&
      configProvider.videoModel != null &&
      !_isStreaming &&
      !_isGeneratingVideos;

  Future<void> loadHistory() async {
    _messages = await StorageService.loadChat();
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    await StorageService.saveChat(_messages);
  }

  Future<void> clearChat() async {
    _messages.clear();
    await StorageService.clearChat();
    notifyListeners();
  }

  Future<void> sendMessage(String input, {String? style, String? ratio}) async {
    if (_isStreaming || _isGeneratingVideos) return;
    if (configProvider.languageModel == null) {
      _currentError = '请先配置语言模型';
      notifyListeners();
      return;
    }

    _currentError = null;
    final selectedStyle = style ?? configProvider.defaultStyle;
    final selectedRatio = ratio ?? configProvider.defaultVideoRatio;

    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      role: MessageRole.user,
      content: input,
    );
    _messages.add(userMsg);

    final assistantMsg = ChatMessage(
      id: const Uuid().v4(),
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
      style: selectedStyle,
    );
    _messages.add(assistantMsg);

    _isStreaming = true;
    _overallProgress = 0.0;
    notifyListeners();

    final lmConfig = configProvider.languageModel!;
    String thinkingContent = '';

    try {
      final stream = AIService.streamChat(
        config: lmConfig,
        history: _messages.where((m) => m.id != assistantMsg.id).toList(),
        userInput: input,
        onThinking: (t) {
          thinkingContent = t;
          assistantMsg.thinking = t;
          notifyListeners();
        },
      );

      await for (final chunk in stream) {
        if (chunk.thinking != null && chunk.thinking!.isNotEmpty) {
          thinkingContent = chunk.thinking!;
          assistantMsg.thinking = thinkingContent;
        }
        if (chunk.content.isNotEmpty) {
          assistantMsg.content += chunk.content;
          notifyListeners();
        }
        if (chunk.done) break;
      }

      assistantMsg.isStreaming = false;

      final scenes = AIService.extractScenes(
        assistantMsg.content,
        selectedRatio,
        selectedStyle,
      );
      assistantMsg.scenes.clear();
      assistantMsg.scenes.addAll(scenes);

      await _saveHistory();
      notifyListeners();
    } catch (e) {
      _currentError = e.toString();
      assistantMsg.isStreaming = false;
      assistantMsg.content += '\n\n[错误] $e';
      notifyListeners();
    } finally {
      _isStreaming = false;
      notifyListeners();
    }
  }

  Future<void> generateVideosForMessage(String messageId) async {
    if (_isGeneratingVideos) return;
    if (configProvider.videoModel == null) {
      _currentError = '请先配置视频模型';
      notifyListeners();
      return;
    }

    final msgIndex = _messages.indexWhere((m) => m.id == messageId);
    if (msgIndex < 0) return;
    final msg = _messages[msgIndex];
    if (msg.scenes.isEmpty) return;

    _isGeneratingVideos = true;
    _overallProgress = 0.0;
    _currentError = null;
    notifyListeners();

    final vmConfig = configProvider.videoModel!;
    int completed = 0;
    int total = msg.scenes.length;

    for (int i = 0; i < msg.scenes.length; i++) {
      final scene = msg.scenes[i];
      if (scene.status == SceneStatus.completed) {
        completed++;
        continue;
      }

      scene.status = SceneStatus.generating;
      notifyListeners();

      try {
        final videoPath = await VideoService.generateVideo(
          config: vmConfig,
          scene: scene,
          onProgress: (p) {
            final baseProgress = completed / total;
            final sceneProgress = p / total;
            _overallProgress = baseProgress + sceneProgress;
            notifyListeners();
          },
        );
        scene.videoPath = videoPath;
        scene.status = SceneStatus.completed;
        completed++;
      } catch (e) {
        scene.status = SceneStatus.failed;
        scene.error = e.toString();
        _currentError = '镜头${scene.index}生成失败: $e';
      }

      _overallProgress = completed / total;
      await _saveHistory();
      notifyListeners();
    }

    _isGeneratingVideos = false;
    _overallProgress = 1.0;
    notifyListeners();
  }

  Future<void> regenerateScene(String messageId, int sceneIndex) async {
    if (_isGeneratingVideos) return;
    if (configProvider.videoModel == null) return;

    final msg = _messages.firstWhere((m) => m.id == messageId);
    final scene = msg.scenes.firstWhere((s) => s.index == sceneIndex);
    scene.status = SceneStatus.generating;
    scene.error = null;
    notifyListeners();

    try {
      final videoPath = await VideoService.generateVideo(
        config: configProvider.videoModel!,
        scene: scene,
        onProgress: (p) {},
      );
      scene.videoPath = videoPath;
      scene.status = SceneStatus.completed;
    } catch (e) {
      scene.status = SceneStatus.failed;
      scene.error = e.toString();
    }
    await _saveHistory();
    notifyListeners();
  }

  void updateScenePrompt(String messageId, int sceneIndex, String newPrompt) {
    final msg = _messages.firstWhere((m) => m.id == messageId);
    final scene = msg.scenes.firstWhere((s) => s.index == sceneIndex);
    scene.prompt = newPrompt;
    notifyListeners();
  }

  Future<String?> mergeMessageVideos(String messageId) async {
    final msg = _messages.firstWhere((m) => m.id == messageId);
    final completedScenes =
        msg.scenes.where((s) => s.status == SceneStatus.completed && s.videoPath != null).toList();
    if (completedScenes.isEmpty) return null;

    completedScenes.sort((a, b) => a.index.compareTo(b.index));
    final paths = completedScenes.map((s) => s.videoPath!).toList();

    try {
      final mergedPath = await MergeService.mergeVideos(paths);
      msg.videoPath = mergedPath;
      await _saveHistory();
      notifyListeners();
      return mergedPath;
    } catch (e) {
      _currentError = '合并失败: $e';
      notifyListeners();
      return null;
    }
  }

  void stopStreaming() {
    _streamSub?.cancel();
    _isStreaming = false;
    for (final msg in _messages) {
      if (msg.isStreaming) {
        msg.isStreaming = false;
      }
    }
    notifyListeners();
  }

  void clearError() {
    _currentError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
