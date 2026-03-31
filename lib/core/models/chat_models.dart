import 'package:flutter/material.dart';

enum SenderRole { user, assistant, system }

enum MessageType { text, markdown, richText, lineChart, barChart, pieChart }

class ChatSession {
  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.updatedAt,
    this.lastResponseId,
    this.pinned = false,
  });

  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime updatedAt;
  final String? lastResponseId;
  final bool pinned;

  String get preview =>
      messages.isEmpty ? '开始新的对话' : messages.last.plainPreview;

  ChatSession copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? updatedAt,
    String? lastResponseId,
    bool? pinned,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
      lastResponseId: lastResponseId ?? this.lastResponseId,
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
  });

  final String id;
  final SenderRole role;
  final MessageType type;
  final DateTime createdAt;
  final String? text;
  final List<RichSegment> richSegments;
  final ChartPayload? chart;

  String get plainPreview {
    switch (type) {
      case MessageType.richText:
        return richSegments.map((segment) => segment.text).join();
      case MessageType.lineChart:
      case MessageType.barChart:
      case MessageType.pieChart:
        return chart?.title ?? '图表消息';
      case MessageType.text:
      case MessageType.markdown:
        return text ?? '';
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
