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
  static const customApiKey = String.fromEnvironment('CUSTOM_API_KEY');
  static const customBaseUrl = String.fromEnvironment(
    'CUSTOM_BASE_URL',
    defaultValue: 'https://api.openai.com/v1',
  );
  static const customModels = String.fromEnvironment(
    'CUSTOM_MODELS',
    defaultValue: '',
  );
  static const systemModels = String.fromEnvironment(
    'SYSTEM_MODELS',
    defaultValue: 'system-local',
  );

  static String defaultApiKeyFor(AiPlatform platform) {
    switch (platform) {
      case AiPlatform.openai:
        return openAIApiKey;
      case AiPlatform.deepseek:
        return deepSeekApiKey;
      case AiPlatform.doubao:
        return doubaoApiKey;
      case AiPlatform.custom:
        return customApiKey;
      case AiPlatform.system:
        return '';
    }
  }

  static String defaultBaseUrlFor(AiPlatform platform) {
    switch (platform) {
      case AiPlatform.openai:
        return openAIBaseUrl;
      case AiPlatform.deepseek:
        return deepSeekBaseUrl;
      case AiPlatform.doubao:
        return doubaoBaseUrl;
      case AiPlatform.custom:
        return customBaseUrl;
      case AiPlatform.system:
        return '';
    }
  }

  static String defaultModelsFor(AiPlatform platform) {
    switch (platform) {
      case AiPlatform.openai:
        return openAIModels;
      case AiPlatform.deepseek:
        return deepSeekModels;
      case AiPlatform.doubao:
        return doubaoModels;
      case AiPlatform.custom:
        return customModels;
      case AiPlatform.system:
        return systemModels;
    }
  }

  static List<AiModelOption> get availableModels => [
        ..._parseModels(AiPlatform.openai, openAIModels),
        ..._parseModels(AiPlatform.deepseek, deepSeekModels),
        ..._parseModels(AiPlatform.doubao, doubaoModels),
        ..._parseModels(AiPlatform.custom, customModels),
        ..._parseModels(AiPlatform.system, systemModels),
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
            isConfigured: defaultApiKeyFor(platform).isNotEmpty,
          ),
        )
        .toList(growable: false);
  }
}
