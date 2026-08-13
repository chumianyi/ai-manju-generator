import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scene.dart';

class SceneEditor extends StatefulWidget {
  final List<Scene> scenes;
  final VoidCallback? onGenerate;
  final VoidCallback? onMerge;
  final Function(int)? onRegenerate;
  final Function(int, String)? onUpdate;
  final Function(String)? onPlay;
  final bool isGenerating;

  const SceneEditor({
    super.key,
    required this.scenes,
    this.onGenerate,
    this.onMerge,
    this.onRegenerate,
    this.onUpdate,
    this.onPlay,
    this.isGenerating = false,
  });

  @override
  State<SceneEditor> createState() => _SceneEditorState();
}

class _SceneEditorState extends State<SceneEditor> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount =
        widget.scenes.where((s) => s.status == SceneStatus.completed).length;
    final hasCompleted = completedCount > 0;
    final allCompleted = completedCount == widget.scenes.length;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.movie_creation, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '分镜列表 (${widget.scenes.length})',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$completedCount/${widget.scenes.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, size: 20),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  ...widget.scenes.map((scene) => _buildSceneItem(scene, theme)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: widget.isGenerating ? null : widget.onGenerate,
                          icon: widget.isGenerating
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.videocam, size: 18),
                          label: Text(widget.isGenerating ? '生成中...' : '生成全部视频'),
                        ),
                      ),
                      if (allCompleted) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onMerge,
                            icon: const Icon(Icons.merge, size: 18),
                            label: const Text('合并保存'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSceneItem(Scene scene, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getStatusColor(scene.status, theme),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${scene.index}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '镜头 ${scene.index}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                scene.ratio,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                scene.style,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            scene.prompt,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          if (scene.status == SceneStatus.failed && scene.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                scene.error!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          if (scene.videoPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  if (File(scene.videoPath!).existsSync())
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 80,
                        height: 45,
                        color: Colors.black,
                        child: const Icon(Icons.play_arrow, color: Colors.white),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => widget.onPlay?.call(scene.videoPath!),
                      icon: const Icon(Icons.play_circle, size: 16),
                      label: const Text('预览'),
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onRegenerate?.call(scene.index),
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: '重新生成',
                  ),
                ],
              ),
            ),
          if (scene.status == SceneStatus.failed)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => widget.onRegenerate?.call(scene.index),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('重试'),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(SceneStatus status, ThemeData theme) {
    switch (status) {
      case SceneStatus.pending:
        return theme.colorScheme.outline;
      case SceneStatus.generating:
        return theme.colorScheme.primary;
      case SceneStatus.completed:
        return Colors.green;
      case SceneStatus.failed:
        return theme.colorScheme.error;
    }
  }
}
