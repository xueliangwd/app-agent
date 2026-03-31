import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/models/ai_provider.dart';
import '../core/models/llm_models.dart';
import 'llm_config.dart';

class LlmService {
  LlmService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<LlmResponse> createChatCompletion({
    required AiModelOption model,
    required List<Map<String, String>> messages,
  }) async {
    final apiKey = LlmConfig.apiKeyFor(model.platform);
    if (apiKey.isEmpty) {
      throw LlmConfigException(_missingKeyMessage(model.platform));
    }

    final response = await _client.post(
      Uri.parse('${_normalizeBaseUrl(LlmConfig.baseUrlFor(model.platform))}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model.id,
        'messages': messages,
        'stream': false,
      }),
    );

    final body = response.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'];
      final message = error is Map<String, dynamic>
          ? (error['message'] as String? ?? '模型请求失败')
          : '模型请求失败';
      throw LlmRequestException(message, response.statusCode);
    }

    final id = body['id'] as String? ?? '';
    final outputText = _extractChatContent(body);

    if (outputText.trim().isEmpty) {
      throw const LlmRequestException('模型返回成功，但没有可展示的文本内容。', 200);
    }

    return LlmResponse(id: id, outputText: outputText.trim());
  }

  String _extractChatContent(Map<String, dynamic> body) {
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) {
      return '';
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) {
      return '';
    }

    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      return '';
    }

    final content = message['content'];
    if (content is String) {
      return content;
    }
    if (content is List) {
      return content
          .whereType<Map<String, dynamic>>()
          .map((part) => part['text'] as String? ?? '')
          .where((part) => part.isNotEmpty)
          .join('\n');
    }
    return '';
  }

  String _normalizeBaseUrl(String baseUrl) => baseUrl.replaceAll(RegExp(r'/+$'), '');

  String _missingKeyMessage(AiPlatform platform) {
    switch (platform) {
      case AiPlatform.openai:
        return '缺少 OPENAI_API_KEY。请使用 --dart-define=OPENAI_API_KEY=你的密钥。';
      case AiPlatform.deepseek:
        return '缺少 DEEPSEEK_API_KEY。请使用 --dart-define=DEEPSEEK_API_KEY=你的密钥。';
      case AiPlatform.doubao:
        return '缺少 DOUBAO_API_KEY 或 ARK_API_KEY。请使用 --dart-define=DOUBAO_API_KEY=你的密钥。';
    }
  }
}

class LlmConfigException implements Exception {
  const LlmConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LlmRequestException implements Exception {
  const LlmRequestException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => '[$statusCode] $message';
}
