import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('BranchAddress.validated', () {
    test('trims every field and normalizes an empty complement to null', () {
      final address = BranchAddress.validated(
        street: ' Rua XV de Novembro ',
        number: ' 100 ',
        complement: '  ',
        neighborhood: ' Centro ',
        city: ' Blumenau ',
        state: ' SC ',
        postalCode: ' 89010-000 ',
        country: ' BR ',
      );

      expect(address.street, 'Rua XV de Novembro');
      expect(address.number, '100');
      expect(address.complement, isNull);
      expect(address.neighborhood, 'Centro');
      expect(address.city, 'Blumenau');
      expect(address.state, 'SC');
      expect(address.postalCode, '89010-000');
      expect(address.country, 'BR');
    });

    test('keeps a non-blank complement trimmed', () {
      final address = BranchAddress.validated(
        street: 'Rua XV de Novembro',
        number: '100',
        complement: ' Sala 2 ',
        neighborhood: 'Centro',
        city: 'Blumenau',
        state: 'SC',
        postalCode: '89010-000',
        country: 'BR',
      );

      expect(address.complement, 'Sala 2');
    });

    test('throws a ValidationException listing every blank required field', () {
      expect(
        () => BranchAddress.validated(
          street: '',
          number: '',
          neighborhood: '',
          city: '',
          state: '',
          postalCode: '',
          country: '',
        ),
        throwsA(
          isA<ValidationException>().having(
            (exception) => exception.fieldErrors.keys,
            'fieldErrors.keys',
            containsAll(<String>[
              'street',
              'number',
              'neighborhood',
              'city',
              'state',
              'postalCode',
              'country',
            ]),
          ),
        ),
      );
    });
  });
}
