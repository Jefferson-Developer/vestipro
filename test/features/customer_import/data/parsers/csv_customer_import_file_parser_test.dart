import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/customer_import/data/parsers/csv_customer_import_file_parser.dart';
import 'package:vestipro/features/customer_import/domain/entities/customer_import_preview.dart';

Uint8List _utf8(String text) => Uint8List.fromList(utf8.encode(text));

void main() {
  group('CsvCustomerImportFileParser', () {
    const parser = CsvCustomerImportFileParser();

    test('supports only .csv file names, case-insensitively', () {
      expect(parser.supports('clientes.csv'), isTrue);
      expect(parser.supports('CLIENTES.CSV'), isTrue);
      expect(parser.supports('clientes.xlsx'), isFalse);
    });

    test('parses a valid comma-delimited CSV with header + sample rows', () {
      const csv =
          'document,legalName,primaryEmail\n'
          '11222333000181,Acme Ltda,contato@acme.com\n'
          '52998224725,,maria@example.com\n';

      final preview = parser.parsePreview(
        fileName: 'clientes.csv',
        bytes: _utf8(csv),
      );

      expect(preview.isXlsx, isFalse);
      expect(preview.headers, <String>[
        'document',
        'legalName',
        'primaryEmail',
      ]);
      expect(preview.sampleRows, hasLength(2));
      expect(preview.sampleRows.first, <String>[
        '11222333000181',
        'Acme Ltda',
        'contato@acme.com',
      ]);
      expect(preview.totalRowsHint, 2);
    });

    test('auto-detects a semicolon delimiter (pt-BR Excel export)', () {
      const csv = 'document;legalName\n11222333000181;Acme Ltda\n';

      final preview = parser.parsePreview(
        fileName: 'clientes.csv',
        bytes: _utf8(csv),
      );

      expect(preview.headers, <String>['document', 'legalName']);
      expect(preview.sampleRows.single, <String>[
        '11222333000181',
        'Acme Ltda',
      ]);
    });

    test(
      'columns out of order are still read positionally, unaffected by header naming',
      () {
        const csv =
            'primaryEmail,document,legalName\n'
            'contato@acme.com,11222333000181,Acme Ltda\n';

        final preview = parser.parsePreview(
          fileName: 'clientes.csv',
          bytes: _utf8(csv),
        );

        expect(preview.headers, <String>[
          'primaryEmail',
          'document',
          'legalName',
        ]);
        expect(preview.sampleRows.single, <String>[
          'contato@acme.com',
          '11222333000181',
          'Acme Ltda',
        ]);
      },
    );

    test('preserves accentuation from a UTF-8 encoded file', () {
      const csv = 'legalName\nAssociação São José & Cia\n';

      final preview = parser.parsePreview(
        fileName: 'clientes.csv',
        bytes: _utf8(csv),
      );

      expect(preview.sampleRows.single.single, 'Associação São José & Cia');
    });

    test(
      'handles quoted fields with an embedded delimiter and escaped quotes',
      () {
        const csv = 'legalName,segment\n"Acme, Ltda","Diz ""Confecções"""\n';

        final preview = parser.parsePreview(
          fileName: 'clientes.csv',
          bytes: _utf8(csv),
        );

        expect(preview.sampleRows.single, <String>[
          'Acme, Ltda',
          'Diz "Confecções"',
        ]);
      },
    );

    test(
      'strips a UTF-8 BOM instead of treating it as part of the first header',
      () {
        final bytes = Uint8List.fromList(<int>[
          0xEF,
          0xBB,
          0xBF,
          ...utf8.encode('document\n11222333000181\n'),
        ]);

        final preview = parser.parsePreview(
          fileName: 'clientes.csv',
          bytes: bytes,
        );

        expect(preview.headers, <String>['document']);
      },
    );

    test('returns an empty preview for a genuinely empty file', () {
      final preview = parser.parsePreview(
        fileName: 'vazio.csv',
        bytes: Uint8List(0),
      );

      expect(preview.headers, isEmpty);
      expect(preview.sampleRows, isEmpty);
    });

    test(
      'never throws on malformed/corrupted bytes — degrades instead of crashing',
      () {
        // Invalid UTF-8 continuation bytes with no valid leading byte.
        final corrupted = Uint8List.fromList(<int>[0xFF, 0xFE, 0x00, 0x01]);

        expect(
          () =>
              parser.parsePreview(fileName: 'corrompido.csv', bytes: corrupted),
          returnsNormally,
        );
      },
    );

    test(
      'never parses more than the preview row limit, regardless of file size',
      () {
        final buffer = StringBuffer('document\n');
        for (var i = 0; i < kCustomerImportPreviewRowLimit + 50; i += 1) {
          buffer.writeln('$i');
        }

        final preview = parser.parsePreview(
          fileName: 'grande.csv',
          bytes: _utf8(buffer.toString()),
        );

        expect(preview.sampleRows.length, kCustomerImportPreviewRowLimit);
      },
    );
  });
}
