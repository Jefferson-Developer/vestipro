import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/onboarding/domain/validators/onboarding_step_validators.dart';
import 'package:vestipro/features/onboarding/domain/value_objects/organization_segment.dart';

void main() {
  group('validateOrganizationName', () {
    test('rejects a blank value', () {
      expect(validateOrganizationName(''), isNotNull);
      expect(validateOrganizationName('   '), isNotNull);
    });

    test('rejects a name shorter than 2 characters', () {
      expect(validateOrganizationName('A'), isNotNull);
    });

    test('accepts a plausible name', () {
      expect(validateOrganizationName('Grupo Fashion XPTO'), isNull);
    });
  });

  group('validateOrganizationSegment', () {
    test('rejects null', () {
      expect(validateOrganizationSegment(null), isNotNull);
    });

    test('accepts any selected segment', () {
      for (final segment in OrganizationSegment.values) {
        expect(validateOrganizationSegment(segment), isNull);
      }
    });
  });

  group('validateCurrency/validateCountry/validateDefaultLanguage', () {
    test('reject blank values', () {
      expect(validateCurrency(''), isNotNull);
      expect(validateCountry('   '), isNotNull);
      expect(validateDefaultLanguage(''), isNotNull);
    });

    test('accept non-blank values', () {
      expect(validateCurrency('BRL'), isNull);
      expect(validateCountry('BR'), isNull);
      expect(validateDefaultLanguage('pt-BR'), isNull);
    });
  });
}
