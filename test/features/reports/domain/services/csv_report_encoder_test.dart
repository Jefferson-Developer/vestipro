import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/reports/reports.dart';

void main() {
  group('CsvReportEncoder (TASK-146)', () {
    test(
      'encodeToBytes prefixes a UTF-8 BOM so Excel opens pt-BR accents correctly',
      () {
        final encoder = const CsvReportEncoder();
        final result = ReportQueryResult(
          columns: const <String>['cliente'],
          rows: const <Map<String, Object?>>[
            <String, Object?>{'cliente': 'João Ação'},
          ],
          generatedAt: DateTime(2026, 9, 4),
        );
        final bytes = encoder.encodeToBytes(result);
        expect(bytes.take(3), <int>[0xEF, 0xBB, 0xBF]);
        final decoded = utf8.decode(bytes.skip(3).toList());
        expect(decoded, contains('João Ação'));
      },
    );

    test(
      'pt-BR locale uses semicolon delimiter and comma decimal separator',
      () {
        final encoder = const CsvReportEncoder(locale: ReportExportLocale.ptBr);
        final result = ReportQueryResult(
          columns: const <String>['cliente', 'faturamento'],
          rows: const <Map<String, Object?>>[
            <String, Object?>{'cliente': 'Loja A', 'faturamento': 1234.5},
          ],
          generatedAt: DateTime(2026, 9, 4),
        );
        final csv = encoder.encode(result);
        expect(csv, contains('cliente;faturamento'));
        expect(csv, contains('Loja A;1234,50'));
      },
    );

    test('en-US locale uses comma delimiter and dot decimal separator', () {
      final encoder = const CsvReportEncoder(locale: ReportExportLocale.enUs);
      final result = ReportQueryResult(
        columns: const <String>['revenue'],
        rows: const <Map<String, Object?>>[
          <String, Object?>{'revenue': 99.9},
        ],
        generatedAt: DateTime(2026, 9, 4),
      );
      final csv = encoder.encode(result);
      expect(csv, contains('revenue'));
      expect(csv, contains('99.90'));
    });

    test(
      'quotes fields containing the delimiter, a quote or a line break, doubling embedded quotes',
      () {
        final encoder = const CsvReportEncoder();
        final result = ReportQueryResult(
          columns: const <String>['observacao'],
          rows: const <Map<String, Object?>>[
            <String, Object?>{'observacao': 'Loja "Central"; Filial\nSul'},
          ],
          generatedAt: DateTime(2026, 9, 4),
        );
        final csv = encoder.encode(result);
        expect(csv, contains('"Loja ""Central""; Filial\nSul"'));
      },
    );

    test(
      'renders null values as an empty field and integer-valued doubles without decimals',
      () {
        final encoder = const CsvReportEncoder();
        final result = ReportQueryResult(
          columns: const <String>['pedidos', 'observacao'],
          rows: const <Map<String, Object?>>[
            <String, Object?>{'pedidos': 12.0, 'observacao': null},
          ],
          generatedAt: DateTime(2026, 9, 4),
        );
        final lines = encoder.encode(result).split('\r\n');
        expect(lines[1], '12;');
      },
    );

    test('a field that is just an integer is never quoted or reformatted', () {
      final encoder = const CsvReportEncoder();
      final result = ReportQueryResult(
        columns: const <String>['pedidos'],
        rows: const <Map<String, Object?>>[
          <String, Object?>{'pedidos': 7},
        ],
        generatedAt: DateTime(2026, 9, 4),
      );
      final lines = encoder.encode(result).split('\r\n');
      expect(lines[1], '7');
    });
  });
}
