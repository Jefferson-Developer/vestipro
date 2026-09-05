import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xls;
import 'package:xml/xml.dart';

import '../entities/report_catalog.dart';
import '../entities/report_export_result.dart';
import '../entities/report_query_result.dart';
import 'report_column_value_type_resolver.dart';

/// Pure Dart XLSX encoder for a [ReportQueryResult] (TASK-147). No
/// Flutter/Firebase dependency — safe to run on the calling isolate or
/// inside a background one (`compute`/`Isolate.run`, wired by the data
/// layer's `XlsxIsolateEncoder`, never here — same split already used by
/// `CsvReportEncoder`/`CsvIsolateEncoder`, TASK-146).
///
/// Column *types* (date/currency/percentage/number/text) are never guessed
/// from the raw runtime value alone — they come from [catalog]
/// (`ReportColumnValueTypeResolver`), the same schema the report was built
/// against, so a metric like "Desconto médio" is always written as a real
/// percentage cell even though its raw value happens to be a plain `double`.
///
/// The underlying `excel` package has no built-in freeze-pane/AutoFilter
/// support, so both are applied by directly editing the generated archive's
/// worksheet XML (`_applyFreezeHeaderAndAutoFilter`) — a deliberate,
/// self-contained post-processing step instead of a second heavier/
/// commercially-licensed dependency (see `pubspec.yaml`'s comment on
/// `excel` for the full dependency trade-off).
final class XlsxReportEncoder {
  const XlsxReportEncoder({this.locale = ReportExportLocale.ptBr});

  final ReportExportLocale locale;

  static final _periodPattern = RegExp(r'^(\d{4})-(\d{2})$');

  /// Encodes [result] as `.xlsx` bytes: a single sheet with a bold, frozen
  /// header row, one column per `result.columns`, native `AutoFilter` on the
  /// header row, and every data cell typed per [catalog] (never as generic
  /// text). Produces a structurally valid workbook (header row only, no
  /// crash) even when `result.rows` is empty.
  List<int> encodeToBytes(ReportQueryResult result, ReportCatalog catalog) {
    final workbook = xls.Excel.createExcel();
    final sheetName = workbook.getDefaultSheet() ?? 'Sheet1';
    final sheet = workbook[sheetName];

    for (var column = 0; column < result.columns.length; column++) {
      final cell = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
      );
      cell.value = xls.TextCellValue(result.columns[column]);
      cell.cellStyle = xls.CellStyle(bold: true);
    }

    final valueTypes = <String, ReportValueType>{
      for (final column in result.columns)
        column: ReportColumnValueTypeResolver.resolve(column, catalog),
    };

    for (var row = 0; row < result.rows.length; row++) {
      final data = result.rows[row];
      for (var column = 0; column < result.columns.length; column++) {
        final columnId = result.columns[column];
        final plan = _planCell(data[columnId], valueTypes[columnId]!);
        final cell = sheet.cell(
          xls.CellIndex.indexByColumnRow(
            columnIndex: column,
            rowIndex: row + 1,
          ),
        );
        cell.value = plan.value;
        if (plan.style != null) cell.cellStyle = plan.style;
      }
    }

