import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/ai_provider.dart';
import '../../../core/models/chat_models.dart';
import '../../../core/models/provider_settings.dart';
import '../../../services/native_bridge_service.dart';
import '../../../services/llm_service.dart';
import 'settings_controller.dart';
import 'mock_chat_data.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    required SettingsController settingsController,
    LlmService? llmService,
  })  : _settingsController = settingsController,
        _llmService = llmService ?? LlmService() {
    _settingsController.addListener(_handleSettingsChanged);
  }

  final SettingsController _settingsController;
  final LlmService _llmService;
  final List<ChatSession> _sessions = [];
  final Set<String> _typingSessionIds = {};
  String? _selectedSessionId;

  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  List<AiModelOption> get availableModels => _settingsController.availableModels;
  Map<AiPlatform, ProviderSettings> get providerSettings => _settingsController.providerSettings;

  String? get selectedSessionId => _selectedSessionId;
  AiModelOption? get selectedModel => _settingsController.selectedModel;

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
    _settingsController.selectModel(model);
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
      lastModel: selectedModel,
    );
    _sessions.insert(0, session);
    _selectedSessionId = session.id;
    notifyListeners();
  }

  Future<void> sendUserMessage(String sessionId, String input) async {
    await sendComposedMessage(sessionId: sessionId, input: input);
  }

  Future<void> sendComposedMessage({
    required String sessionId,
    required String input,
    List<DraftAttachment> attachments = const [],
  }) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty && attachments.isEmpty) {
      return;
    }
    if (_typingSessionIds.contains(sessionId)) {
      return;
    }
    final activeModel = selectedModel;
    if (activeModel == null) {
      return;
    }
    final providerSettings = this.providerSettings[activeModel.platform];
    if (providerSettings == null) {
      return;
    }

    final sessionIndex = _sessions.indexWhere((session) => session.id == sessionId);
    if (sessionIndex == -1) {
      return;
    }

    final current = _sessions[sessionIndex];
    final nextMessages = [...current.messages];
    nextMessages.add(_buildUserMessage(trimmed, attachments));

    _sessions[sessionIndex] = current.copyWith(
      title: current.title == '新对话' ? _buildTitle(trimmed) : current.title,
      messages: nextMessages,
      updatedAt: DateTime.now(),
      lastModel: activeModel,
    );
    try {
      final assistantMessageId = 'assistant_${DateTime.now().microsecondsSinceEpoch}';
      final sessionWithPlaceholder = _sessions[sessionIndex].copyWith(
        messages: [
          ..._sessions[sessionIndex].messages,
          ChatMessage(
            id: assistantMessageId,
            role: SenderRole.assistant,
            type: MessageType.markdown,
            createdAt: DateTime.now(),
            text: '',
          ),
        ],
        updatedAt: DateTime.now(),
      );
      _sessions[sessionIndex] = sessionWithPlaceholder;
      _typingSessionIds.add(sessionId);
      _sortSessions();
      notifyListeners();

      final buffer = StringBuffer();
      await for (final chunk in _llmService.streamChatCompletion(
        model: activeModel,
        providerSettings: providerSettings,
        messages: _buildRequestMessages(current.copyWith(messages: nextMessages)),
      )) {
        buffer.write(chunk);
        _updateAssistantDraft(
          sessionId: sessionId,
          messageId: assistantMessageId,
          nextText: buffer.toString(),
          activeModel: activeModel,
        );
      }

      if (buffer.isEmpty) {
        throw const LlmRequestException('流式连接已建立，但没有收到文本内容。', 200);
      }
    } catch (error) {
      _upsertErrorMessage(sessionId, error);
    } finally {
      _typingSessionIds.remove(sessionId);
      _sortSessions();
      notifyListeners();
    }
  }

  void _upsertErrorMessage(String sessionId, Object error) {
    final sessionIndex = _sessions.indexWhere((session) => session.id == sessionId);
    if (sessionIndex == -1) {
      return;
    }

    final session = _sessions[sessionIndex];
    final messages = [...session.messages];
    final assistantIndex = messages.lastIndexWhere(
      (message) => message.role == SenderRole.assistant && (message.text ?? '').isEmpty,
    );

    final errorMessage = ChatMessage(
      id: 'assistant_error_${DateTime.now().microsecondsSinceEpoch}',
      role: SenderRole.assistant,
      type: MessageType.markdown,
      createdAt: DateTime.now(),
      text: '''
模型调用失败：

```text
$error
```

请先检查：

- `OPENAI_API_KEY` 是否已通过 `--dart-define` 传入
- 当前平台对应的 API Key 是否已传入
- Base URL 是否正确
- 当前模型名是否可用
- 可以在右上角设置页里直接修改 API Key、Base URL、模型列表
''',
    );

    if (assistantIndex != -1) {
      messages[assistantIndex] = errorMessage;
    } else {
      messages.add(errorMessage);
    }

    _sessions[sessionIndex] = session.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );
  }

  String _buildTitle(String input) {
    if (input.isEmpty) {
      return '附件对话';
    }
    if (input.runes.length <= 16) {
      return input;
    }
    return '${String.fromCharCodes(input.runes.take(16))}...';
  }
  void _sortSessions() {
    _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void _updateAssistantDraft({
    required String sessionId,
    required String messageId,
    required String nextText,
    required AiModelOption activeModel,
  }) {
    final sessionIndex = _sessions.indexWhere((session) => session.id == sessionId);
    if (sessionIndex == -1) {
      return;
    }

    final session = _sessions[sessionIndex];
    final messages = [...session.messages];
    final messageIndex = messages.indexWhere((message) => message.id == messageId);
    if (messageIndex == -1) {
      return;
    }

    final previous = messages[messageIndex];
    messages[messageIndex] = ChatMessage(
      id: previous.id,
      role: previous.role,
      type: previous.type,
      createdAt: previous.createdAt,
      text: nextText,
      richSegments: previous.richSegments,
      chart: previous.chart,
    );

    _sessions[sessionIndex] = session.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
      lastModel: activeModel,
    );
    notifyListeners();
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

  ChatMessage _buildUserMessage(String input, List<DraftAttachment> attachments) {
    final blocks = <ContentBlock>[
      if (input.isNotEmpty) ContentBlock(type: ContentBlockType.text, text: input),
      ...attachments.map((attachment) => attachment.toContentBlock()),
    ];
    final hasAttachments = attachments.isNotEmpty;

    return ChatMessage(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      role: SenderRole.user,
      type: hasAttachments ? MessageType.blocks : MessageType.text,
      createdAt: DateTime.now(),
      text: hasAttachments ? null : input,
      blocks: hasAttachments ? blocks : const [],
    );
  }

  void _handleSettingsChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _settingsController.removeListener(_handleSettingsChanged);
    super.dispose();
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
