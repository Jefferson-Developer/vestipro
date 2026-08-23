import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/onboarding/data/dtos/onboarding_progress_dto.dart';
import 'package:vestipro/features/onboarding/data/mappers/onboarding_progress_mapper.dart';
import 'package:vestipro/features/onboarding/domain/entities/onboarding_progress.dart';
import 'package:vestipro/features/onboarding/domain/value_objects/onboarding_step.dart';
import 'package:vestipro/features/onboarding/domain/value_objects/organization_segment.dart';

void main() {
  group('OnboardingProgressMapper', () {
    const mapper = OnboardingProgressMapper();

    test('toEntity maps every field, including the segment code', () {
      const dto = OnboardingProgressDto(
        stepIndex: 1,
        organizationName: 'Grupo Fashion XPTO',
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
        segmentCode: 'footwear',
      );

      final entity = mapper.toEntity(dto);

      expect(entity.step, OnboardingStep.segment);
      expect(entity.organizationName, 'Grupo Fashion XPTO');
      expect(entity.segment, OrganizationSegment.footwear);
      expect(entity.currency, 'BRL');
      expect(entity.country, 'BR');
      expect(entity.defaultLanguage, 'pt-BR');
    });

    test('toEntity falls back to the first step for an out-of-range index', () {
      const dto = OnboardingProgressDto(
        stepIndex: 99,
        organizationName: 'Grupo Fashion XPTO',
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
      );

      final entity = mapper.toEntity(dto);

      expect(entity.step, OnboardingStep.organizationDetails);
    });

    test('toDto is the exact inverse of toEntity', () {
      const progress = OnboardingProgress(
        step: OnboardingStep.regionalSettings,
        organizationName: 'Grupo Fashion XPTO',
        segment: OrganizationSegment.accessories,
        currency: 'USD',
        country: 'US',
        defaultLanguage: 'en-US',
      );

      final dto = mapper.toDto(progress);
      final roundTrippedEntity = mapper.toEntity(dto);

      expect(roundTrippedEntity, progress);
    });
  });
}
