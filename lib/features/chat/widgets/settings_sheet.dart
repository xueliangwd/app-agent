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
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _platform = widget.controller.providerSettings.keys.firstOrNull ?? AiPlatform.openai;
    _hydrateForm(widget.controller.settingsFor(_platform));
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelsController.dispose();
    super.dispose();
  }

  void _hydrateForm(ProviderSettings settings) {
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _baseUrlController = TextEditingController(text: settings.baseUrl);
    _modelsController = TextEditingController(text: settings.modelsText);
  }

  void _loadPlatform(AiPlatform platform) {
    final settings = widget.controller.settingsFor(platform);
    setState(() {
      _platform = platform;
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
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final isSystem = _platform == AiPlatform.system;
    final isCustom = _platform == AiPlatform.custom;
    final settings = widget.controller.settingsFor(_platform);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 760),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFFFFCF7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          '模型设置',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '按提供方分别维护 API Key、Base URL 和模型列表，保存后会立即刷新模型选择器。',
                          style: TextStyle(color: Color(0xFF64748B), height: 1.45),
                        ),
                        const SizedBox(height: 18),
                        _StatusCard(
                          title: _platformLabel(_platform),
                          subtitle: isSystem
                              ? '系统原生 AI，不需要 API Key'
                              : (settings.isConfigured ? '已配置完成' : '尚未配置 API Key'),
                          tag: isSystem
                              ? 'Native'
                              : (settings.isConfigured ? 'Ready' : 'Pending'),
                        ),
                        const SizedBox(height: 18),
                        const _SectionTitle('提供方'),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F1E7),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: AiPlatform.values
                                .map(
                                  (platform) => _ProviderPill(
                                    label: _platformLabel(platform),
                                    selected: platform == _platform,
                                    onTap: () => _loadPlatform(platform),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!isSystem) ...[
                          const _SectionTitle('接入信息'),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _apiKeyController,
                            obscureText: _obscureApiKey,
                            decoration: InputDecoration(
                              labelText: isCustom ? 'API Key（自定义提供方）' : 'API Key',
                              hintText: isCustom ? '输入你的自定义网关密钥' : '输入密钥',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscureApiKey = !_obscureApiKey;
                                  });
                                },
                                icon: Icon(
                                  _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _baseUrlController,
                            decoration: InputDecoration(
                              labelText: isCustom ? 'Base URL（OpenAI-compatible）' : 'Base URL',
                              hintText: isCustom
                                  ? 'https://your-openai-compatible-gateway/v1'
                                  : 'https://api.example.com/v1',
                            ),
                          ),
                          const SizedBox(height: 18),
                        ] else ...[
                          const _SectionTitle('系统能力'),
                          const SizedBox(height: 10),
                          _SystemInfoCard(platform: _platform),
                          const SizedBox(height: 18),
                        ],
                        const _SectionTitle('模型列表'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _modelsController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: '模型 ID',
                            hintText: '多个模型用英文逗号分隔，例如：gpt-5.2,gpt-5-mini',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: settings.models.isEmpty
                              ? const [
                                  _HintTag('保存后会出现在模型切换列表'),
                                ]
                              : settings.models.map((model) => _HintTag(model)).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFCF7),
                    border: Border(top: BorderSide(color: Color(0xFFF1E7D8))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('保存配置'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      case AiPlatform.custom:
        return 'Custom';
      case AiPlatform.system:
        return 'System AI';
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
      ),
    );
  }
}

class _ProviderPill extends StatelessWidget {
  const _ProviderPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const themeSelected = Color(0xFF0F766E);
    final backgroundColor =
        selected ? themeSelected.withValues(alpha: 0.18) : const Color(0xFFFFFCF7);
    final borderColor =
        selected ? themeSelected : const Color(0xFFD8CDBB);
    final textColor =
        selected ? themeSelected : const Color(0xFF243431);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: borderColor,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x220F766E),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.tag,
  });

  final String title;
  final String subtitle;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF2F8F7), Color(0xFFFAF6ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF64748B), height: 1.45),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: Color(0xFF0F766E),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemInfoCard extends StatelessWidget {
  const _SystemInfoCard({required this.platform});

  final AiPlatform platform;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8DED0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System AI 不需要 API Key',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            'iOS 会优先调用 Foundation Models；Android 会调用 ML Kit GenAI Prompt API，并通过 AICore / Gemini Nano 在支持设备上执行。',
            style: TextStyle(color: Color(0xFF475569), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _HintTag extends StatelessWidget {
  const _HintTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1E7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6B5A43),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
