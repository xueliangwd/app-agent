import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/ai_provider.dart';
import '../core/models/provider_settings.dart';
import 'llm_config.dart';

class AppSettingsRepository {
  const AppSettingsRepository();

  static const _apiKeySuffix = 'api_key';
  static const _baseUrlSuffix = 'base_url';
  static const _modelsSuffix = 'models';
  static const _selectedPlatformKey = 'selected_platform';
  static const _selectedModelIdKey = 'selected_model_id';

  Future<Map<AiPlatform, ProviderSettings>> loadProviderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final platform in AiPlatform.values)
        platform: ProviderSettings(
          platform: platform,
          apiKey: prefs.getString(_key(platform, _apiKeySuffix)) ??
              LlmConfig.defaultApiKeyFor(platform),
          baseUrl: prefs.getString(_key(platform, _baseUrlSuffix)) ??
              LlmConfig.defaultBaseUrlFor(platform),
          modelsText: prefs.getString(_key(platform, _modelsSuffix)) ??
              LlmConfig.defaultModelsFor(platform),
        ),
    };
  }

  Future<void> saveProviderSettings(ProviderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(settings.platform, _apiKeySuffix), settings.apiKey);
    await prefs.setString(_key(settings.platform, _baseUrlSuffix), settings.baseUrl);
    await prefs.setString(_key(settings.platform, _modelsSuffix), settings.modelsText);
  }

  Future<void> saveSelectedModel(AiModelOption? model) async {
    final prefs = await SharedPreferences.getInstance();
    if (model == null) {
      await prefs.remove(_selectedPlatformKey);
      await prefs.remove(_selectedModelIdKey);
      return;
    }
    await prefs.setString(_selectedPlatformKey, model.platform.name);
    await prefs.setString(_selectedModelIdKey, model.id);
  }

  Future<(AiPlatform?, String?)> loadSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    final platformName = prefs.getString(_selectedPlatformKey);
    final modelId = prefs.getString(_selectedModelIdKey);
    final platform = AiPlatform.values.where((item) => item.name == platformName).firstOrNull;
    return (platform, modelId);
  }

  String _key(AiPlatform platform, String suffix) => 'provider.${platform.name}.$suffix';
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
