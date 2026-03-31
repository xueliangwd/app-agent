import 'package:flutter/material.dart';

import '../../../core/models/chat_models.dart';
import '../data/chat_controller.dart';
import 'message_bubble.dart';

class ChatDetailView extends StatefulWidget {
  const ChatDetailView({
    super.key,
    required this.controller,
    required this.sessionId,
    this.embedded = false,
  });

  final ChatController controller;
  final String? sessionId;
  final bool embedded;

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  late final TextEditingController _inputController;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.controller.sessions.cast<ChatSession?>().firstWhere(
          (item) => item?.id == widget.sessionId,
          orElse: () => widget.controller.selectedSession,
        );

    if (session == null) {
      return const SizedBox.shrink();
    }

    final body = Column(
      children: [
        _Header(
          session: session,
          embedded: widget.embedded,
          controller: widget.controller,
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            itemCount: session.messages.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return MessageBubble(message: session.messages[index]);
            },
          ),
        ),
        _Composer(
          controller: _inputController,
          isBusy: widget.controller.isTyping(session.id),
          onSend: () async {
            final text = _inputController.text;
            _inputController.clear();
            await widget.controller.sendUserMessage(session.id, text);
          },
        ),
      ],
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(child: body),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.session,
    required this.embedded,
    required this.controller,
  });

  final ChatSession session;
  final bool embedded;
  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final selectedModel = controller.selectedModel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          if (!embedded)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedModel == null
                      ? '支持多平台模型接入'
                      : '当前模型：${selectedModel.platformLabel} / ${selectedModel.id}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ModelSwitcher(controller: controller),
        ],
      ),
    );
  }
}

class _ModelSwitcher extends StatelessWidget {
  const _ModelSwitcher({required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    final selectedModel = controller.selectedModel;
    return OutlinedButton.icon(
      onPressed: () async {
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Text(
                      '切换模型',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  for (final option in controller.availableModels)
                    ListTile(
                      leading: Icon(
                        option == selectedModel
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: const Color(0xFF0F766E),
                      ),
                      title: Text(option.displayName),
                      subtitle: Text(option.isConfigured ? '已配置' : '未配置 API Key'),
                      trailing: option.isConfigured
                          ? null
                          : const Icon(Icons.warning_amber_rounded, color: Color(0xFFE58C40)),
                      onTap: () {
                        controller.selectModel(option);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.tune),
      label: Text(selectedModel?.label ?? '选择模型'),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.isBusy,
  });

  final TextEditingController controller;
  final Future<void> Function() onSend;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF0F766E)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !isBusy,
                  minLines: 1,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: '输入你的问题，例如：帮我用图表总结这周活跃度',
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: isBusy ? null : onSend,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
