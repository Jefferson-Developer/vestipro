import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('OrganizationSettings.validated', () {
    test('builds trimmed settings from valid values', () {
      final settings = OrganizationSettings.validated(
        currency: ' BRL ',
        country: ' BR ',
        defaultLanguage: ' pt-BR ',
      );

      expect(settings.currency, 'BRL');
      expect(settings.country, 'BR');
      expect(settings.defaultLanguage, 'pt-BR');
    });

    test('throws ValidationException when currency is blank', () {
      expect(
        () => OrganizationSettings.validated(
          currency: '  ',
          country: 'BR',
          defaultLanguage: 'pt-BR',
        ),
        throwsA(
          isA<ValidationException>().having(
            (exception) => exception.fieldErrors.containsKey('currency'),
            'fieldErrors has currency',
            isTrue,
          ),
        ),
      );
    });

    test('throws ValidationException reporting every blank field', () {
      try {
        OrganizationSettings.validated(
          currency: '',
          country: '',
          defaultLanguage: '',
        );
        fail('Expected a ValidationException.');
      } on ValidationException catch (exception) {
        expect(
          exception.fieldErrors.keys,
          containsAll(<String>['currency', 'country', 'defaultLanguage']),
        );
        expect(exception.code, 'invalid_organization_settings');
      }
    });

    test('trims a non-blank segment', () {
      final settings = OrganizationSettings.validated(
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
        segment: ' apparel ',
      );

      expect(settings.segment, 'apparel');
    });

    test('normalizes a blank segment to null instead of rejecting it', () {
      final settings = OrganizationSettings.validated(
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
        segment: '   ',
      );

      expect(settings.segment, isNull);
    });

    test('defaults segment to null when not provided', () {
      final settings = OrganizationSettings.validated(
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
      );

      expect(settings.segment, isNull);
    });
  });
}
