enum AiPlatform { openai, deepseek, doubao }

class AiModelOption {
  const AiModelOption({
    required this.platform,
    required this.id,
    required this.label,
    required this.isConfigured,
  });

  final AiPlatform platform;
  final String id;
  final String label;
  final bool isConfigured;

  String get platformLabel {
    switch (platform) {
      case AiPlatform.openai:
        return 'OpenAI';
      case AiPlatform.deepseek:
        return 'DeepSeek';
      case AiPlatform.doubao:
        return '豆包';
    }
  }

  String get displayName => '$platformLabel · $label';
}
