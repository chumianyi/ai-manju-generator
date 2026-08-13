import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/config_provider.dart';
import '../utils/constants.dart';
import '../widgets/message_bubble.dart';
import '../widgets/style_selector.dart';
import 'config_screen.dart';
import 'video_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedStyle = AppConstants.videoStyles.first;
  String _selectedRatio = AppConstants.defaultVideoRatio;
  bool _showStylePanel = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ConfigProvider>();
      setState(() {
        _selectedStyle = provider.defaultStyle;
        _selectedRatio = provider.defaultVideoRatio;
      });
      context.read<ChatProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.sendMessage(text, style: _selectedStyle, ratio: _selectedRatio);
    _scrollToBottom();
  }

  void _openVideoDetail(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoDetailScreen(videoPath: path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final configProvider = context.watch<ConfigProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.movie_filter, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('AI漫剧生成器'),
          ],
        ),
        actions: [
          if (chatProvider.overallProgress > 0 && chatProvider.overallProgress < 1)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 120,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(
                        value: chatProvider.overallProgress,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(chatProvider.overallProgress * 100).toInt()}%',
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '模型配置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfigScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'clear') {
                _confirmClearChat(context);
              } else if (v == 'context') {
                _showContextSettings(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'context', child: Row(children: [Icon(Icons.memory, size: 18), SizedBox(width: 8), Text('上下文设置')])),
              const PopupMenuItem(value: 'clear', child: Row(children: [Icon(Icons.delete_outline, size: 18), SizedBox(width: 8), Text('清空对话')])),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (chatProvider.currentError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: theme.colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(Icons.error, size: 18, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatProvider.currentError!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => chatProvider.clearError(),
                  ),
                ],
              ),
            ),
          if (configProvider.languageModel == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.tertiaryContainer,
              child: Row(
                children: [
                  Icon(Icons.warning, size: 18, color: theme.colorScheme.onTertiaryContainer),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('尚未配置语言模型，请先点击右上角设置按钮进行配置')),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfigScreen())),
                    child: const Text('去配置'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: chatProvider.messages.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatProvider.messages[index];
                      return MessageBubble(
                        message: msg,
                        onGenerateVideos: () => chatProvider.generateVideosForMessage(msg.id),
                        onMergeVideos: () => chatProvider.mergeMessageVideos(msg.id),
                        onRegenerateScene: (idx) => chatProvider.regenerateScene(msg.id, idx),
                        onUpdateScene: (idx, p) => chatProvider.updateScenePrompt(msg.id, idx, p),
                        onPlayVideo: _openVideoDetail,
                      );
                    },
                  ),
          ),
          if (_showStylePanel)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: StyleSelector(
                selectedStyle: _selectedStyle,
                selectedRatio: _selectedRatio,
                onStyleChanged: (s) => setState(() => _selectedStyle = s),
                onRatioChanged: (r) => setState(() => _selectedRatio = r),
              ),
            ),
          _buildInputArea(theme, chatProvider),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_creation_outlined, size: 80, color: theme.colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text(
              'AI漫剧生成器',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '输入故事创意，AI自动生成分镜并生成视频',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('一个少女在樱花树下的邂逅'),
                _buildSuggestionChip('赛博朋克城市中的追车戏'),
                _buildSuggestionChip('古风侠客的江湖恩怨'),
                _buildSuggestionChip('未来太空站的冒险故事'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _inputController.text = text;
      },
      avatar: const Icon(Icons.auto_awesome, size: 16),
    );
  }

  Widget _buildInputArea(ThemeData theme, ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                _showStylePanel ? Icons.style : Icons.style_outlined,
                color: _showStylePanel ? theme.colorScheme.primary : null,
              ),
              tooltip: '风格设置',
              onPressed: () => setState(() => _showStylePanel = !_showStylePanel),
            ),
            Expanded(
              child: TextField(
                controller: _inputController,
                maxLines: null,
                minLines: 1,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: '输入你的漫剧创意...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  counterText: '',
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            chatProvider.isStreaming
                ? IconButton.filled(
                    icon: const Icon(Icons.stop),
                    onPressed: () => chatProvider.stopStreaming(),
                  )
                : IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: chatProvider.canGenerate ? _sendMessage : null,
                  ),
          ],
        ),
      ),
    );
  }

  void _confirmClearChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空对话'),
        content: const Text('确定要清空所有对话记录吗？此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              context.read<ChatProvider>().clearChat();
              Navigator.pop(context);
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  void _showContextSettings(BuildContext context) {
    final provider = context.read<ConfigProvider>();
    int tempValue = provider.contextWindow;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('上下文窗口设置'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('当前: ${(tempValue / 10000).toStringAsFixed(1)}万 Token'),
                Slider(
                  value: tempValue.toDouble(),
                  min: 4096,
                  max: 2650000.toDouble(),
                  divisions: 50,
                  label: '${(tempValue / 10000).toStringAsFixed(1)}万',
                  onChanged: (v) => setDialogState(() => tempValue = v.toInt()),
                ),
                const Text('最高支持 265万 Token', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
              FilledButton(
                onPressed: () {
                  provider.setContextWindow(tempValue);
                  Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }
}
