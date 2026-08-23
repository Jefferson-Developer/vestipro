import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';
import '../../../organizations/domain/entities/organization.dart';
import '../../domain/value_objects/onboarding_step.dart';
import '../../domain/value_objects/organization_segment.dart';

part 'onboarding_state.freezed.dart';

/// Whether the saved progress has finished loading yet. Kept separate from
/// [OnboardingSubmissionStatus] — same rationale as `AboutAppState`'s own
/// initial/ready split: the wizard's fields have no meaningful value to
/// show until this reaches [OnboardingLoadStatus.ready].
enum OnboardingLoadStatus { loading, ready }

/// The outcome of the last [OnboardingEvent.submitted], kept separate from
/// the typed fields — same rationale as `SignUpSubmissionStatus` (TASK-035):
/// a failed submission never has to duplicate/clear what the user already
/// filled in.
enum OnboardingSubmissionStatus { idle, submitting, success, failure }

@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(OnboardingLoadStatus.loading) OnboardingLoadStatus loadStatus,
    @Default(OnboardingStep.organizationDetails) OnboardingStep step,
    @Default('') String organizationName,

    /// `null` until the current step has been submitted at least once (a
    /// [OnboardingEvent.nextStepRequested]/[OnboardingEvent.submitted] that
    /// found it invalid) or until a fresh edit clears the previous error —
    /// same contract as `SignUpState`'s per-field error strings.
    String? organizationNameError,
    OrganizationSegment? segment,
    String? segmentError,
    @Default('BRL') String currency,
    String? currencyError,
    @Default('BR') String country,
    String? countryError,
    @Default('pt-BR') String defaultLanguage,
    String? defaultLanguageError,
    @Default(OnboardingSubmissionStatus.idle)
    OnboardingSubmissionStatus submissionStatus,

    /// Only meaningful when [submissionStatus] is
    /// [OnboardingSubmissionStatus.failure].
    Failure? failure,

    /// Only meaningful when [submissionStatus] is
    /// [OnboardingSubmissionStatus.success] — the Organization the wizard
    /// just created, consumed by `OnboardingWizardPage` to navigate away
    /// with its real id.
    Organization? createdOrganization,
  }) = _OnboardingState;
}
