import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/ai_provider.dart';
import '../../../core/models/chat_models.dart';
import '../../../services/native_bridge_service.dart';
import '../../../services/llm_config.dart';
import '../../../services/llm_service.dart';
import 'mock_chat_data.dart';

class ChatController extends ChangeNotifier {
  ChatController({LlmService? llmService}) : _llmService = llmService ?? LlmService();

  final LlmService _llmService;
  final List<ChatSession> _sessions = [];
  final Set<String> _typingSessionIds = {};
  late final List<AiModelOption> _availableModels;
  String? _selectedSessionId;
  AiModelOption? _selectedModel;

  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  List<AiModelOption> get availableModels => List.unmodifiable(_availableModels);

  String? get selectedSessionId => _selectedSessionId;
  AiModelOption? get selectedModel => _selectedModel;

  ChatSession? get selectedSession {
    if (_selectedSessionId == null) {
      return _sessions.isEmpty ? null : _sessions.first;
    }
    return _sessions.cast<ChatSession?>().firstWhere(
          (session) => session?.id == _selectedSessionId,
          orElse: () => _sessions.isEmpty ? null : _sessions.first,
        );
  }

  bool isTyping(String sessionId) => _typingSessionIds.contains(sessionId);

  Future<void> bootstrap() async {
    final context = await NativeBridgeService.instance.getPlatformContext();
    _availableModels = LlmConfig.availableModels;
    _selectedModel =
        LlmConfig.configuredModels.firstOrNull ?? _availableModels.firstOrNull;
    _sessions
      ..clear()
      ..addAll(MockChatData.seedSessions(platformContext: context));
    _selectedSessionId = _sessions.firstOrNull?.id;
    notifyListeners();
  }

  void selectSession(String sessionId) {
    _selectedSessionId = sessionId;
    notifyListeners();
  }

  void selectModel(AiModelOption model) {
    _selectedModel = model;
    notifyListeners();
  }

  void createSession() {
    final session = ChatSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      title: '新对话',
      messages: [
        ChatMessage(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          role: SenderRole.assistant,
          type: MessageType.markdown,
          createdAt: DateTime.now(),
          text: '''
你可以直接把需求丢给我，我会尽量按 **Agent** 的方式处理。

- 支持普通问答
- 支持 Markdown / 表格 / 列表
- 支持图表结果卡片
- 后续可接 OpenAI、豆包、DeepSeek 等模型 API
''',
        ),
      ],
      updatedAt: DateTime.now(),
      lastModel: _selectedModel,
    );
    _sessions.insert(0, session);
    _selectedSessionId = session.id;
    notifyListeners();
  }

  Future<void> sendUserMessage(String sessionId, String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final activeModel = _selectedModel;
    if (activeModel == null) {
      return;
    }

    final sessionIndex = _sessions.indexWhere((session) => session.id == sessionId);
    if (sessionIndex == -1) {
      return;
    }

    final current = _sessions[sessionIndex];
    final nextMessages = [...current.messages];
    nextMessages.add(
      ChatMessage(
        id: 'user_${DateTime.now().microsecondsSinceEpoch}',
        role: SenderRole.user,
        type: MessageType.text,
        createdAt: DateTime.now(),
        text: trimmed,
      ),
    );

    _sessions[sessionIndex] = current.copyWith(
      title: current.title == '新对话' ? _buildTitle(trimmed) : current.title,
      messages: nextMessages,
      updatedAt: DateTime.now(),
      lastModel: activeModel,
    );
    _typingSessionIds.add(sessionId);
    _sortSessions();
    notifyListeners();

    try {
      final updatedSession = _sessions.firstWhere((session) => session.id == sessionId);
      final response = await _llmService.createChatCompletion(
        model: activeModel,
        messages: _buildRequestMessages(updatedSession),
      );
      final refreshed = _sessions.firstWhere((session) => session.id == sessionId);
      _sessions[_sessions.indexOf(refreshed)] = refreshed.copyWith(
        messages: [
          ...refreshed.messages,
          ChatMessage(
            id: 'assistant_${DateTime.now().microsecondsSinceEpoch}',
            role: SenderRole.assistant,
            type: MessageType.markdown,
            createdAt: DateTime.now(),
            text: response.outputText,
          ),
        ],
        lastModel: activeModel,
        updatedAt: DateTime.now(),
      );
    } catch (error) {
      final updated = _sessions.firstWhere((session) => session.id == sessionId);
      _sessions[_sessions.indexOf(updated)] = updated.copyWith(
        messages: [
          ...updated.messages,
          ChatMessage(
            id: 'assistant_error_${DateTime.now().microsecondsSinceEpoch}',
            role: SenderRole.assistant,
            type: MessageType.markdown,
            createdAt: DateTime.now(),
            text: '''
OpenAI 调用失败：

```text
$error
```

请先检查：

- `OPENAI_API_KEY` 是否已通过 `--dart-define` 传入
- 当前平台对应的 API Key 是否已传入
- Base URL 是否正确
- 当前模型名是否可用
''',
          ),
        ],
        updatedAt: DateTime.now(),
      );
    }
    _typingSessionIds.remove(sessionId);
    _sortSessions();
    notifyListeners();
  }

  String _buildTitle(String input) {
    if (input.runes.length <= 16) {
      return input;
    }
    return '${String.fromCharCodes(input.runes.take(16))}...';
  }
  void _sortSessions() {
    _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<Map<String, String>> _buildRequestMessages(ChatSession session) {
    return [
      const {
        'role': 'system',
        'content':
            '你是一个中文优先的 AI Agent 助手。请尽量使用清晰结构化的 Markdown 回复；如果用户要求图表或富文本，先用文本和 Markdown 给出适合 UI 渲染的内容。',
      },
      for (final message in session.messages)
        {
          'role': switch (message.role) {
            SenderRole.user => 'user',
            SenderRole.assistant => 'assistant',
            SenderRole.system => 'system',
          },
          'content': message.plainPreview,
        },
    ];
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
