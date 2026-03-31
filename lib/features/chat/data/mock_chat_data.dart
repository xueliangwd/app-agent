import 'package:flutter/material.dart';

import '../../../core/models/ai_provider.dart';
import '../../../core/models/chat_models.dart';

class MockChatData {
  static List<ChatSession> seedSessions({required String platformContext}) {
    final now = DateTime.now();
    return [
      ChatSession(
        id: 'session_product',
        title: 'Agent App 方案',
        updatedAt: now,
        lastModel: const AiModelOption(
          platform: AiPlatform.openai,
          id: 'gpt-5.2',
          label: 'gpt-5.2',
          isConfigured: false,
        ),
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
            type: MessageType.blocks,
            createdAt: now.subtract(const Duration(minutes: 6)),
            blocks: const [
              ContentBlock(
                type: ContentBlockType.markdown,
                text: '下面这条消息演示了会话内多种格式混排能力，目标是覆盖豆包类产品常见内容载体。',
              ),
              ContentBlock(
                type: ContentBlockType.richText,
                richSegments: [
                  RichSegment(text: '已支持 '),
                  RichSegment(text: 'Markdown', bold: true, color: Color(0xFF0F766E)),
                  RichSegment(text: '、'),
                  RichSegment(text: '富文本', bold: true, color: Color(0xFFE58C40)),
                  RichSegment(text: '、'),
                  RichSegment(text: '图片/文件/网页卡片', bold: true, color: Color(0xFF264653)),
                  RichSegment(text: '、代码、公式、Mermaid、媒体与任务结果。'),
                ],
              ),
              ContentBlock(
                type: ContentBlockType.code,
                code: CodePayload(
                  language: 'dart',
                  title: 'Flutter Block Renderer',
                  source: 'Widget buildBlock(ContentBlock block) {\n  return switch (block.type) {\n    ContentBlockType.markdown => MarkdownBody(data: block.text ?? \'\'),\n    ContentBlockType.image => Image.network(block.images.first.url),\n    _ => const SizedBox.shrink(),\n  };\n}',
                ),
              ),
              ContentBlock(
                type: ContentBlockType.latex,
                text: r'E = mc^2, \int_0^1 x^2 dx = \frac{1}{3}',
              ),
              ContentBlock(
                type: ContentBlockType.mermaid,
                text: 'graph TD\n  用户输入 --> 模型路由\n  模型路由 --> 渲染协议\n  渲染协议 --> Flutter UI',
              ),
              ContentBlock(
                type: ContentBlockType.quote,
                text: '引用块通常用于总结、结论、法规摘要、研究摘录或来源片段。',
              ),
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
          ChatMessage(
            id: 'msg_5',
            role: SenderRole.assistant,
            type: MessageType.blocks,
            createdAt: now.subtract(const Duration(minutes: 4)),
            blocks: const [
              ContentBlock(
                type: ContentBlockType.gallery,
                images: [
                  MediaItem(
                    url: 'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=900&q=80',
                    title: '产品看板',
                    caption: '图库示例：适合生成结果、多图对比、海报合集',
                  ),
                  MediaItem(
                    url: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=900&q=80',
                    title: '数据大屏',
                  ),
                ],
              ),
              ContentBlock(
                type: ContentBlockType.file,
                file: FileAttachment(
                  name: '2026_Q1_Agent_PRD.pdf',
                  extension: 'pdf',
                  sizeLabel: '2.4 MB',
                  summary: '产品需求文档摘要已生成',
                ),
              ),
              ContentBlock(
                type: ContentBlockType.webCard,
                webCard: WebCardPayload(
                  title: 'Agent App 行业研究',
                  domain: 'research.example.com',
                  summary: '网页卡片适合展示搜索结果、引用来源、链接摘要与结构化检索信息。',
                ),
              ),
              ContentBlock(
                type: ContentBlockType.audio,
                media: MediaPayload(
                  title: '会议录音转写',
                  durationLabel: '12:32',
                  summary: '音频卡片可用于转写、播报、语音消息。',
                ),
              ),
              ContentBlock(
                type: ContentBlockType.video,
                media: MediaPayload(
                  title: '交互演示视频',
                  durationLabel: '00:45',
                  summary: '视频卡片可用于短片预览、讲解结果、生成素材。',
                ),
              ),
              ContentBlock(
                type: ContentBlockType.taskResult,
                taskResult: TaskResultPayload(
                  title: 'Agent 执行结果',
                  status: '已完成',
                  items: [
                    '已读取 3 份产品文档',
                    '已生成一版信息架构',
                    '已整理 5 条关键风险',
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ChatSession(
        id: 'session_data',
        title: '运营周报',
        updatedAt: now.subtract(const Duration(hours: 2)),
        lastModel: const AiModelOption(
          platform: AiPlatform.deepseek,
          id: 'deepseek-chat',
          label: 'deepseek-chat',
          isConfigured: false,
        ),
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
