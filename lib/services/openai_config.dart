class OpenAIConfig {
  const OpenAIConfig._();

  static const apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const baseUrl = String.fromEnvironment(
    'OPENAI_BASE_URL',
    defaultValue: 'https://api.openai.com/v1',
  );
  static const model = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-5.2',
  );

  static bool get isConfigured => apiKey.isNotEmpty;
}
