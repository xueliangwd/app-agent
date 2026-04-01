enum AiPlatform { openai, deepseek, doubao, custom, system }

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
      case AiPlatform.custom:
        return 'Custom';
      case AiPlatform.system:
        return 'System AI';
    }
  }

  String get displayName => '$platformLabel · $label';

  bool sameIdentity(AiModelOption? other) {
    if (other == null) {
      return false;
    }
    return platform == other.platform && id == other.id;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AiModelOption && sameIdentity(other);
  }

  @override
  int get hashCode => Object.hash(platform, id);
}
