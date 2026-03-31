import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../core/models/chat_models.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  bool get _isUser => message.role == SenderRole.user;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = _isUser ? const Color(0xFF0F766E) : Colors.white;
    final textColor = _isUser ? Colors.white : const Color(0xFF1F2937);

    return Row(
      mainAxisAlignment: _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isUser) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF16302B),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: DefaultTextStyle(
              style: TextStyle(color: textColor, height: 1.55, fontSize: 15),
              child: _MessageContent(message: message, textColor: textColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.message, required this.textColor});

  final ChatMessage message;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Text(message.text ?? '');
      case MessageType.markdown:
        return MarkdownBody(
          data: message.text ?? '',
          selectable: true,
          extensionSet: mdExtensionSet,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: TextStyle(color: textColor, fontSize: 15, height: 1.55),
            strong: TextStyle(color: textColor, fontWeight: FontWeight.w800),
            em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
            code: TextStyle(
              color: textColor,
              backgroundColor: textColor.withValues(alpha: 0.08),
            ),
            blockquote: TextStyle(color: textColor.withValues(alpha: 0.82)),
            h1: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w800),
            h2: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w800),
            h3: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700),
            listBullet: TextStyle(color: textColor),
            tableBody: TextStyle(color: textColor),
            tableHead: TextStyle(color: textColor, fontWeight: FontWeight.w700),
          ),
        );
      case MessageType.richText:
        return Text.rich(
          TextSpan(
            children: message.richSegments
                .map(
                  (segment) => TextSpan(
                    text: segment.text,
                    style: TextStyle(
                      color: segment.color ?? textColor,
                      fontWeight: segment.bold ? FontWeight.w800 : FontWeight.w400,
                      fontStyle: segment.italic ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                )
                .toList(),
          ),
        );
      case MessageType.lineChart:
      case MessageType.barChart:
      case MessageType.pieChart:
        return _ChartCard(message: message);
    }
  }
}

final mdExtensionSet = md.ExtensionSet.gitHubWeb;

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final chart = message.chart!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          chart.title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          chart.subtitle,
          style: const TextStyle(color: Color(0xFF64748B), height: 1.45),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: switch (message.type) {
            MessageType.lineChart => _LineChartView(chart: chart),
            MessageType.barChart => _BarChartView(chart: chart),
            MessageType.pieChart => _PieChartView(chart: chart),
            _ => const SizedBox.shrink(),
          },
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: chart.series
              .map(
                (item) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${item.label} ${item.value.toStringAsFixed(0)}'),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _LineChartView extends StatelessWidget {
  const _LineChartView({required this.chart});

  final ChartPayload chart;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= chart.series.length) {
                  return const SizedBox.shrink();
                }
                return Text(chart.series[index].label);
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: const Color(0xFF0F766E),
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
            ),
            spots: [
              for (var i = 0; i < chart.series.length; i++)
                FlSpot(i.toDouble(), chart.series[i].value),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarChartView extends StatelessWidget {
  const _BarChartView({required this.chart});

  final ChartPayload chart;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= chart.series.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(chart.series[index].label),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < chart.series.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: chart.series[i].value,
                  width: 22,
                  color: chart.series[i].color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PieChartView extends StatelessWidget {
  const _PieChartView({required this.chart});

  final ChartPayload chart;

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        centerSpaceRadius: 46,
        sectionsSpace: 3,
        sections: chart.series
            .map(
              (item) => PieChartSectionData(
                value: item.value,
                color: item.color,
                title: '${item.value.toStringAsFixed(0)}%',
                radius: 60,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
