import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';
import '../models/scene.dart';
import 'scene_editor.dart';
import 'think_panel.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onGenerateVideos;
  final VoidCallback? onMergeVideos;
  final Function(int)? onRegenerateScene;
  final Function(int, String)? onUpdateScene;
  final Function(String)? onPlayVideo;

  const MessageBubble({
    super.key,
    required this.message,
    this.onGenerateVideos,
    this.onMergeVideos,
    this.onRegenerateScene,
    this.onUpdateScene,
    this.onPlayVideo,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.thinking != null && message.thinking!.isNotEmpty)
              ThinkPanel(thinking: message.thinking!),
            if (message.content.isNotEmpty)
              MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: theme.textTheme.bodyMedium,
                  h1: theme.textTheme.headlineSmall,
                  h2: theme.textTheme.titleLarge,
                  h3: theme.textTheme.titleMedium,
                  code: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    backgroundColor: theme.colorScheme.surface,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            if (message.isStreaming)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text('生成中...', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            if (message.scenes.isNotEmpty)
              SceneEditor(
                scenes: message.scenes,
                onGenerate: onGenerateVideos,
                onMerge: onMergeVideos,
                onRegenerate: onRegenerateScene,
                onUpdate: onUpdateScene,
                onPlay: onPlayVideo,
                isGenerating: false,
              ),
            if (message.videoPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Icon(Icons.movie, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '已合并完整视频',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => onPlayVideo?.call(message.videoPath!),
                      icon: const Icon(Icons.play_circle, size: 18),
                      label: const Text('播放'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
