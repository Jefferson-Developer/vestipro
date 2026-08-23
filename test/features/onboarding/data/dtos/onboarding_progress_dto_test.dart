import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/onboarding/data/dtos/onboarding_progress_dto.dart';

void main() {
  group('OnboardingProgressDto', () {
    test('toJson/fromJson round-trips every field, including segmentCode', () {
      const dto = OnboardingProgressDto(
        stepIndex: 2,
        organizationName: 'Grupo Fashion XPTO',
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
        segmentCode: 'apparel',
      );

      final roundTripped = OnboardingProgressDto.fromJson(dto.toJson());

      expect(roundTripped.stepIndex, dto.stepIndex);
      expect(roundTripped.organizationName, dto.organizationName);
      expect(roundTripped.currency, dto.currency);
      expect(roundTripped.country, dto.country);
      expect(roundTripped.defaultLanguage, dto.defaultLanguage);
      expect(roundTripped.segmentCode, dto.segmentCode);
    });

    test('omits segmentCode from toJson when null, and fromJson tolerates '
        'its absence', () {
      const dto = OnboardingProgressDto(
        stepIndex: 0,
        organizationName: '',
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
      );

      final json = dto.toJson();
      expect(json.containsKey('segmentCode'), isFalse);

      final roundTripped = OnboardingProgressDto.fromJson(json);
      expect(roundTripped.segmentCode, isNull);
    });

    test('throws ValidationException for a malformed payload', () {
      expect(
        () => OnboardingProgressDto.fromJson(<String, dynamic>{
          'stepIndex': 'not-an-int',
          'organizationName': 'Grupo Fashion XPTO',
          'currency': 'BRL',
          'country': 'BR',
          'defaultLanguage': 'pt-BR',
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
