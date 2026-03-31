import 'package:flutter/material.dart';

import 'ai_provider.dart';

enum SenderRole { user, assistant, system }

enum MessageType { text, markdown, richText, lineChart, barChart, pieChart, blocks }

enum ContentBlockType {
  text,
  markdown,
  richText,
  code,
  quote,
  latex,
  mermaid,
  image,
  gallery,
  file,
  webCard,
  audio,
  video,
  taskResult,
  lineChart,
  barChart,
  pieChart,
}

enum DraftAttachmentType { image, file }

class ChatSession {
  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.updatedAt,
    this.lastModel,
    this.pinned = false,
  });

  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime updatedAt;
  final AiModelOption? lastModel;
  final bool pinned;

  String get preview =>
      messages.isEmpty ? '开始新的对话' : messages.last.plainPreview;

  ChatSession copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? updatedAt,
    AiModelOption? lastModel,
    bool? pinned,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
      lastModel: lastModel ?? this.lastModel,
      pinned: pinned ?? this.pinned,
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.type,
    required this.createdAt,
    this.text,
    this.richSegments = const [],
    this.chart,
    this.blocks = const [],
  });

  final String id;
  final SenderRole role;
  final MessageType type;
  final DateTime createdAt;
  final String? text;
  final List<RichSegment> richSegments;
  final ChartPayload? chart;
  final List<ContentBlock> blocks;

  String get plainPreview {
    switch (type) {
      case MessageType.richText:
        return richSegments.map((segment) => segment.text).join();
      case MessageType.lineChart:
      case MessageType.barChart:
      case MessageType.pieChart:
        return chart?.title ?? '图表消息';
      case MessageType.blocks:
        return blocks.map((block) => block.preview).where((e) => e.isNotEmpty).join(' ');
      case MessageType.text:
      case MessageType.markdown:
        return text ?? '';
    }
  }
}

class ContentBlock {
  const ContentBlock({
    required this.type,
    this.text,
    this.richSegments = const [],
    this.chart,
    this.images = const [],
    this.file,
    this.webCard,
    this.media,
    this.code,
    this.taskResult,
  });

  final ContentBlockType type;
  final String? text;
  final List<RichSegment> richSegments;
  final ChartPayload? chart;
  final List<MediaItem> images;
  final FileAttachment? file;
  final WebCardPayload? webCard;
  final MediaPayload? media;
  final CodePayload? code;
  final TaskResultPayload? taskResult;

  String get preview {
    switch (type) {
      case ContentBlockType.richText:
        return richSegments.map((segment) => segment.text).join();
      case ContentBlockType.code:
        return code?.title ?? '代码块';
      case ContentBlockType.quote:
      case ContentBlockType.latex:
      case ContentBlockType.mermaid:
      case ContentBlockType.text:
      case ContentBlockType.markdown:
        return text ?? '';
      case ContentBlockType.image:
      case ContentBlockType.gallery:
        return images.isEmpty ? '图片' : images.first.title;
      case ContentBlockType.file:
        return file?.name ?? '文件';
      case ContentBlockType.webCard:
        return webCard?.title ?? '网页卡片';
      case ContentBlockType.audio:
      case ContentBlockType.video:
        return media?.title ?? '媒体卡片';
      case ContentBlockType.taskResult:
        return taskResult?.title ?? '任务结果';
      case ContentBlockType.lineChart:
      case ContentBlockType.barChart:
      case ContentBlockType.pieChart:
        return chart?.title ?? '图表';
    }
  }
}

class RichSegment {
  const RichSegment({
    required this.text,
    this.bold = false,
    this.italic = false,
    this.color,
  });

  final String text;
  final bool bold;
  final bool italic;
  final Color? color;
}

class ChartPayload {
  const ChartPayload({
    required this.title,
    required this.subtitle,
    required this.series,
  });

  final String title;
  final String subtitle;
  final List<ChartDatum> series;
}

class ChartDatum {
  const ChartDatum({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class MediaItem {
  const MediaItem({
    required this.url,
    required this.title,
    this.aspectRatio = 16 / 9,
    this.caption,
    this.localPath,
  });

  final String url;
  final String title;
  final double aspectRatio;
  final String? caption;
  final String? localPath;
}

class FileAttachment {
  const FileAttachment({
    required this.name,
    required this.extension,
    required this.sizeLabel,
    this.summary,
    this.localPath,
  });

  final String name;
  final String extension;
  final String sizeLabel;
  final String? summary;
  final String? localPath;
}

class WebCardPayload {
  const WebCardPayload({
    required this.title,
    required this.domain,
    required this.summary,
    this.url,
  });

  final String title;
  final String domain;
  final String summary;
  final String? url;
}

class MediaPayload {
  const MediaPayload({
    required this.title,
    required this.durationLabel,
    this.summary,
  });

  final String title;
  final String durationLabel;
  final String? summary;
}

class CodePayload {
  const CodePayload({
    required this.language,
    required this.source,
    this.title,
  });

  final String language;
  final String source;
  final String? title;
}

class TaskResultPayload {
  const TaskResultPayload({
    required this.title,
    required this.status,
    required this.items,
  });

  final String title;
  final String status;
  final List<String> items;
}

class DraftAttachment {
  const DraftAttachment({
    required this.id,
    required this.type,
    required this.path,
    required this.name,
    required this.sizeLabel,
    this.extension,
  });

  final String id;
  final DraftAttachmentType type;
  final String path;
  final String name;
  final String sizeLabel;
  final String? extension;

  ContentBlock toContentBlock() {
    switch (type) {
      case DraftAttachmentType.image:
        return ContentBlock(
          type: ContentBlockType.image,
          images: [
            MediaItem(
              url: path,
              localPath: path,
              title: name,
              caption: sizeLabel,
            ),
          ],
        );
      case DraftAttachmentType.file:
        return ContentBlock(
          type: ContentBlockType.file,
          file: FileAttachment(
            name: name,
            extension: (extension ?? 'file').replaceFirst('.', ''),
            sizeLabel: sizeLabel,
            summary: '本地附件',
            localPath: path,
          ),
        );
    }
  }
}
