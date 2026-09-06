import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/product_import/data/parsers/csv_product_import_file_parser.dart';
import 'package:vestipro/features/product_import/domain/entities/product_import_preview.dart';

Uint8List _utf8(String text) => Uint8List.fromList(utf8.encode(text));

void main() {
  group('CsvProductImportFileParser', () {
    const parser = CsvProductImportFileParser();

    test('supports only .csv file names, case-insensitively', () {
      expect(parser.supports('produtos.csv'), isTrue);
      expect(parser.supports('PRODUTOS.CSV'), isTrue);
      expect(parser.supports('produtos.xlsx'), isFalse);
    });

    test('parses a valid comma-delimited CSV with header + sample rows', () {
      const csv =
          'sku,reference,name,colorName,sizeLabel\n'
          'CAMISA-01,REF-01,Camisa Social,Azul,M\n'
          'CAMISA-01,REF-01,Camisa Social,Azul,G\n';

      final preview = parser.parsePreview(
        fileName: 'produtos.csv',
        bytes: _utf8(csv),
      );

      expect(preview.isXlsx, isFalse);
      expect(preview.headers, <String>[
        'sku',
        'reference',
        'name',
        'colorName',
        'sizeLabel',
      ]);
      expect(preview.sampleRows, hasLength(2));
      expect(preview.sampleRows.first, <String>[
        'CAMISA-01',
        'REF-01',
        'Camisa Social',
        'Azul',
        'M',
      ]);
      expect(preview.totalRowsHint, 2);
    });

    test('auto-detects a semicolon delimiter (pt-BR Excel export)', () {
      const csv = 'sku;reference\nCAMISA-01;REF-01\n';

      final preview = parser.parsePreview(
        fileName: 'produtos.csv',
        bytes: _utf8(csv),
      );

      expect(preview.headers, <String>['sku', 'reference']);
      expect(preview.sampleRows.single, <String>['CAMISA-01', 'REF-01']);
    });

    test('preserves accentuation from a UTF-8 encoded file', () {
      const csv = 'name\nJaqueta Impermeável & Cia\n';

      final preview = parser.parsePreview(
        fileName: 'produtos.csv',
        bytes: _utf8(csv),
      );

      expect(preview.sampleRows.single.single, 'Jaqueta Impermeável & Cia');
    });

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
        final buffer = StringBuffer('sku\n');
        for (var i = 0; i < kProductImportPreviewRowLimit + 50; i += 1) {
          buffer.writeln('SKU-$i');
        }

        final preview = parser.parsePreview(
          fileName: 'grande.csv',
          bytes: _utf8(buffer.toString()),
        );

        expect(preview.sampleRows.length, kProductImportPreviewRowLimit);
      },
    );
  });
}
