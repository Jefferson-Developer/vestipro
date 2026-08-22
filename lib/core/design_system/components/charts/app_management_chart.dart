import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import '../buttons/app_icon_button.dart';
import '../feedback/app_empty_state.dart';

/// The chart shape rendered by [AppManagementChart].
///
/// Deliberately limited to `line`/`bar`: management dashboards compare a
/// metric across periods/segments, which both shapes read clearly at a
/// glance. A pie/donut chart is intentionally **not** offered here — pies
/// stop being legible past a handful of categories, and every dataset this
/// component targets (monthly revenue, ranking, funnel stages, ...) tends to
/// have more categories than that. A feature that genuinely needs a
/// two/three-slice proportion chart should build it as its own small
/// component, not extend this one.
enum AppChartType {
  /// A connected line per series — best for a trend over an ordered period
  /// (e.g. revenue per month).
  line,

  /// Grouped bars per category — best for comparing discrete categories
  /// (e.g. revenue per collection).
  bar,
}

/// A single data point of an [AppChartSeries].
///
/// [x] is kept for the caller's own bookkeeping (e.g. a timestamp) but
/// [AppManagementChart] lays points out by their *position* in
/// [AppChartSeries.points] (all series are assumed aligned by index — e.g.
/// "January" is index 0 in every series being compared). [label] is what
/// renders under the x-axis for that position; when omitted, the position's
/// 1-based index is shown instead.
@immutable
class AppChartPoint {
  const AppChartPoint({required this.x, required this.y, this.label});

  final double x;
  final double y;
  final String? label;
}

/// A named series of [points] plotted by [AppManagementChart]. When [color]
/// is omitted, the chart assigns one from its default palette by series
/// order.
@immutable
class AppChartSeries {
  const AppChartSeries({required this.label, required this.points, this.color});

  final String label;
  final List<AppChartPoint> points;
  final Color? color;
}

/// The base management chart every dashboard (executivo, vendas, metas,
/// funil, ...) reuses for a line/bar visualization of one or more
/// [AppChartSeries].
///
/// [AppManagementChart] never computes the values it plots — [series] is
/// already-aggregated data supplied by the domain/BLoC layer (see
/// `flutter-senior-architect`'s server-side aggregation).
///
/// Accessibility: the chart is always wrapped in a [Semantics] node carrying
/// a generated textual summary of every series/value, and a toggle button
/// lets any user (not only screen-reader users) switch to a plain data table
/// with the exact same numbers — the chart's own colors/shapes are never the
/// only way to read the data.
///
/// ```dart
/// AppManagementChart(
///   type: AppChartType.line,
///   series: [
///     AppChartSeries(
///       label: 'Faturamento',
///       points: [
///         AppChartPoint(x: 1, y: 42000, label: 'Jan'),
///         AppChartPoint(x: 2, y: 51000, label: 'Fev'),
///       ],
///     ),
///   ],
/// )
/// ```
class AppManagementChart extends StatefulWidget {
  const AppManagementChart({
    super.key,
    required this.type,
    required this.series,
    this.height = 220,
    this.emptyTitle = 'Sem dados para exibir',
    this.emptyDescription,
    this.valueFormatter,
    this.tableToggleSemanticLabel = 'Ver dados em formato de tabela',
    this.chartToggleSemanticLabel = 'Ver dados em formato de gráfico',
  });

  final AppChartType type;
  final List<AppChartSeries> series;
  final double height;

  final String emptyTitle;
  final String? emptyDescription;

  /// Formats a raw value for the axis labels, the accessible summary and
  /// the underlying data table. Defaults to a plain integer string —
  /// currency/percentage formatting is a domain/localization concern, not a
  /// Design System one, so callers with formatted needs should format
  /// [AppChartPoint.y] themselves upstream and pass a matching formatter.
  final String Function(double value)? valueFormatter;

  final String tableToggleSemanticLabel;
  final String chartToggleSemanticLabel;

  @override
  State<AppManagementChart> createState() => _AppManagementChartState();
}

class _AppManagementChartState extends State<AppManagementChart> {
  bool _showTable = false;

  bool get _isEmpty =>
      widget.series.isEmpty || widget.series.every((s) => s.points.isEmpty);

  String Function(double) get _formatter =>
      widget.valueFormatter ?? (value) => value.toStringAsFixed(0);

