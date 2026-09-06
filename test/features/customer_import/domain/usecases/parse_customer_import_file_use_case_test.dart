import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customer_import/customer_import.dart';

class _MockFileParser extends Mock implements CustomerImportFileParser {}

void main() {
  group('ParseCustomerImportFileUseCase', () {
    late _MockFileParser csvParser;
    late _MockFileParser xlsxParser;
    late ParseCustomerImportFileUseCase useCase;

    setUpAll(() {
      registerFallbackValue(Uint8List(0));
    });

    setUp(() {
      csvParser = _MockFileParser();
      xlsxParser = _MockFileParser();
      useCase = ParseCustomerImportFileUseCase(<CustomerImportFileParser>[
        csvParser,
        xlsxParser,
      ]);
    });

    test('rejects a file above the max size before touching any parser', () {
      final oversized = Uint8List(kCustomerImportMaxFileSizeBytes + 1);

      final result = useCase(fileName: 'clientes.csv', bytes: oversized);

      expect(result, isA<AppFailure<CustomerImportPreview>>());
      verifyNever(() => csvParser.supports(any()));
    });

    test('picks the CSV parser for a .csv file name', () {
      when(() => csvParser.supports('clientes.csv')).thenReturn(true);
      when(() => xlsxParser.supports('clientes.csv')).thenReturn(false);
      when(
        () => csvParser.parsePreview(
          fileName: any(named: 'fileName'),
          bytes: any(named: 'bytes'),
        ),
      ).thenReturn(
        const CustomerImportPreview(
          fileName: 'clientes.csv',
          isXlsx: false,
          headers: <String>['document'],
          sampleRows: <List<String>>[
            <String>['11222333000181'],
          ],
        ),
      );

      final result = useCase(
        fileName: 'clientes.csv',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
      );

      expect(result, isA<AppSuccess<CustomerImportPreview>>());
      verify(
        () => csvParser.parsePreview(
          fileName: 'clientes.csv',
          bytes: any(named: 'bytes'),
        ),
      ).called(1);
      verifyNever(
        () => xlsxParser.parsePreview(
          fileName: any(named: 'fileName'),
          bytes: any(named: 'bytes'),
        ),
      );
    });

    test('fails validation for a file extension no parser supports', () {
      when(() => csvParser.supports(any())).thenReturn(false);
      when(() => xlsxParser.supports(any())).thenReturn(false);

      final result = useCase(
        fileName: 'clientes.pdf',
        bytes: Uint8List.fromList(<int>[1]),
      );

      expect(result, isA<AppFailure<CustomerImportPreview>>());
    });

    test(
      'fails validation when the parser returns no headers (empty spreadsheet)',
      () {
        when(() => csvParser.supports(any())).thenReturn(true);
        when(
          () => csvParser.parsePreview(
            fileName: any(named: 'fileName'),
            bytes: any(named: 'bytes'),
          ),
        ).thenReturn(
          const CustomerImportPreview(
            fileName: 'vazio.csv',
            isXlsx: false,
            headers: <String>[],
            sampleRows: <List<String>>[],
          ),
        );

        final result = useCase(
          fileName: 'vazio.csv',
          bytes: Uint8List.fromList(<int>[1]),
        );

        expect(result, isA<AppFailure<CustomerImportPreview>>());
      },
    );

    test(
      'converts a CustomerImportParseException into a validation failure',
      () {
        when(() => csvParser.supports(any())).thenReturn(true);
        when(
          () => csvParser.parsePreview(
            fileName: any(named: 'fileName'),
            bytes: any(named: 'bytes'),
          ),
        ).thenThrow(const CustomerImportParseException('Arquivo corrompido.'));

        final result = useCase(
          fileName: 'corrompido.csv',
          bytes: Uint8List.fromList(<int>[1]),
        );

        expect(result, isA<AppFailure<CustomerImportPreview>>());
      },
    );
  });
}
