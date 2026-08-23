import 'package:injectable/injectable.dart';

import '../../domain/entities/onboarding_progress.dart';
import '../../domain/value_objects/onboarding_step.dart';
import '../../domain/value_objects/organization_segment.dart';
import '../dtos/onboarding_progress_dto.dart';

@lazySingleton
final class OnboardingProgressMapper {
  const OnboardingProgressMapper();

  OnboardingProgress toEntity(OnboardingProgressDto dto) {
    final steps = OnboardingStep.values;
    final step = (dto.stepIndex >= 0 && dto.stepIndex < steps.length)
        ? steps[dto.stepIndex]
        // An out-of-range index (e.g. saved by a future app version with
        // more steps than this one knows about) falls back to the first
        // step instead of throwing — losing the exact resume point is far
        // better than losing the wizard entirely.
        : OnboardingStep.organizationDetails;

    return OnboardingProgress(
      step: step,
      organizationName: dto.organizationName,
      segment: organizationSegmentFromCode(dto.segmentCode),
      currency: dto.currency,
      country: dto.country,
      defaultLanguage: dto.defaultLanguage,
    );
  }

  OnboardingProgressDto toDto(OnboardingProgress entity) {
    return OnboardingProgressDto(
      stepIndex: entity.step.stepNumber - 1,
      organizationName: entity.organizationName,
      currency: entity.currency,
      country: entity.country,
      defaultLanguage: entity.defaultLanguage,
      segmentCode: entity.segment?.code,
    );
  }
}
