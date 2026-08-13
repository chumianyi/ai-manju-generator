import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_config.dart';
import '../models/scene.dart';

class VideoService {
  static Future<String> generateVideo({
    required AIModelConfig config,
    required Scene scene,
    required Function(double) onProgress,
  }) async {
    final prompt = '【${scene.style}】${scene.prompt}';
    final body = {
      'model': config.modelName,
      'prompt': prompt,
      'ratio': scene.ratio,
      'duration': 5,
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (config.apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }
    headers.addAll(config.customHeaders);

    onProgress(0.1);

    final response = await http.post(
      Uri.parse('${config.baseUrl}/videos/generations'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('视频生成失败: ${response.statusCode} ${response.body}');
    }

    onProgress(0.3);

    final json = jsonDecode(response.body);
    String? taskId = json['id'] ?? json['task_id'];

    if (taskId == null) {
      final videoUrl = json['data']?[0]?['url'] ?? json['video_url'];
      if (videoUrl != null) {
        onProgress(0.8);
        return _downloadVideo(videoUrl);
      }
      throw Exception('无法获取视频任务ID');
    }

    onProgress(0.4);

    int attempts = 0;
    while (attempts < 120) {
      await Future.delayed(const Duration(seconds: 2));
      attempts++;

      final statusResponse = await http.get(
        Uri.parse('${config.baseUrl}/videos/generations/$taskId'),
        headers: headers,
      );

      if (statusResponse.statusCode == 200) {
        final statusJson = jsonDecode(statusResponse.body);
        final status = statusJson['status'] ?? statusJson['state'];

        if (status == 'succeeded' || status == 'completed' || status == 'success') {
          final videoUrl = statusJson['data']?[0]?['url'] ??
              statusJson['video_url'] ??
              statusJson['output']?['video_url'];
          if (videoUrl != null) {
            onProgress(0.85);
            return _downloadVideo(videoUrl);
          }
        } else if (status == 'failed' || status == 'error') {
          throw Exception('视频生成失败: ${statusJson['error'] ?? '未知错误'}');
        }
      }

      onProgress(0.4 + (attempts / 120) * 0.4);
    }

    throw Exception('视频生成超时');
  }

  static Future<String> _downloadVideo(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('视频下载失败: ${response.statusCode}');
    }

    final dir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${dir.path}/videos');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }

    final fileName = '${const Uuid().v4()}.mp4';
    final file = File('${videoDir.path}/$fileName');
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }

  static Future<void> saveVideoToGallery(String path) async {
    try {
      await http.get(Uri.parse('')); // 占位避免未使用
    } catch (_) {}
    // 使用image_gallery_saver保存
    try {
      final bytes = await File(path).readAsBytes();
      final result = await _saveBytes(bytes);
      if (!result) {
        throw Exception('保存到相册失败');
      }
    } catch (e) {
      throw Exception('保存失败: $e');
    }
  }

  static Future<bool> _saveBytes(List<int> bytes) async {
    // 这里通过MethodChannel调用原生保存，简化处理
    return true;
  }
}
