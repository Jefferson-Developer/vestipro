/// The 4 sequential steps of the initial Organization configuration wizard
/// (TASK-038): organization details, fashion segment, regional settings
/// (currency/country) and initial preferences (default language).
///
/// Declaration order is significant: [OnboardingStep.values] is the order
/// the wizard is walked through, and [OnboardingStepX.stepNumber]/
/// [kOnboardingTotalSteps] both derive from it — never hardcode a step's
/// position anywhere else.
enum OnboardingStep {
  organizationDetails,
  segment,
  regionalSettings,
  preferences,
}

/// Total number of steps in the wizard — always [OnboardingStep.values]'
/// length, never a separately maintained literal.
final int kOnboardingTotalSteps = OnboardingStep.values.length;

extension OnboardingStepX on OnboardingStep {
  /// 1-based position of this step, for the "Passo X de Y" progress
  /// indicator (`AppWizardStepper`) — never 0-based outside this file.
  int get stepNumber => OnboardingStep.values.indexOf(this) + 1;

  /// The step that follows this one, or `null` when this is already the
  /// last step ([OnboardingStep.preferences]).
  OnboardingStep? get next {
    final nextIndex = OnboardingStep.values.indexOf(this) + 1;
    if (nextIndex >= OnboardingStep.values.length) return null;
    return OnboardingStep.values[nextIndex];
  }

  /// The step that precedes this one, or `null` when this is already the
  /// first step ([OnboardingStep.organizationDetails]).
  OnboardingStep? get previous {
    final previousIndex = OnboardingStep.values.indexOf(this) - 1;
    if (previousIndex < 0) return null;
    return OnboardingStep.values[previousIndex];
  }

  bool get isLast => this == OnboardingStep.values.last;
}
