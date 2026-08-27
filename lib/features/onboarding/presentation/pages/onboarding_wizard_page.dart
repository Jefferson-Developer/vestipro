import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/navigation.dart';
import '../../domain/value_objects/onboarding_step.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../widgets/onboarding_step_views.dart';

/// The step titles shown by `AppWizardStepper`, in [OnboardingStep] order.
const List<String> _kOnboardingStepLabels = <String>[
  'Dados da organização',
  'Segmento',
  'Moeda e país',
  'Preferências iniciais',
];

/// The initial Organization configuration wizard (TASK-038), shown right
/// after sign-up creates the Firebase Auth account (TASK-035): the
/// Organization itself is only created once this wizard's last step is
/// submitted, via `CompleteOnboardingUseCase`.
///
/// Never talks to `OnboardingProgressRepository`/`OrganizationRepository`
/// itself — every field edit, step navigation and the final submit are
/// dispatched to [OnboardingBloc], same rationale as `SignUpPage`
/// (TASK-035).
class OnboardingWizardPage extends StatelessWidget {
  const OnboardingWizardPage({required this.createBloc, super.key});

  final OnboardingBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OnboardingBloc>(
      create: (_) => createBloc()..add(const OnboardingEvent.started()),
      child: const _OnboardingWizardView(),
    );
  }
}

class _OnboardingWizardView extends StatelessWidget {
  const _OnboardingWizardView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocListener<OnboardingBloc, OnboardingState>(
        listenWhen: (previous, current) =>
            previous.submissionStatus != current.submissionStatus,
        listener: (context, state) {
          switch (state.submissionStatus) {
            case OnboardingSubmissionStatus.success:
              final organization = state.createdOrganization;
              if (organization != null) {
                context.go(CatalogHomeRoute(orgId: organization.id).location);
              }
            case OnboardingSubmissionStatus.failure:
              final failure = state.failure;
              if (failure != null) {
                AppSnackbar.show(
                  context,
                  message: failure.message,
                  variant: AppSnackbarVariant.error,
                );
              }
            case OnboardingSubmissionStatus.idle:
            case OnboardingSubmissionStatus.submitting:
              break;
          }
        },
        child: SafeArea(
          child: BlocBuilder<OnboardingBloc, OnboardingState>(
            builder: (context, state) {
              if (state.loadStatus == OnboardingLoadStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              return _OnboardingWizardContent(state: state);
            },
          ),
        ),
      ),
    );
  }
}

class _OnboardingWizardContent extends StatelessWidget {
  const _OnboardingWizardContent({required this.state});

  final OnboardingState state;

  Widget _stepView(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.organizationDetails =>
        const OnboardingOrganizationDetailsStep(),
      OnboardingStep.segment => const OnboardingSegmentStep(),
      OnboardingStep.regionalSettings => const OnboardingRegionalSettingsStep(),
      OnboardingStep.preferences => const OnboardingPreferencesStep(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        state.submissionStatus == OnboardingSubmissionStatus.submitting;
    final isLastStep = state.step.isLast;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spacing24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppWizardStepper(
                currentStep: state.step.stepNumber,
                stepLabels: _kOnboardingStepLabels,
              ),
              const SizedBox(height: AppSpacing.spacing32),
              _stepView(state.step),
              const SizedBox(height: AppSpacing.spacing32),
              Row(
                children: <Widget>[
                  if (state.step.previous != null) ...<Widget>[
                    Expanded(
                      child: AppButton(
                        label: 'Voltar',
                        variant: AppButtonVariant.secondary,
                        isDisabled: isSubmitting,
                        onPressed: () => context.read<OnboardingBloc>().add(
                          const OnboardingEvent.previousStepRequested(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spacing16),
                  ],
                  Expanded(
                    child: AppButton(
                      label: isLastStep ? 'Concluir' : 'Continuar',
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () => context.read<OnboardingBloc>().add(
                              isLastStep
                                  ? const OnboardingEvent.submitted()
                                  : const OnboardingEvent.nextStepRequested(),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
