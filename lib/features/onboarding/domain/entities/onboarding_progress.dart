import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/onboarding_step.dart';
import '../value_objects/organization_segment.dart';

part 'onboarding_progress.freezed.dart';

/// The wizard's answers-so-far plus the step the user was on, persisted
/// locally (TASK-038) so the wizard resumes exactly where the user left it
/// if the app is closed before [OnboardingStep.preferences] is completed.
///
/// [currency]/[country]/[defaultLanguage] default to sensible values instead
/// of blank, so the regional-settings/preferences steps start pre-filled and
/// never block completion by themselves — only [organizationName] and
/// [segment] are the "hard" minimum the business rule requires
/// (`docs/tasks/TASK-038-*.md`, "Regras de negócio e restrições").
@freezed
abstract class OnboardingProgress with _$OnboardingProgress {
  const factory OnboardingProgress({
    @Default(OnboardingStep.organizationDetails) OnboardingStep step,
    @Default('') String organizationName,
    OrganizationSegment? segment,
    @Default('BRL') String currency,
    @Default('BR') String country,
    @Default('pt-BR') String defaultLanguage,
  }) = _OnboardingProgress;
}
