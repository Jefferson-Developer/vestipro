import 'dart:convert';

import '../entities/report_export_result.dart';
import '../entities/report_query_result.dart';

/// Pure CSV encoder for a [ReportQueryResult] (TASK-146). No Flutter/Firebase
/// dependency — safe to run on the calling isolate or inside a background
/// one (`compute`/`Isolate.run`, wired by the data layer's
/// `CsvIsolateEncoder`, never here: isolate scheduling is a platform
/// concern, not a business rule).
///
/// Output always:
/// - Starts with a UTF-8 BOM (`encodeToBytes`), so Excel on pt-BR Windows
///   never mangles accented characters (critério de aceite do TASK-146).
/// - Uses `\r\n` line endings (the CSV "MS-DOS" convention every spreadsheet
///   reader — including Excel — expects).
/// - Ties delimiter and decimal separator together via [ReportExportLocale]:
///   pt-BR is always `;` + comma decimal, en-US is always `,` + dot decimal
///   — never mixed, which would make the file ambiguous to parse.
/// - Quotes a field (RFC4180-style, doubling embedded quotes) only when it
///   actually contains the delimiter, a quote or a line break.
final class CsvReportEncoder {
  const CsvReportEncoder({this.locale = ReportExportLocale.ptBr});

  final ReportExportLocale locale;

  String get _delimiter => locale == ReportExportLocale.ptBr ? ';' : ',';

  /// The full CSV text (header + rows), without the BOM — [encodeToBytes] is
  /// the entry point actually meant to be written to a file/uploaded.
  String encode(ReportQueryResult result) {
    final buffer = StringBuffer()
      ..write(result.columns.map(_encodeField).join(_delimiter))
      ..write('\r\n');
    for (final row in result.rows) {
      buffer
        ..write(
          result.columns
              .map((column) => _encodeField(_formatValue(row[column])))
              .join(_delimiter),
        )
        ..write('\r\n');
    }
    return buffer.toString();
  }

  /// UTF-8 bytes ready to be saved/uploaded as a `.csv` file, prefixed with
  /// the BOM Excel needs to detect UTF-8 (otherwise it defaults to the local
  /// codepage and corrupts accented pt-BR characters).
  List<int> encodeToBytes(ReportQueryResult result) => <int>[
    0xEF,
    0xBB,
    0xBF,
    ...utf8.encode(encode(result)),
  ];

  String _formatValue(Object? value) {
    if (value == null) return '';
    if (value is double) return _formatDecimal(value);
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }

  String _formatDecimal(double value) {
    if (!value.isFinite) return '';
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toStringAsFixed(0);
    }
    final fixed = value.toStringAsFixed(2);
    return locale == ReportExportLocale.ptBr
        ? fixed.replaceAll('.', ',')
        : fixed;
  }

  String _encodeField(String field) {
    final needsQuoting =
        field.contains(_delimiter) ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r');
    if (!needsQuoting) return field;
    return '"${field.replaceAll('"', '""')}"';
  }
}
