import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/models/openai_models.dart';
import 'openai_config.dart';

class OpenAIService {
  OpenAIService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<OpenAIResponse> createResponse({
    required String input,
    String? previousResponseId,
  }) async {
    if (!OpenAIConfig.isConfigured) {
      throw const OpenAIConfigException(
        '缺少 OPENAI_API_KEY。请使用 --dart-define=OPENAI_API_KEY=你的密钥 启动应用。',
      );
    }

    final uri = Uri.parse('${OpenAIConfig.baseUrl}/responses');
    final payload = <String, Object?>{
      'model': OpenAIConfig.model,
      'input': input,
      'store': false,
    };

    if (previousResponseId != null && previousResponseId.isNotEmpty) {
      payload['previous_response_id'] = previousResponseId;
    }

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${OpenAIConfig.apiKey}',
      },
      body: jsonEncode(payload),
    );

    final body = response.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'];
      final message = error is Map<String, dynamic>
          ? (error['message'] as String? ?? 'OpenAI 请求失败')
          : 'OpenAI 请求失败';
      throw OpenAIRequestException(message, response.statusCode);
    }

    final id = body['id'] as String? ?? '';
    final outputText = body['output_text'] as String? ?? _extractOutputText(body);

    if (outputText.trim().isEmpty) {
      throw const OpenAIRequestException('模型返回成功，但没有可展示的文本内容。', 200);
    }

    return OpenAIResponse(id: id, outputText: outputText.trim());
  }

  String _extractOutputText(Map<String, dynamic> body) {
    final output = body['output'];
    if (output is! List) {
      return '';
    }

    final buffer = StringBuffer();
    for (final item in output) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final content = item['content'];
      if (content is! List) {
        continue;
      }
      for (final block in content) {
        if (block is! Map<String, dynamic>) {
          continue;
        }
        if (block['type'] == 'output_text') {
          final text = block['text'] as String?;
          if (text != null && text.isNotEmpty) {
            buffer.writeln(text);
          }
        }
      }
    }
    return buffer.toString();
  }
}

class OpenAIConfigException implements Exception {
  const OpenAIConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OpenAIRequestException implements Exception {
  const OpenAIRequestException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => '[$statusCode] $message';
}
