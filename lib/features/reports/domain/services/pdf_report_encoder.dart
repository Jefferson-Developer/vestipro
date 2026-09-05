import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../entities/report_branding.dart';
import '../entities/report_catalog.dart';
import '../entities/report_definition.dart';
import '../entities/report_export_result.dart';
import '../entities/report_query_result.dart';
import 'report_column_value_type_resolver.dart';

/// Pure Dart PDF encoder for a [ReportQueryResult] (TASK-148). No
/// Flutter/Firebase dependency — safe to run on the calling isolate or
/// inside a background one (`compute`, wired by the data layer's
/// `PdfIsolateEncoder`, never here — same split already used by
/// `CsvReportEncoder`/`XlsxReportEncoder`, TASK-146/TASK-147).
///
/// Produces an executive-oriented document: a cover page (report title,
/// period, applied filters), one or more table pages (paginated
/// automatically by `pw.MultiPage`) and a footer with page number + the
/// generation instant on every page. [branding] is only ever applied when
/// [ReportBranding.isConfigured] is `true` (TASK-148's "branding só é
/// aplicado quando explicitamente configurado" rule) — otherwise
/// [_defaultBrandColor]/no logo is used instead, VestiPro's own default
/// identity, never a blank or broken-looking cover page.
///
/// Column *types* (date/currency/percentage/number/text) are resolved from
/// [ReportCatalog] via [ReportColumnValueTypeResolver] — the same schema the
/// report was built against — never guessed from the raw runtime value
/// alone, exactly like the XLSX encoder. Values displayed here are never
/// recomputed: they are the same values `result` already carries, which
/// itself came straight from the validated server-side aggregation
/// (TASK-133) — this encoder only formats, it never calculates.
final class PdfReportEncoder {
  const PdfReportEncoder({this.locale = ReportExportLocale.ptBr});

  final ReportExportLocale locale;

  /// VestiPro's own default brand color, used whenever the organization
  /// never configured [ReportBranding.primaryColorHex] — a dark slate that
  /// reads well as a header background with white text.
  static const PdfColor _defaultBrandColor = PdfColor.fromInt(0xFF0F172A);

  static final _periodPattern = RegExp(r'^(\d{4})-(\d{2})$');
  static const _monthNames = <String>[
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  Future<Uint8List> encodeToBytes({
    required ReportDefinition definition,
    required ReportQueryResult result,
    required ReportCatalog catalog,
    ReportBranding branding = const ReportBranding.none(),
  }) async {
    final document = pw.Document();
    final brandColor = _resolveColor(branding.primaryColorHex);
    final logo = branding.logoBytes == null
        ? null
        : pw.MemoryImage(branding.logoBytes!);
    final title = _buildTitle(definition, catalog);
    final periodLabel = _periodLabel(definition);
    final filterLines = _filterLines(definition, catalog);

    document.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(40),
        build: (context) => _buildCoverPage(
          title: title,
          periodLabel: periodLabel,
          filterLines: filterLines,
          generatedAt: result.generatedAt,
          rowCount: result.rows.length,
          brandColor: brandColor,
          logo: logo,
        ),
      ),
    );

