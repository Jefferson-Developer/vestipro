import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/value_objects/organization_segment.dart';

part 'onboarding_event.freezed.dart';

@freezed
sealed class OnboardingEvent with _$OnboardingEvent {
  /// Loads any saved progress for the signed-in user, so the wizard resumes
  /// exactly where it was left (TASK-038). Dispatched once, right when
  /// `OnboardingWizardPage` is built.
  const factory OnboardingEvent.started() = OnboardingStarted;

  const factory OnboardingEvent.organizationNameChanged(
    String organizationName,
  ) = OnboardingOrganizationNameChanged;

  const factory OnboardingEvent.segmentSelected(OrganizationSegment segment) =
      OnboardingSegmentSelected;

  const factory OnboardingEvent.currencyChanged(String currency) =
      OnboardingCurrencyChanged;

  const factory OnboardingEvent.countryChanged(String country) =
      OnboardingCountryChanged;

  const factory OnboardingEvent.defaultLanguageChanged(String defaultLanguage) =
      OnboardingDefaultLanguageChanged;

  /// Validates the current step and, only if it passes, advances to the
  /// next one. Never fired from the last step — that step's primary action
  /// is [OnboardingEvent.submitted] instead.
  const factory OnboardingEvent.nextStepRequested() =
      OnboardingNextStepRequested;

  /// Moves back one step without any validation, preserving every answer
  /// already typed.
  const factory OnboardingEvent.previousStepRequested() =
      OnboardingPreviousStepRequested;

  /// Completes the wizard: re-validates every required field and, if they
  /// pass, creates the Organization.
  const factory OnboardingEvent.submitted() = OnboardingSubmitted;
}