  String _buildAccessibleSummary() {
    final formatter = _formatter;
    final typeLabel = widget.type == AppChartType.line ? 'linha' : 'barra';
    final buffer = StringBuffer(
      'Gráfico de $typeLabel com ${widget.series.length} série(s). ',
    );
    for (final series in widget.series) {
      buffer.write('${series.label}: ');
      buffer.write(
        series.points
            .asMap()
            .entries
            .map(
              (entry) =>
                  '${entry.value.label ?? 'posição ${entry.key + 1}'}: '
                  '${formatter(entry.value.y)}',
            )
            .join(', '),
      );
      buffer.write('. ');
    }
    return buffer.toString();
  }

  List<Color> _palette(AppColors colors) => <Color>[
    colors.primary,
    colors.secondary,
    colors.success,
    colors.warning,
    colors.info,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isEmpty) {
      return SizedBox(
        height: widget.height,
        child: AppEmptyState(
          title: widget.emptyTitle,
          description: widget.emptyDescription,
          icon: Icons.show_chart,
        ),
      );
    }

    return Semantics(
      label: _buildAccessibleSummary(),
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _buildLegend(colors)),
              AppIconButton(
                icon: _showTable
                    ? Icons.show_chart
                    : Icons.table_chart_outlined,
                semanticLabel: _showTable
                    ? widget.chartToggleSemanticLabel
                    : widget.tableToggleSemanticLabel,
                onPressed: () => setState(() => _showTable = !_showTable),
              ),
            ],
          ),
          SizedBox(
            height: widget.height,
            child: _showTable
                ? _AppChartDataTable(
                    series: widget.series,
                    formatter: _formatter,
                  )
                : CustomPaint(
                    size: Size.infinite,
                    painter: _AppChartPainter(
                      type: widget.type,
                      series: widget.series,
                      gridColor: colors.outline.withValues(alpha: 0.2),
                      axisTextStyle: AppTypography.bodySmall.copyWith(
                        color: colors.outline,
                      ),
                      palette: _palette(colors),
                      valueFormatter: _formatter,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(AppColors colors) {
    final palette = _palette(colors);
    return Wrap(
      spacing: AppSpacing.spacing16,
      runSpacing: AppSpacing.spacing4,
      children: List<Widget>.generate(widget.series.length, (index) {
        final series = widget.series[index];
        final color = series.color ?? palette[index % palette.length];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: AppSpacing.spacing12,
              height: AppSpacing.spacing12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.spacing4),
            Text(
              series.label,
              style: AppTypography.bodySmall.copyWith(color: colors.onSurface),
            ),
          ],
        );
      }),
    );
  }
}

/// The accessible, exact-value alternative to the painted chart — the
/// "tabela de dados subjacente" required alongside every management chart.
class _AppChartDataTable extends StatelessWidget {
  const _AppChartDataTable({required this.series, required this.formatter});

