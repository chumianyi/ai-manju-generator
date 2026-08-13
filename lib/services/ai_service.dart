import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_config.dart';
import '../models/chat_message.dart';
import '../models/scene.dart';

class StreamChunk {
  final String content;
  final String? thinking;
  final bool done;

  StreamChunk({required this.content, this.thinking, this.done = false});
}

class AIService {
  static const String systemPrompt = '''你是一位专业的漫画分镜编剧和视频导演。请根据用户的需求创作漫画视频脚本。

重要规则：
1. 每个镜头必须用 <镜头N>内容</镜头N> 标签包裹，N为镜头序号从1开始
2. 每个镜头内描述该镜头的画面内容、人物动作、场景氛围
3. 镜头描述要具体、有画面感，适合AI视频生成
4. 镜头之间要有连贯性，形成完整的故事
5. 如果使用思考模型，请将思考过程放在 <think></think> 标签内
6. 思考内容仅用于推理，不会出现在最终输出中
7. 回答使用中文，语言生动有感染力''';

  static Stream<StreamChunk> streamChat({
    required AIModelConfig config,
    required List<ChatMessage> history,
    required String userInput,
    void Function(String)? onThinking,
  }) {
    final controller = StreamController<StreamChunk>();

    () async {
      try {
        final messages = _buildMessages(history, userInput, config);
        final body = _buildRequestBody(config, messages);
        final headers = _buildHeaders(config);

        final uri = Uri.parse('${config.baseUrl}/chat/completions');
        final request = http.Request('POST', uri);
        request.headers.addAll(headers);
        request.body = jsonEncode(body);

        final response = await request.send();

        if (response.statusCode != 200) {
          final errorBody = await response.stream.bytesToString();
          controller.addError('API错误 ${response.statusCode}: $errorBody');
          controller.close();
          return;
        }

        String buffer = '';
        String thinkingBuffer = '';
        bool inThinking = false;
        bool thinkingStarted = false;

        await for (final chunk in response.stream.transform(utf8.decoder)) {
          buffer += chunk;
          final lines = buffer.split('\n');
          buffer = lines.removeLast();

          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) continue;
            if (!trimmed.startsWith('data:')) continue;

            final data = trimmed.substring(5).trim();
            if (data == '[DONE]') {
              controller.add(StreamChunk(content: '', done: true));
              controller.close();
              return;
            }

            try {
              final json = jsonDecode(data);
              final delta = json['choices']?[0]?['delta'];
              if (delta == null) continue;

              String? content = delta['content'] as String?;
              String? reasoning = delta['reasoning_content'] as String? ??
                  delta['thinking'] as String?;

              if (reasoning != null && reasoning.isNotEmpty) {
                if (!thinkingStarted) {
                  thinkingStarted = true;
                  inThinking = true;
                }
                if (inThinking) {
                  thinkingBuffer += reasoning;
                  onThinking?.call(thinkingBuffer);
                }
              }

              if (content != null && content.isNotEmpty) {
                if (inThinking) {
                  inThinking = false;
                }
                controller.add(StreamChunk(
                  content: content,
                  thinking: thinkingStarted ? thinkingBuffer : null,
                ));
              }
            } catch (_) {
              // 忽略解析错误
            }
          }
        }

        controller.add(StreamChunk(content: '', done: true));
        controller.close();
      } catch (e) {
        controller.addError(e.toString());
        controller.close();
      }
    }();

    return controller.stream;
  }

  static List<Map<String, String>> _buildMessages(
    List<ChatMessage> history,
    String userInput,
    AIModelConfig config,
  ) {
    final messages = <Map<String, String>>[];
    messages.add({'role': 'system', 'content': systemPrompt});

    for (final msg in history) {
      if (msg.role == MessageRole.system) continue;
      final content = msg.contentWithoutThinking;
      if (content.isEmpty) continue;
      messages.add({'role': msg.role.name, 'content': content});
    }

    messages.add({'role': 'user', 'content': userInput});
    return messages;
  }

  static Map<String, dynamic> _buildRequestBody(
    AIModelConfig config,
    List<Map<String, String>> messages,
  ) {
    return {
      'model': config.modelName,
      'messages': messages,
      'stream': true,
      'max_tokens': config.maxTokens,
      'temperature': config.temperature,
    };
  }

  static Map<String, String> _buildHeaders(AIModelConfig config) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    };
    if (config.apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }
    headers.addAll(config.customHeaders);
    return headers;
  }

  static List<Scene> extractScenes(String content, String ratio, String style) {
    final scenes = <Scene>[];
    final regex = RegExp(r'<镜头(\d+)>([\s\S]*?)</镜头\1>');
    final matches = regex.allMatches(content);

    for (final match in matches) {
      final index = int.parse(match.group(1)!);
      final prompt = match.group(2)!.trim();
      if (prompt.isNotEmpty) {
        scenes.add(Scene(
          index: index,
          prompt: prompt,
          ratio: ratio,
          style: style,
        ));
      }
    }

    if (scenes.isEmpty && content.trim().isNotEmpty) {
      scenes.add(Scene(
        index: 1,
        prompt: content.trim(),
        ratio: ratio,
        style: style,
      ));
    }

    return scenes;
  }

  static String? extractThinking(String content) {
    final regex = RegExp(r'<think>([\s\S]*?)</think>');
    final match = regex.firstMatch(content);
    return match?.group(1)?.trim();
  }

  static String removeThinkingTags(String content) {
    return content.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '').trim();
  }

  static Future<String> generateVideoPrompt({
    required AIModelConfig config,
    required String scenePrompt,
    required String style,
    required String ratio,
  }) async {
    final body = {
      'model': config.modelName,
      'prompt': '风格：$style\n比例：$ratio\n画面描述：$scenePrompt\n\n请根据以上信息生成适合AI视频生成的详细提示词，直接输出提示词内容，不要解释。',
      'max_tokens': 500,
      'temperature': 0.8,
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (config.apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }
    headers.addAll(config.customHeaders);

    try {
      final response = await http.post(
        Uri.parse('${config.baseUrl}/completions'),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['choices']?[0]?['text'] ?? scenePrompt;
      }
    } catch (_) {}
    return scenePrompt;
  }
}
