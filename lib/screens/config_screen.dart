import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_config.dart';
import '../providers/config_provider.dart';
import '../utils/constants.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConfigProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI模型配置'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '语言模型'),
            Tab(text: '视频模型'),
            Tab(text: '图片模型'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showLicenseDialog(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildModelList(provider, '语言模型', provider.languageModels,
              provider.selectedLanguageModelId, (id) => provider.selectLanguageModel(id)),
          _buildModelList(provider, '视频模型', provider.videoModels,
              provider.selectedVideoModelId, (id) => provider.selectVideoModel(id)),
          _buildModelList(provider, '图片模型', provider.imageModels,
              provider.selectedImageModelId, (id) => provider.selectImageModel(id)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final type = ['语言模型', '视频模型', '图片模型'][_tabController.index];
          _showModelEditor(context, provider, null, type);
        },
        icon: const Icon(Icons.add),
        label: const Text('添加模型'),
      ),
    );
  }

  Widget _buildModelList(
    ConfigProvider provider,
    String type,
    List<AIModelConfig> models,
    String? selectedId,
    Function(String?) onSelect,
  ) {
    if (models.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('暂无$type配置', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('点击右下角按钮添加', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: models.length,
      itemBuilder: (context, index) {
        final model = models[index];
        final isSelected = model.id == selectedId;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                _getModelIcon(type),
                color: isSelected ? Colors.white : null,
              ),
            ),
            title: Text(
              model.name,
              style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text('${model.protocol} · ${model.modelName}', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text(model.baseUrl, style: TextStyle(fontSize: 11, color: Colors.grey)),
                if (model.isThinkingModel)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.psychology, size: 12, color: Theme.of(context).colorScheme.tertiary),
                        const SizedBox(width: 4),
                        Text('思考模型', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.tertiary)),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: model.id,
                  groupValue: selectedId,
                  onChanged: onSelect,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showModelEditor(context, provider, model, type),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(context, provider, model),
                ),
              ],
            ),
            onTap: () => onSelect(model.id),
          ),
        );
      },
    );
  }

  IconData _getModelIcon(String type) {
    switch (type) {
      case '语言模型':
        return Icons.chat;
      case '视频模型':
        return Icons.videocam;
      case '图片模型':
        return Icons.image;
      default:
        return Icons.smart_toy;
    }
  }

  void _showModelEditor(
    BuildContext context,
    ConfigProvider provider,
    AIModelConfig? existing,
    String type,
  ) {
    final isEdit = existing != null;
    final model = existing ?? provider.createEmptyModel(type);

    final nameController = TextEditingController(text: model.name);
    final baseUrlController = TextEditingController(text: model.baseUrl);
    final apiKeyController = TextEditingController(text: model.apiKey);
    final modelNameController = TextEditingController(text: model.modelName);
    final maxTokensController = TextEditingController(text: '${model.maxTokens}');
    final tempController = TextEditingController(text: '${model.temperature}');

    String selectedProtocol = model.protocol;
    bool isThinkingModel = model.isThinkingModel;
    Map<String, String> headers = Map.from(model.customHeaders);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            isEdit ? '编辑模型' : '添加$type',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () {
                              final updated = AIModelConfig(
                                id: model.id,
                                name: nameController.text.trim(),
                                type: type,
                                protocol: selectedProtocol,
                                baseUrl: baseUrlController.text.trim(),
                                apiKey: apiKeyController.text.trim(),
                                modelName: modelNameController.text.trim(),
                                customHeaders: headers,
                                maxTokens: int.tryParse(maxTokensController.text) ?? 4096,
                                temperature: double.tryParse(tempController.text) ?? 0.7,
                                isThinkingModel: isThinkingModel,
                              );
                              if (isEdit) {
                                provider.updateModel(updated);
                              } else {
                                provider.addModel(updated);
                              }
                              Navigator.pop(context);
                            },
                            child: const Text('保存'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildTextField('配置名称', nameController, Icons.label),
                          const SizedBox(height: 12),
                          _buildDropdown(
                            '协议类型',
                            selectedProtocol,
                            AppConstants.aiProtocols,
                            (v) => setSheetState(() => selectedProtocol = v),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField('API Base URL', baseUrlController, Icons.link),
                          const SizedBox(height: 12),
                          _buildTextField('API Key', apiKeyController, Icons.key, obscure: true),
                          const SizedBox(height: 12),
                          _buildTextField('模型名称', modelNameController, Icons.smart_toy),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField('最大Token', maxTokensController, Icons.numbers, keyboard: TextInputType.number),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField('温度', tempController, Icons.thermostat, keyboard: const TextInputType.numberWithOptions(decimal: true)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            title: const Text('思考模型'),
                            subtitle: const Text('启用后将识别 <think></think> 标签'),
                            value: isThinkingModel,
                            onChanged: (v) => setSheetState(() => isThinkingModel = v),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 8),
                          Text('自定义请求头', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ...headers.entries.map((e) => _buildHeaderRow(e.key, e.value, headers, setSheetState)),
                          TextButton.icon(
                            onPressed: () {
                              setSheetState(() {
                                headers['Header-Name'] = 'value';
                              });
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('添加请求头'),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.protocol, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => onChanged(v ?? items.first),
    );
  }

  Widget _buildHeaderRow(String key, String value, Map<String, String> headers, StateSetter setSheetState) {
    final keyController = TextEditingController(text: key);
    final valueController = TextEditingController(text: value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: keyController,
              decoration: const InputDecoration(
                hintText: 'Header',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                headers.remove(key);
                headers[v] = valueController.text;
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: valueController,
              decoration: const InputDecoration(
                hintText: 'Value',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                headers[keyController.text] = v;
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: () => setSheetState(() => headers.remove(key)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ConfigProvider provider, AIModelConfig model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除模型「${model.name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              provider.deleteModel(model.id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('AI漫剧生成器 v1.0.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('基于 Flutter + Material 3 构建'),
              SizedBox(height: 8),
              Text('开源协议: GPL-3.0'),
              SizedBox(height: 12),
              Text('功能特性:', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('• 多协议AI模型配置\n• 流式对话输出\n• 自动分镜识别\n• 思考模型支持\n• 视频生成与合并\n• 上下文窗口最高265万'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定')),
        ],
      ),
    );
  }
}
