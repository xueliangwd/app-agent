import 'ai_provider.dart';

class ProviderSettings {
  const ProviderSettings({
    required this.platform,
    required this.apiKey,
    required this.baseUrl,
    required this.modelsText,
  });

  final AiPlatform platform;
  final String apiKey;
  final String baseUrl;
  final String modelsText;

  ProviderSettings copyWith({
    AiPlatform? platform,
    String? apiKey,
    String? baseUrl,
    String? modelsText,
  }) {
    return ProviderSettings(
      platform: platform ?? this.platform,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      modelsText: modelsText ?? this.modelsText,
    );
  }

  List<String> get models => modelsText
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  bool get isConfigured => apiKey.trim().isNotEmpty;
}
