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

    test('defaults allowMultipleCollectionsPerProduct to false (TASK-066)', () {
      final settings = OrganizationSettings.validated(
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
      );

      expect(settings.allowMultipleCollectionsPerProduct, isFalse);
    });

    test('accepts allowMultipleCollectionsPerProduct set to true', () {
      final settings = OrganizationSettings.validated(
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
        allowMultipleCollectionsPerProduct: true,
      );

      expect(settings.allowMultipleCollectionsPerProduct, isTrue);
    });

    test('defaults stockReservationExpiresInMinutes to 15', () {
      final settings = OrganizationSettings.validated(
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
      );

      expect(settings.stockReservationExpiresInMinutes, 15);
    });

    test('rejects stockReservationExpiresInMinutes below the safe window', () {
      expect(
        () => OrganizationSettings.validated(
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
          stockReservationExpiresInMinutes: 10,
        ),
        throwsA(
          isA<ValidationException>().having(
            (exception) => exception.fieldErrors.containsKey(
              'stockReservationExpiresInMinutes',
            ),
            'fieldErrors has stockReservationExpiresInMinutes',
            isTrue,
          ),
        ),
      );
    });

    test('defaults positivação fields (TASK-117) when not provided', () {
      final settings = OrganizationSettings.validated(
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
      );

      expect(settings.positivacaoPeriodGranularity, 'monthly');
      expect(
        settings.positivacaoEligibleOrderStatuses,
        defaultPositivacaoEligibleOrderStatuses,
      );
      expect(settings.positivacaoMinOrderValue, isNull);
    });

    test('accepts a custom positivação rule (TASK-117)', () {
      final settings = OrganizationSettings.validated(
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
        positivacaoPeriodGranularity: 'quarterly',
        positivacaoEligibleOrderStatuses: <String>['invoiced', 'delivered'],
        positivacaoMinOrderValue: 250,
      );

      expect(settings.positivacaoPeriodGranularity, 'quarterly');
      expect(settings.positivacaoEligibleOrderStatuses, <String>[
        'delivered',
        'invoiced',
      ]);
      expect(settings.positivacaoMinOrderValue, 250);
    });

    test('rejects an unknown positivacaoPeriodGranularity', () {
      expect(
        () => OrganizationSettings.validated(
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
          positivacaoPeriodGranularity: 'weekly',
        ),
        throwsA(
          isA<ValidationException>().having(
            (exception) => exception.fieldErrors.containsKey(
              'positivacaoPeriodGranularity',
            ),
            'fieldErrors has positivacaoPeriodGranularity',
            isTrue,
          ),
        ),
      );
    });

    test('rejects an empty positivacaoEligibleOrderStatuses list', () {
      expect(
        () => OrganizationSettings.validated(
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
          positivacaoEligibleOrderStatuses: const <String>[],
        ),
        throwsA(
          isA<ValidationException>().having(
            (exception) => exception.fieldErrors.containsKey(
              'positivacaoEligibleOrderStatuses',
            ),
            'fieldErrors has positivacaoEligibleOrderStatuses',
            isTrue,
          ),
        ),
      );
    });

    test('rejects a negative positivacaoMinOrderValue', () {
      expect(
        () => OrganizationSettings.validated(
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
          positivacaoMinOrderValue: -1,
        ),
        throwsA(
          isA<ValidationException>().having(
            (exception) =>
                exception.fieldErrors.containsKey('positivacaoMinOrderValue'),
            'fieldErrors has positivacaoMinOrderValue',
            isTrue,
          ),
        ),
      );
    });
  });
}