    final valueTypes = <String, ReportValueType>{
      for (final column in result.columns)
        column: ReportColumnValueTypeResolver.resolve(column, catalog),
    };
    final headers = result.columns
        .map((id) => catalog.find(id)?.label ?? id)
        .toList(growable: false);
    final tableData = result.rows
        .map(
          (row) => result.columns
              .map((id) => _formatCell(row[id], valueTypes[id]!))
              .toList(growable: false),
        )
        .toList(growable: false);

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(32, 24, 32, 40),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(fontSize: 10, color: brandColor),
          ),
        ),
        footer: (context) => _buildFooter(context, result.generatedAt),
        build: (context) => <pw.Widget>[
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: tableData,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: pw.BoxDecoration(color: brandColor),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _buildCoverPage({
    required String title,
    required String periodLabel,
    required List<String> filterLines,
    required DateTime generatedAt,
    required int rowCount,
    required PdfColor brandColor,
    pw.MemoryImage? logo,
  }) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      if (logo != null)
        pw.Container(
          height: 64,
          margin: const pw.EdgeInsets.only(bottom: 24),
          child: pw.Image(logo, fit: pw.BoxFit.contain),
        )
      else
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 24),
          child: pw.Text(
            'VestiPro',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: brandColor,
            ),
          ),
        ),
      pw.Spacer(flex: 2),
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 26,
          fontWeight: pw.FontWeight.bold,
          color: brandColor,
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Text('Período: $periodLabel', style: const pw.TextStyle(fontSize: 13)),
      pw.SizedBox(height: 4),
      pw.Text(
        '$rowCount ${rowCount == 1 ? 'linha' : 'linhas'} de dados',
        style: const pw.TextStyle(fontSize: 13),
      ),
      if (filterLines.isNotEmpty) ...[
        pw.SizedBox(height: 16),
        pw.Text(
          'Filtros aplicados',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        ...filterLines.map(
          // A plain hyphen (never a Unicode bullet/em-dash): the default
          // Helvetica base-14 font `pw.Document` falls back to has no glyph
          // for "•"/"—", which would otherwise render as a missing-glyph box
          // on every generated PDF.
          (line) => pw.Text('- $line', style: const pw.TextStyle(fontSize: 11)),
        ),
      ],
      pw.Spacer(flex: 3),
      pw.Divider(color: PdfColors.grey400),
      pw.Text(
        'Gerado em ${_formatDateTime(generatedAt)}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
    ],
  );

  pw.Widget _buildFooter(pw.Context context, DateTime generatedAt) =>
      pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount} · '
          'Gerado em ${_formatDateTime(generatedAt)}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      );

  String _buildTitle(ReportDefinition definition, ReportCatalog catalog) {
    String labelFor(String id) => catalog.find(id)?.label ?? id;
    final dimensions = definition.dimensions.map(labelFor).join(' + ');
    final metrics = definition.metrics.map(labelFor).join(', ');
    if (dimensions.isEmpty && metrics.isEmpty) return 'Relatório personalizado';
    if (dimensions.isEmpty) return metrics;
    if (metrics.isEmpty) return dimensions;
    // A plain hyphen, not an em-dash — see the filter bullet's own doc above
    // for why: the default base-14 font has no glyph for "—".
    return '$dimensions - $metrics';
  }

  String _periodLabel(ReportDefinition definition) {
    final periodFilter = definition.filters
        .where((filter) => filter.fieldId == 'period')
        .toList();
    if (periodFilter.isEmpty) return 'Todos os períodos';
    final raw = periodFilter.first.value;
    final match = _periodPattern.firstMatch(raw);
    if (match == null) return raw;
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) return raw;
    return '${_monthNames[month - 1]} de ${match.group(1)}';
  }

  List<String> _filterLines(
    ReportDefinition definition,
    ReportCatalog catalog,
  ) {
    String labelFor(String id) => catalog.find(id)?.label ?? id;
    return definition.filters
        .map((filter) => '${labelFor(filter.fieldId)}: ${filter.value}')
        .toList(growable: false);
  }

  PdfColor _resolveColor(String? hex) {
    if (hex == null) return _defaultBrandColor;
    final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null || normalized.length != 6) return _defaultBrandColor;
    return PdfColor.fromInt(0xFF000000 | value);
  }

  String _formatCell(Object? value, ReportValueType type) {
    // A plain hyphen, never an em-dash — same base-14-font glyph rationale
    // as `_buildTitle`/the filter bullet above.
    if (value == null) return '-';
    return switch (type) {
      ReportValueType.date => _formatDateCell(value),
      ReportValueType.currency => _formatCurrency(value),
      ReportValueType.percentage => _formatPercentage(value),
      ReportValueType.number => _formatNumber(value),
      ReportValueType.text => value.toString(),
    };
  }

  String _formatDateCell(Object value) {
    if (value is String) {
      final match = _periodPattern.firstMatch(value);
      if (match != null) return '${match.group(2)}/${match.group(1)}';
      return value;
    }
    if (value is DateTime) {
      return '${value.month.toString().padLeft(2, '0')}/${value.year}';
    }
    return value.toString();
  }

  String _formatCurrency(Object value) {
    final number = _asDouble(value);
    if (number == null) return value.toString();
    final symbol = locale == ReportExportLocale.ptBr ? 'R\$ ' : r'$ ';
    return '$symbol${_formatDecimal(number, forceTwoDecimals: true)}';
  }

  String _formatPercentage(Object value) {
    final number = _asDouble(value);
    if (number == null) return value.toString();
    return '${_formatDecimal(number, forceTwoDecimals: true)}%';
  }

  String _formatNumber(Object value) {
    if (value is int) return _groupThousands(value.toString());
    final number = _asDouble(value);
    if (number == null) return value.toString();
    if (number == number.roundToDouble() && number.abs() < 1e15) {
      return _groupThousands(number.toInt().toString());
    }
    return _formatDecimal(number, forceTwoDecimals: false);
  }

  double? _asDouble(Object value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  String _formatDecimal(double value, {required bool forceTwoDecimals}) {
    if (!value.isFinite) return '0';
    final isWhole = value == value.roundToDouble() && value.abs() < 1e15;
    final fixed = (isWhole && !forceTwoDecimals)
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final grouped = _groupThousands(parts[0]);
    if (parts.length == 1) return grouped;
    return locale == ReportExportLocale.ptBr
        ? '$grouped,${parts[1]}'
        : '$grouped.${parts[1]}';
  }

  String _groupThousands(String digits) {
    final negative = digits.startsWith('-');
    final unsigned = negative ? digits.substring(1) : digits;
    final buffer = StringBuffer();
    final separator = locale == ReportExportLocale.ptBr ? '.' : ',';
    for (var i = 0; i < unsigned.length; i++) {
      if (i > 0 && (unsigned.length - i) % 3 == 0) buffer.write(separator);
      buffer.write(unsigned[i]);
    }
    return negative ? '-$buffer' : buffer.toString();
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${pad(local.day)}/${pad(local.month)}/${local.year} '
        '${pad(local.hour)}:${pad(local.minute)}';
  }
}