    final rawBytes = workbook.encode();
    if (rawBytes == null) {
      throw StateError('excel package failed to encode the workbook.');
    }
    return _applyFreezeHeaderAndAutoFilter(
      rawBytes,
      columnCount: result.columns.length,
      // +1 for the header row; at least 1 so `AutoFilter`/`dimension`
      // always cover the header even when `result.rows` is empty.
      rowCount: result.rows.length + 1,
    );
  }

  _CellPlan _planCell(Object? value, ReportValueType valueType) {
    if (value == null) return _CellPlan(xls.TextCellValue(''), null);
    switch (valueType) {
      case ReportValueType.date:
        return _planDate(value);
      case ReportValueType.currency:
        return _planCurrency(value);
      case ReportValueType.percentage:
        return _planPercentage(value);
      case ReportValueType.number:
        return _planNumber(value);
      case ReportValueType.text:
        return _CellPlan(xls.TextCellValue(value.toString()), null);
    }
  }

  _CellPlan _planDate(Object? value) {
    final DateTime? parsed;
    if (value is DateTime) {
      parsed = value;
    } else if (value is String) {
      final match = _periodPattern.firstMatch(value);
      parsed = match == null
          ? null
          : DateTime(int.parse(match.group(1)!), int.parse(match.group(2)!));
    } else {
      parsed = null;
    }
    if (parsed == null) {
      return _CellPlan(xls.TextCellValue(value.toString()), null);
    }
    return _CellPlan(
      xls.DateCellValue(year: parsed.year, month: parsed.month, day: 1),
      // `yyyy-mm` (never a locale-dependent month name) so the rendered
      // text is unambiguous regardless of which Excel language the file is
      // opened in — the underlying value is still a real Excel date
      // (serial number), never a string, satisfying TASK-147's "data como
      // data" requirement.
      xls.CellStyle(numberFormat: xls.NumFormat.custom(formatCode: 'yyyy-mm')),
    );
  }

  _CellPlan _planCurrency(Object? value) {
    final number = _asDouble(value);
    if (number == null) {
      return _CellPlan(xls.TextCellValue(value.toString()), null);
    }
    return _CellPlan(
      xls.DoubleCellValue(number),
      xls.CellStyle(
        numberFormat: xls.NumFormat.custom(formatCode: _currencyFormatCode),
      ),
    );
  }

  _CellPlan _planPercentage(Object? value) {
    final number = _asDouble(value);
    if (number == null) {
      return _CellPlan(xls.TextCellValue(value.toString()), null);
    }
    // The aggregation already returns a percentage in "human" units (e.g.
    // `12.34` meaning 12.34%, see `execute-report-query.ts`'s
    // `averageDiscount`/`ChangePercent`), but Excel's own `%` number format
    // multiplies the stored value by 100 for display — so it must be
    // divided back to the `0.1234` fractional form here, or the sheet would
    // render "1234.00%" for a 12.34% value.
    return _CellPlan(
      xls.DoubleCellValue(number / 100),
      xls.CellStyle(numberFormat: xls.NumFormat.standard_10),
    );
  }

  _CellPlan _planNumber(Object? value) {
    if (value is int) {
      return _CellPlan(
        xls.IntCellValue(value),
        xls.CellStyle(numberFormat: xls.NumFormat.standard_3),
      );
    }
    final number = _asDouble(value);
    if (number == null) {
      return _CellPlan(xls.TextCellValue(value.toString()), null);
    }
    if (number == number.roundToDouble() && number.abs() < 1e15) {
      return _CellPlan(
        xls.IntCellValue(number.toInt()),
        xls.CellStyle(numberFormat: xls.NumFormat.standard_3),
      );
    }
    return _CellPlan(
      xls.DoubleCellValue(number),
      xls.CellStyle(numberFormat: xls.NumFormat.standard_4),
    );
  }

  String get _currencyFormatCode =>
      locale == ReportExportLocale.ptBr ? '"R\$" #,##0.00' : r'"$" #,##0.00';

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  /// Injects a frozen header row (`<pane .../>`) and a native `AutoFilter`
  /// (`<autoFilter ref="A1:..."/>`) into the single worksheet `excel`
  /// generated — neither is exposed by the package's public API, so this
  /// edits `xl/worksheets/sheet*.xml` directly inside the already-zipped
  /// archive [bytes] and re-zips it, leaving every other part (styles,
  /// shared strings, workbook metadata) untouched.
  List<int> _applyFreezeHeaderAndAutoFilter(
    List<int> bytes, {
    required int columnCount,
    required int rowCount,
  }) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final sheetFile = archive.files.firstWhere(
      (file) => RegExp(r'^xl/worksheets/sheet\d+\.xml$').hasMatch(file.name),
      orElse: () => throw StateError(
        'excel package did not produce a worksheet XML part.',
      ),
    );
    final document = XmlDocument.parse(
      utf8.decode(sheetFile.content as List<int>),
    );
    final worksheet = document.rootElement;
    final lastColumn = _columnLetter(columnCount == 0 ? 0 : columnCount - 1);
    final range = 'A1:$lastColumn$rowCount';

    final dimension = worksheet.getElement('dimension');
    dimension?.setAttribute('ref', range);

    worksheet.findElements('sheetViews').forEach((views) {
      views.children.clear();
      views.children.add(_frozenHeaderSheetView());
    });

    worksheet.children.removeWhere(
      (node) => node is XmlElement && node.name.local == 'autoFilter',
    );
    final sheetDataIndex = worksheet.children.indexWhere(
      (node) => node is XmlElement && node.name.local == 'sheetData',
    );
    worksheet.children.insert(
      sheetDataIndex + 1,
      XmlElement(XmlName('autoFilter'), [XmlAttribute(XmlName('ref'), range)]),
    );

    final updatedXml = utf8.encode(document.toXmlString());
    final updatedArchive = Archive();
    for (final file in archive.files) {
      if (file.name == sheetFile.name) {
        updatedArchive.addFile(
          ArchiveFile(file.name, updatedXml.length, updatedXml),
        );
      } else {
        updatedArchive.addFile(file);
      }
    }
    final encoded = ZipEncoder().encode(updatedArchive);
    if (encoded == null) {
      throw StateError('Failed to re-encode the XLSX archive.');
    }
    return encoded;
  }

  XmlElement _frozenHeaderSheetView() => XmlElement(
    XmlName('sheetView'),
    [XmlAttribute(XmlName('workbookViewId'), '0')],
    [
      XmlElement(XmlName('pane'), [
        XmlAttribute(XmlName('ySplit'), '1'),
        XmlAttribute(XmlName('topLeftCell'), 'A2'),
        XmlAttribute(XmlName('activePane'), 'bottomLeft'),
        XmlAttribute(XmlName('state'), 'frozen'),
      ]),
      XmlElement(XmlName('selection'), [
        XmlAttribute(XmlName('pane'), 'bottomLeft'),
        XmlAttribute(XmlName('activeCell'), 'A2'),
        XmlAttribute(XmlName('sqref'), 'A2'),
      ]),
    ],
  );

  static String _columnLetter(int zeroBasedIndex) {
    var index = zeroBasedIndex;
    var letters = '';
    do {
      letters = String.fromCharCode(65 + (index % 26)) + letters;
      index = (index ~/ 26) - 1;
    } while (index >= 0);
    return letters;
  }
}

final class _CellPlan {
  const _CellPlan(this.value, this.style);
  final xls.CellValue value;
  final xls.CellStyle? style;
}
