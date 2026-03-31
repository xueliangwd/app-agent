import 'dart:io';

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
            constraints: const BoxConstraints(maxWidth: 720),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: DefaultTextStyle(
              style: TextStyle(color: textColor, height: 1.55, fontSize: 15),
              child: _MessageContent(message: message, textColor: textColor, isUser: _isUser),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.message,
    required this.textColor,
    required this.isUser,
  });

  final ChatMessage message;
  final Color textColor;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Text(message.text ?? '');
      case MessageType.markdown:
        return _MarkdownText(data: message.text ?? '', textColor: textColor);
      case MessageType.richText:
        return _RichTextBlock(segments: message.richSegments, textColor: textColor);
      case MessageType.lineChart:
      case MessageType.barChart:
      case MessageType.pieChart:
        return _ChartCard(message: message);
      case MessageType.blocks:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < message.blocks.length; i++) ...[
              _ContentBlockView(
                block: message.blocks[i],
                textColor: textColor,
                isUser: isUser,
              ),
              if (i != message.blocks.length - 1) const SizedBox(height: 14),
            ],
          ],
        );
    }
  }
}

class _ContentBlockView extends StatelessWidget {
  const _ContentBlockView({
    required this.block,
    required this.textColor,
    required this.isUser,
  });

  final ContentBlock block;
  final Color textColor;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case ContentBlockType.text:
        return Text(block.text ?? '');
      case ContentBlockType.markdown:
        return _MarkdownText(data: block.text ?? '', textColor: textColor);
      case ContentBlockType.richText:
        return _RichTextBlock(segments: block.richSegments, textColor: textColor);
      case ContentBlockType.code:
        return _CodeCard(code: block.code!, isUser: isUser);
      case ContentBlockType.quote:
        return _QuoteCard(text: block.text ?? '');
      case ContentBlockType.latex:
        return _LabelCard(
          icon: Icons.functions,
          title: 'LaTeX / 数学公式',
          subtitle: block.text ?? '',
        );
      case ContentBlockType.mermaid:
        return _LabelCard(
          icon: Icons.account_tree_outlined,
          title: 'Mermaid 图示',
          subtitle: block.text ?? '',
        );
      case ContentBlockType.image:
        return _ImageCard(item: block.images.first);
      case ContentBlockType.gallery:
        return _GalleryCard(images: block.images);
      case ContentBlockType.file:
        return _FileCard(block.file!);
      case ContentBlockType.webCard:
        return _WebCard(block.webCard!);
      case ContentBlockType.audio:
        return _MediaCard(
          icon: Icons.graphic_eq_rounded,
          title: block.media!.title,
          meta: block.media!.durationLabel,
          summary: block.media!.summary,
        );
      case ContentBlockType.video:
        return _MediaCard(
          icon: Icons.smart_display_outlined,
          title: block.media!.title,
          meta: block.media!.durationLabel,
          summary: block.media!.summary,
        );
      case ContentBlockType.taskResult:
        return _TaskResultCard(block.taskResult!);
      case ContentBlockType.lineChart:
      case ContentBlockType.barChart:
      case ContentBlockType.pieChart:
        return _BlockChartCard(block: block);
    }
  }
}

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.data, required this.textColor});

  final String data;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubWeb,
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
  }
}

class _RichTextBlock extends StatelessWidget {
  const _RichTextBlock({required this.segments, required this.textColor});

  final List<RichSegment> segments;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: segments
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
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFF0F766E), width: 4),
        ),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF334155))),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code, required this.isUser});

  final CodePayload code;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF0B3F39) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                code.title ?? '代码块',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  code.language,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            code.source,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontFamily: 'monospace',
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPreview(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: item.aspectRatio,
              child: _buildImage(),
            ),
            if (item.caption != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(item.caption!, style: const TextStyle(color: Color(0xFF64748B))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (item.localPath != null && item.localPath!.isNotEmpty) {
      return Image.file(
        File(item.localPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _FallbackVisual(title: item.title),
      );
    }
    return Image.network(
      item.url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _FallbackVisual(title: item.title),
    );
  }

  void _showPreview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(child: _buildImage()),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({required this.images});

  final List<MediaItem> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = images[index];
          final imageWidget = item.localPath != null && item.localPath!.isNotEmpty
              ? Image.file(
                  File(item.localPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _FallbackVisual(title: item.title),
                )
              : Image.network(
                  item.url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _FallbackVisual(title: item.title),
                );
          return GestureDetector(
            onTap: () => _ImageCard(item: item)._showPreview(context),
            child: SizedBox(
              width: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: imageWidget,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FallbackVisual extends StatelessWidget {
  const _FallbackVisual({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFCBD5E1), Color(0xFFE2E8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
        ),
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard(this.file);

  final FileAttachment file;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              file.extension.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF0F766E),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '${file.sizeLabel}${file.summary == null ? '' : ' · ${file.summary}'}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WebCard extends StatelessWidget {
  const _WebCard(this.card);

  final WebCardPayload card;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.domain, style: const TextStyle(color: Color(0xFF0F766E), fontSize: 12)),
          const SizedBox(height: 4),
          Text(card.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(card.summary, style: const TextStyle(color: Color(0xFF475569), height: 1.45)),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.icon,
    required this.title,
    required this.meta,
    this.summary,
  });

  final IconData icon;
  final String title;
  final String meta;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF0F766E)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(meta, style: const TextStyle(color: Color(0xFF64748B))),
                if (summary != null) ...[
                  const SizedBox(height: 4),
                  Text(summary!, style: const TextStyle(color: Color(0xFF475569))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskResultCard extends StatelessWidget {
  const _TaskResultCard(this.payload);

  final TaskResultPayload payload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(payload.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  payload.status,
                  style: const TextStyle(
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in payload.items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7, right: 8),
                  child: Icon(Icons.circle, size: 6, color: Color(0xFF0F766E)),
                ),
                Expanded(child: Text(item)),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _LabelCard extends StatelessWidget {
  const _LabelCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0F766E)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                SelectableText(subtitle, style: const TextStyle(color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockChartCard extends StatelessWidget {
  const _BlockChartCard({required this.block});

  final ContentBlock block;

  @override
  Widget build(BuildContext context) {
    return _ChartBody(type: block.type, chart: block.chart!);
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return _ChartBody(type: _mapMessageType(message.type), chart: message.chart!);
  }
}

ContentBlockType _mapMessageType(MessageType type) {
  switch (type) {
    case MessageType.lineChart:
      return ContentBlockType.lineChart;
    case MessageType.barChart:
      return ContentBlockType.barChart;
    case MessageType.pieChart:
      return ContentBlockType.pieChart;
    case MessageType.text:
    case MessageType.markdown:
    case MessageType.richText:
    case MessageType.blocks:
      return ContentBlockType.text;
  }
}

class _ChartBody extends StatelessWidget {
  const _ChartBody({required this.type, required this.chart});

  final ContentBlockType type;
  final ChartPayload chart;

  @override
  Widget build(BuildContext context) {
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
          child: switch (type) {
            ContentBlockType.lineChart => _LineChartView(chart: chart),
            ContentBlockType.barChart => _BarChartView(chart: chart),
            ContentBlockType.pieChart => _PieChartView(chart: chart),
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
