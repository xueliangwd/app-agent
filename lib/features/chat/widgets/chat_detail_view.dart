import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/models/chat_models.dart';
import '../data/chat_controller.dart';
import '../data/settings_controller.dart';
import 'message_bubble.dart';
import 'settings_sheet.dart';

class ChatDetailView extends StatefulWidget {
  const ChatDetailView({
    super.key,
    required this.controller,
    required this.settingsController,
    required this.sessionId,
    this.embedded = false,
  });

  final ChatController controller;
  final SettingsController settingsController;
  final String? sessionId;
  final bool embedded;

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  late final TextEditingController _inputController;
  final List<DraftAttachment> _draftAttachments = [];

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

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _draftAttachments.addAll(_toDraftAttachments(result, imageOnly: true));
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _draftAttachments.addAll(_toDraftAttachments(result));
    });
  }

  List<DraftAttachment> _toDraftAttachments(
    FilePickerResult result, {
    bool imageOnly = false,
  }) {
    return result.files.where((file) => file.path != null).map((file) {
      final type = imageOnly || _isImageExtension(file.extension)
          ? DraftAttachmentType.image
          : DraftAttachmentType.file;
      return DraftAttachment(
        id: 'draft_${DateTime.now().microsecondsSinceEpoch}_${file.name}',
        type: type,
        path: file.path!,
        name: file.name,
        sizeLabel: _formatBytes(file.size),
        extension: file.extension,
      );
    }).toList(growable: false);
  }

  void _removeDraft(String id) {
    setState(() {
      _draftAttachments.removeWhere((item) => item.id == id);
    });
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
          settingsController: widget.settingsController,
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
          attachments: _draftAttachments,
          onPickImages: _pickImages,
          onPickFiles: _pickFiles,
          onRemoveAttachment: _removeDraft,
          onSend: () async {
            final text = _inputController.text;
            final attachments = List<DraftAttachment>.from(_draftAttachments);
            _inputController.clear();
            setState(() {
              _draftAttachments.clear();
            });
            await widget.controller.sendComposedMessage(
              sessionId: session.id,
              input: text,
              attachments: attachments,
            );
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
    required this.settingsController,
  });

  final ChatSession session;
  final bool embedded;
  final ChatController controller;
  final SettingsController settingsController;

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
          IconButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => SettingsSheet(controller: settingsController),
              );
            },
            icon: const Icon(Icons.settings_outlined),
            tooltip: '模型设置',
          ),
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
    required this.attachments,
    required this.onPickImages,
    required this.onPickFiles,
    required this.onRemoveAttachment,
  });

  final TextEditingController controller;
  final Future<void> Function() onSend;
  final bool isBusy;
  final List<DraftAttachment> attachments;
  final Future<void> Function() onPickImages;
  final Future<void> Function() onPickFiles;
  final ValueChanged<String> onRemoveAttachment;

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
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (attachments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: attachments.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = attachments[index];
                        return _AttachmentChip(
                          attachment: item,
                          onRemove: () => onRemoveAttachment(item.id),
                        );
                      },
                    ),
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    onPressed: isBusy ? null : onPickImages,
                    icon: const Icon(Icons.image_outlined, color: Color(0xFF0F766E)),
                    tooltip: '添加图片',
                  ),
                  IconButton(
                    onPressed: isBusy ? null : onPickFiles,
                    icon: const Icon(Icons.attach_file, color: Color(0xFF0F766E)),
                    tooltip: '添加文件',
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: !isBusy,
                      minLines: 1,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: '输入问题，或直接发送图片/文件',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.attachment,
    required this.onRemove,
  });

  final DraftAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attachment.type == DraftAttachmentType.image
                ? Icons.image_outlined
                : Icons.attach_file,
            size: 18,
            color: const Color(0xFF0F766E),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(attachment.name, overflow: TextOverflow.ellipsis),
                Text(
                  attachment.sizeLabel,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isImageExtension(String? extension) {
  final normalized = extension?.toLowerCase();
  return normalized == 'png' ||
      normalized == 'jpg' ||
      normalized == 'jpeg' ||
      normalized == 'webp' ||
      normalized == 'heic';
}

String _formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  final digits = size >= 100 || unitIndex == 0 ? 0 : 1;
  return '${size.toStringAsFixed(digits)} ${units[unitIndex]}';
}
