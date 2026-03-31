import '../core/models/ai_provider.dart';

class LlmConfig {
  const LlmConfig._();

  static const openAIApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const openAIBaseUrl = String.fromEnvironment(
    'OPENAI_BASE_URL',
    defaultValue: 'https://api.openai.com/v1',
  );
  static const openAIModels = String.fromEnvironment(
    'OPENAI_MODELS',
    defaultValue: 'gpt-5.2',
  );

  static const deepSeekApiKey = String.fromEnvironment('DEEPSEEK_API_KEY');
  static const deepSeekBaseUrl = String.fromEnvironment(
    'DEEPSEEK_BASE_URL',
    defaultValue: 'https://api.deepseek.com',
  );
  static const deepSeekModels = String.fromEnvironment(
    'DEEPSEEK_MODELS',
    defaultValue: 'deepseek-chat,deepseek-reasoner',
  );

  static const _doubaoApiKeyPrimary = String.fromEnvironment('DOUBAO_API_KEY');
  static const _doubaoApiKeySecondary = String.fromEnvironment('ARK_API_KEY');
  static String get doubaoApiKey =>
      _doubaoApiKeyPrimary.isNotEmpty ? _doubaoApiKeyPrimary : _doubaoApiKeySecondary;
  static const doubaoBaseUrl = String.fromEnvironment(
    'DOUBAO_BASE_URL',
    defaultValue: 'https://ark.cn-beijing.volces.com/api/v3',
  );
  static const doubaoModels = String.fromEnvironment(
    'DOUBAO_MODELS',
    defaultValue: 'doubao-seed-1-6-251015',
  );

  static String apiKeyFor(AiPlatform platform) {
    switch (platform) {
      case AiPlatform.openai:
        return openAIApiKey;
      case AiPlatform.deepseek:
        return deepSeekApiKey;
      case AiPlatform.doubao:
        return doubaoApiKey;
    }
  }

  static String baseUrlFor(AiPlatform platform) {
    switch (platform) {
      case AiPlatform.openai:
        return openAIBaseUrl;
      case AiPlatform.deepseek:
        return deepSeekBaseUrl;
      case AiPlatform.doubao:
        return doubaoBaseUrl;
    }
  }

  static List<AiModelOption> get availableModels => [
        ..._parseModels(AiPlatform.openai, openAIModels),
        ..._parseModels(AiPlatform.deepseek, deepSeekModels),
        ..._parseModels(AiPlatform.doubao, doubaoModels),
      ];

  static List<AiModelOption> get configuredModels =>
      availableModels.where((model) => model.isConfigured).toList(growable: false);

  static List<AiModelOption> _parseModels(AiPlatform platform, String source) {
    return source
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map(
          (id) => AiModelOption(
            platform: platform,
            id: id,
            label: id,
            isConfigured: apiKeyFor(platform).isNotEmpty,
          ),
        )
        .toList(growable: false);
  }
}
