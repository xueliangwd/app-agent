import 'package:flutter/material.dart';

import '../../../core/models/ai_provider.dart';
import '../../../core/models/provider_settings.dart';
import '../data/settings_controller.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late AiPlatform _platform;
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _modelsController;

  @override
  void initState() {
    super.initState();
    _platform = widget.controller.providerSettings.keys.firstOrNull ?? AiPlatform.openai;
    final settings = widget.controller.settingsFor(_platform);
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _baseUrlController = TextEditingController(text: settings.baseUrl);
    _modelsController = TextEditingController(text: settings.modelsText);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelsController.dispose();
    super.dispose();
  }

  void _loadPlatform(AiPlatform platform) {
    setState(() {
      _platform = platform;
      final settings = widget.controller.settingsFor(platform);
      _apiKeyController.text = settings.apiKey;
      _baseUrlController.text = settings.baseUrl;
      _modelsController.text = settings.modelsText;
    });
  }

  Future<void> _save() async {
    await widget.controller.updateProviderSettings(
      ProviderSettings(
        platform: _platform,
        apiKey: _apiKeyController.text.trim(),
        baseUrl: _baseUrlController.text.trim(),
        modelsText: _modelsController.text.trim(),
      ),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('模型设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SegmentedButton<AiPlatform>(
              segments: AiPlatform.values
                  .map(
                    (platform) => ButtonSegment<AiPlatform>(
                      value: platform,
                      label: Text(_platformLabel(platform)),
                    ),
                  )
                  .toList(),
              selected: {_platform},
              onSelectionChanged: (selection) => _loadPlatform(selection.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'API Key'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(labelText: 'Base URL'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '模型列表',
                hintText: '多个模型用英文逗号分隔',
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '修改后会本地保存，并即时刷新模型切换列表。',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _platformLabel(AiPlatform platform) {
    switch (platform) {
      case AiPlatform.openai:
        return 'OpenAI';
      case AiPlatform.deepseek:
        return 'DeepSeek';
      case AiPlatform.doubao:
        return '豆包';
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