  final List<AppChartSeries> series;
  final String Function(double) formatter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: series
            .map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      s.label,
                      style: AppTypography.labelLarge.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    for (var i = 0; i < s.points.length; i++)
                      Text(
                        '${s.points[i].label ?? 'Posição ${i + 1}'}: '
                        '${formatter(s.points[i].y)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.outline,
                        ),
                      ),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _AppChartPainter extends CustomPainter {
  _AppChartPainter({
    required this.type,
    required this.series,
    required this.gridColor,
    required this.axisTextStyle,
    required this.palette,
    required this.valueFormatter,
  });

  final AppChartType type;
  final List<AppChartSeries> series;
  final Color gridColor;
  final TextStyle axisTextStyle;
  final List<Color> palette;
  final String Function(double) valueFormatter;

  static const double _leftAxisWidth = 44;
  static const double _bottomAxisHeight = 20;
  static const int _gridLineCount = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final allPoints = series.expand((s) => s.points).toList(growable: false);
    if (allPoints.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    final chartRect = Rect.fromLTWH(
      _leftAxisWidth,
      0,
      math.max(size.width - _leftAxisWidth, 0),
      math.max(size.height - _bottomAxisHeight, 0),
    );

    double minY = allPoints.first.y;
    double maxY = allPoints.first.y;
    for (final point in allPoints) {
      minY = math.min(minY, point.y);
      maxY = math.max(maxY, point.y);
    }
    if (minY > 0) {
      minY = 0;
    }
    if (maxY < 0) {
      maxY = 0;
    }
    if (maxY == minY) {
      maxY = minY + 1;
    }
    final range = maxY - minY;

    _paintGrid(canvas, chartRect, minY, maxY);

    final rawMaxCount = series
        .map((s) => s.points.length)
        .fold<int>(0, math.max);
    final maxCount = rawMaxCount < 1 ? 1 : rawMaxCount;
    final slotWidth = chartRect.width / maxCount;

    double yFor(double value) =>
        chartRect.bottom - ((value - minY) / range) * chartRect.height;

    switch (type) {
      case AppChartType.line:
        _paintLines(canvas, chartRect, slotWidth, yFor);
      case AppChartType.bar:
        _paintBars(canvas, chartRect, slotWidth, yFor);
    }

    _paintXAxisLabels(canvas, chartRect, slotWidth, maxCount);
  }

  void _paintGrid(Canvas canvas, Rect chartRect, double minY, double maxY) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 0; i <= _gridLineCount; i++) {
      final t = i / _gridLineCount;
      final y = chartRect.bottom - t * chartRect.height;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        paint,
      );

      final value = minY + t * (maxY - minY);
      _paintText(
        canvas,
        valueFormatter(value),
        Offset(0, y - 6),
        maxWidth: _leftAxisWidth - 4,
        alignRight: true,
      );
    }
  }

  void _paintLines(
    Canvas canvas,
    Rect chartRect,
    double slotWidth,
    double Function(double) yFor,
  ) {
    for (var s = 0; s < series.length; s++) {
      final points = series[s].points;
      if (points.isEmpty) {
        continue;
      }
      final color = series[s].color ?? palette[s % palette.length];
      final linePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final dotPaint = Paint()..color = color;

      final offsets = <Offset>[
        for (var i = 0; i < points.length; i++)
          Offset(chartRect.left + (i + 0.5) * slotWidth, yFor(points[i].y)),
      ];

      if (offsets.length == 1) {
        canvas.drawCircle(offsets.first, 3, dotPaint);
        continue;
      }

      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (final offset in offsets.skip(1)) {
        path.lineTo(offset.dx, offset.dy);
      }
      canvas.drawPath(path, linePaint);
      for (final offset in offsets) {
        canvas.drawCircle(offset, 3, dotPaint);
      }
    }
  }

  void _paintBars(
    Canvas canvas,
    Rect chartRect,
    double slotWidth,
    double Function(double) yFor,
  ) {
    final seriesCount = math.max(series.length, 1);
    final groupWidth = slotWidth * 0.7;
    final barWidth = groupWidth / seriesCount;
    final baselineY = yFor(0);

    for (var s = 0; s < series.length; s++) {
      final color = series[s].color ?? palette[s % palette.length];
      final barPaint = Paint()..color = color;
      final points = series[s].points;

      for (var i = 0; i < points.length; i++) {
        final slotStart =
            chartRect.left + i * slotWidth + (slotWidth - groupWidth) / 2;
        final barLeft = slotStart + s * barWidth;
        final barTop = math.min(yFor(points[i].y), baselineY);
        final barBottom = math.max(yFor(points[i].y), baselineY);
        canvas.drawRect(
          Rect.fromLTRB(barLeft, barTop, barLeft + barWidth, barBottom),
          barPaint,
        );
      }
    }
  }

  void _paintXAxisLabels(
    Canvas canvas,
    Rect chartRect,
    double slotWidth,
    int maxCount,
  ) {
    for (var i = 0; i < maxCount; i++) {
      final label = series
          .map((s) => i < s.points.length ? s.points[i].label : null)
          .firstWhere((l) => l != null, orElse: () => null);
      final text = label ?? '${i + 1}';
      final center = chartRect.left + (i + 0.5) * slotWidth;
      _paintText(
        canvas,
        text,
        Offset(center - slotWidth / 2, chartRect.bottom + 2),
        maxWidth: slotWidth,
        centered: true,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset, {
    double maxWidth = 100,
    bool alignRight = false,
    bool centered = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: axisTextStyle),
      textDirection: TextDirection.ltr,
      textAlign: centered ? TextAlign.center : TextAlign.left,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    final dx = alignRight ? offset.dx + (maxWidth - painter.width) : offset.dx;
    painter.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _AppChartPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.series != series ||
        oldDelegate.gridColor != gridColor;
  }
}
