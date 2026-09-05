import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xls;
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/reports/reports.dart';

void main() {
  group('XlsxReportEncoder (TASK-147)', () {
    const catalog = ReportCatalog(
      fields: <ReportFieldDefinition>[
        ReportFieldDefinition(
          id: 'period',
          label: 'Período',
          type: ReportFieldType.dimension,
          valueType: ReportValueType.date,
        ),
        ReportFieldDefinition(
          id: 'customer',
          label: 'Cliente',
          type: ReportFieldType.dimension,
          valueType: ReportValueType.text,
        ),
        ReportFieldDefinition(
          id: 'revenueNet',
          label: 'Faturamento líquido',
          type: ReportFieldType.metric,
          valueType: ReportValueType.currency,
        ),
        ReportFieldDefinition(
          id: 'averageDiscount',
          label: 'Desconto médio',
          type: ReportFieldType.metric,
          valueType: ReportValueType.percentage,
        ),
        ReportFieldDefinition(
          id: 'orderCount',
          label: 'Pedidos',
          type: ReportFieldType.metric,
          valueType: ReportValueType.number,
        ),
      ],
    );

    ReportQueryResult resultWithOneRow() => ReportQueryResult(
      columns: const <String>[
        'period',
        'customer',
        'revenueNet',
        'averageDiscount',
        'orderCount',
      ],
      rows: const <Map<String, Object?>>[
        <String, Object?>{
          'period': '2026-09',
          'customer': 'João Ação',
          'revenueNet': 1234.56,
          'averageDiscount': 12.5,
          'orderCount': 7,
        },
      ],
      generatedAt: DateTime(2026, 9, 4),
    );

    test('every column is written with its real (non-text) cell type', () {
      final bytes = const XlsxReportEncoder().encodeToBytes(
        resultWithOneRow(),
        catalog,
      );
      final workbook = xls.Excel.decodeBytes(bytes);
      final sheet = workbook.tables.values.single;

      xls.Data cellAt(int column, int row) => sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
      );

      // Header row: plain text, bold.
      expect(cellAt(1, 0).value, isA<xls.TextCellValue>());
      expect(cellAt(1, 0).value.toString(), 'customer');
      expect(cellAt(1, 0).cellStyle?.isBold, isTrue);

      // period -> a real date, never a string.
      final period = cellAt(0, 1).value;
      expect(period, isA<xls.DateCellValue>());
      final periodDate = (period as xls.DateCellValue).asDateTimeUtc();
      expect(periodDate.year, 2026);
      expect(periodDate.month, 9);

      // customer -> plain text, accents preserved.
      expect(cellAt(1, 1).value, isA<xls.TextCellValue>());
      expect(cellAt(1, 1).value.toString(), 'João Ação');

      // revenueNet -> a real number (currency), never text.
      final revenue = cellAt(2, 1).value;
      expect(revenue, isA<xls.DoubleCellValue>());
      expect((revenue as xls.DoubleCellValue).value, closeTo(1234.56, 0.001));

      // averageDiscount (12.5 "human" percent) -> stored as the 0.125
      // fraction Excel's own `%` format expects, never as "12.5" as-is.
      final discount = cellAt(3, 1).value;
      expect(discount, isA<xls.DoubleCellValue>());
      expect((discount as xls.DoubleCellValue).value, closeTo(0.125, 0.0001));

      // orderCount -> a plain integer.
      final orders = cellAt(4, 1).value;
      expect(orders, isA<xls.IntCellValue>());
      expect((orders as xls.IntCellValue).value, 7);
    });

    test(
      'produces a structurally valid workbook (header only) when there are no rows',
      () {
        final emptyResult = ReportQueryResult(
          columns: const <String>['customer', 'revenueNet'],
          rows: const <Map<String, Object?>>[],
          generatedAt: DateTime(2026, 9, 4),
        );
        final bytes = const XlsxReportEncoder().encodeToBytes(
          emptyResult,
          catalog,
        );
        final workbook = xls.Excel.decodeBytes(bytes);
        final sheet = workbook.tables.values.single;
        expect(sheet.maxRows, 1);
        expect(
          sheet
              .cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
              .value
              .toString(),
          'customer',
        );
      },
    );

    test('a null value is written as an empty text cell, never a crash', () {
      final result = ReportQueryResult(
        columns: const <String>['customer', 'revenueNet'],
        rows: const <Map<String, Object?>>[
          <String, Object?>{'customer': null, 'revenueNet': 10.0},
        ],
        generatedAt: DateTime(2026, 9, 4),
      );
      final bytes = const XlsxReportEncoder().encodeToBytes(result, catalog);
      final workbook = xls.Excel.decodeBytes(bytes);
      final sheet = workbook.tables.values.single;
      final cell = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      );
      expect(cell.value.toString(), '');
    });

    test(
      'applies a frozen header row and a native AutoFilter over the full data range',
      () {
        final bytes = const XlsxReportEncoder().encodeToBytes(
          resultWithOneRow(),
          catalog,
        );
        // `excel` has no public API for freeze panes/AutoFilter, so this
        // asserts directly against the generated worksheet XML instead of
        // going through the package's own (read-only-for-these-features)
        // decoder.
        final archive = ZipDecoder().decodeBytes(bytes);
        final sheetXml = utf8.decode(
          archive.files
                  .firstWhere(
                    (file) => RegExp(
                      r'^xl/worksheets/sheet\d+\.xml$',
                    ).hasMatch(file.name),
                  )
                  .content
              as List<int>,
        );
        expect(sheetXml, contains('<pane'));
        expect(sheetXml, contains('state="frozen"'));
        expect(sheetXml, contains('ySplit="1"'));
        // 5 columns (A..E), 1 header + 1 data row = 2 rows.
        expect(sheetXml, contains('<autoFilter ref="A1:E2"/>'));
      },
    );
  });
}
