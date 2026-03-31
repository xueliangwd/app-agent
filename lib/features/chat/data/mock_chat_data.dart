import 'package:flutter/material.dart';

import '../../../core/models/chat_models.dart';

class MockChatData {
  static List<ChatSession> seedSessions({required String platformContext}) {
    final now = DateTime.now();
    return [
      ChatSession(
        id: 'session_product',
        title: 'Agent App 方案',
        updatedAt: now,
        lastResponseId: null,
        pinned: true,
        messages: [
          ChatMessage(
            id: 'msg_1',
            role: SenderRole.assistant,
            type: MessageType.markdown,
            createdAt: now.subtract(const Duration(minutes: 8)),
            text: '''
# Flutter Agent App

这个 Demo 参考豆包的交互方式，采用：

- 左侧会话列表
- 右侧对话详情
- 多消息类型统一渲染
- iOS 原生能力桥接预留

当前运行环境：`$platformContext`
''',
          ),
          ChatMessage(
            id: 'msg_2',
            role: SenderRole.user,
            type: MessageType.text,
            createdAt: now.subtract(const Duration(minutes: 7)),
            text: '需要支持 markdown、富文本、图表。',
          ),
          ChatMessage(
            id: 'msg_3',
            role: SenderRole.assistant,
            type: MessageType.richText,
            createdAt: now.subtract(const Duration(minutes: 6)),
            richSegments: const [
              RichSegment(text: '已经支持 '),
              RichSegment(text: 'Markdown', bold: true, color: Color(0xFF0F766E)),
              RichSegment(text: '、'),
              RichSegment(text: 'Rich Text', bold: true, color: Color(0xFFE58C40)),
              RichSegment(text: '、'),
              RichSegment(text: 'Charts', bold: true, color: Color(0xFF264653)),
              RichSegment(text: ' 三类消息卡片。'),
            ],
          ),
          ChatMessage(
            id: 'msg_4',
            role: SenderRole.assistant,
            type: MessageType.barChart,
            createdAt: now.subtract(const Duration(minutes: 5)),
            chart: ChartPayload(
              title: '消息类型渲染覆盖率',
              subtitle: '当前 Demo 已内建的展示能力',
              series: const [
                ChartDatum(label: 'Text', value: 100, color: Color(0xFF0F766E)),
                ChartDatum(label: 'Markdown', value: 95, color: Color(0xFF2A9D8F)),
                ChartDatum(label: 'Rich', value: 88, color: Color(0xFFF4A261)),
                ChartDatum(label: 'Chart', value: 92, color: Color(0xFFE76F51)),
              ],
            ),
          ),
        ],
      ),
      ChatSession(
        id: 'session_data',
        title: '运营周报',
        updatedAt: now.subtract(const Duration(hours: 2)),
        lastResponseId: null,
        messages: [
          ChatMessage(
            id: 'data_1',
            role: SenderRole.assistant,
            type: MessageType.pieChart,
            createdAt: now.subtract(const Duration(hours: 2)),
            chart: ChartPayload(
              title: '请求分布',
              subtitle: '可用于 API 请求来源占比分析',
              series: const [
                ChartDatum(label: '搜索', value: 40, color: Color(0xFF0F766E)),
                ChartDatum(label: '问答', value: 30, color: Color(0xFFE58C40)),
                ChartDatum(label: '工具调用', value: 20, color: Color(0xFF264653)),
                ChartDatum(label: '其他', value: 10, color: Color(0xFF84A59D)),
              ],
            ),
          ),
        ],
      ),
    ];
  }
}
