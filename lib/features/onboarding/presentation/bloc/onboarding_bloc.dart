import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/auth/auth.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/entities/organization.dart';
import '../../domain/entities/onboarding_progress.dart';
import '../../domain/usecases/clear_onboarding_progress_use_case.dart';
import '../../domain/usecases/complete_onboarding_use_case.dart';
import '../../domain/usecases/get_onboarding_progress_use_case.dart';
import '../../domain/usecases/save_onboarding_progress_use_case.dart';
import '../../domain/validators/onboarding_step_validators.dart';
import '../../domain/value_objects/onboarding_step.dart';
import '../../domain/value_objects/organization_segment.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// Drives the initial Organization configuration wizard (TASK-038): loading/
/// resuming saved progress, per-step field edits and validation, step
/// navigation and the final submit against [CompleteOnboardingUseCase].
///
/// `OnboardingWizardPage`/its step widgets never talk to
/// [GetOnboardingProgressUseCase]/[SaveOnboardingProgressUseCase]/
/// [CompleteOnboardingUseCase]/[AuthRepository] directly — every state
/// transition goes through this bloc, same rationale as `SignUpBloc`
/// (TASK-035).
@injectable
final class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({
    required this.getProgress,
    required this.saveProgress,
    required this.clearProgress,
    required this.completeOnboarding,
    required this.authRepository,
    required this.analyticsService,
  }) : super(const OnboardingState()) {
    on<OnboardingStarted>(_onStarted, transformer: droppable());
    on<OnboardingOrganizationNameChanged>(
      _onOrganizationNameChanged,
      transformer: sequential(),
    );
    on<OnboardingSegmentSelected>(
      _onSegmentSelected,
      transformer: sequential(),
    );
    on<OnboardingCurrencyChanged>(
      _onCurrencyChanged,
      transformer: sequential(),
    );
    on<OnboardingCountryChanged>(_onCountryChanged, transformer: sequential());
    on<OnboardingDefaultLanguageChanged>(
      _onDefaultLanguageChanged,
      transformer: sequential(),
    );
    on<OnboardingNextStepRequested>(
      _onNextStepRequested,
      transformer: sequential(),
    );
    on<OnboardingPreviousStepRequested>(
      _onPreviousStepRequested,
      transformer: sequential(),
    );
    on<OnboardingSubmitted>(_onSubmitted, transformer: droppable());
  }

  final GetOnboardingProgressUseCase getProgress;
  final SaveOnboardingProgressUseCase saveProgress;
  final ClearOnboardingProgressUseCase clearProgress;
  final CompleteOnboardingUseCase completeOnboarding;
  final AuthRepository authRepository;
  final AnalyticsService analyticsService;

  /// `null` when there is no signed-in user — should never happen in
  /// practice (the wizard route is only reachable right after sign-up/
  /// sign-in), but every use of it is still guarded defensively instead of
  /// assumed.
  String? get _userId => authRepository.currentUser?.uid;

  Future<void> _onStarted(
    OnboardingStarted event,
    Emitter<OnboardingState> emit,
  ) async {
    final userId = _userId;
    if (userId == null) {
      emit(state.copyWith(loadStatus: OnboardingLoadStatus.ready));
      return;
    }

    final result = await getProgress(userId: userId);
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<OnboardingProgress?>(value: final progress):
        if (progress == null) {
          emit(state.copyWith(loadStatus: OnboardingLoadStatus.ready));
          return;
        }
        emit(
          state.copyWith(
            loadStatus: OnboardingLoadStatus.ready,
            step: progress.step,
            organizationName: progress.organizationName,
            segment: progress.segment,
            currency: progress.currency,
            country: progress.country,
            defaultLanguage: progress.defaultLanguage,
          ),
        );
      case AppFailure<OnboardingProgress?>():
        // A local-cache read failure must never block the wizard: fall back
        // to a clean slate, exactly like a missing/corrupted cache entry
        // already does one layer below (see
        // `SharedPreferencesOnboardingProgressDataSource`'s own doc).
        emit(state.copyWith(loadStatus: OnboardingLoadStatus.ready));
    }
  }

  Future<void> _onOrganizationNameChanged(
    OnboardingOrganizationNameChanged event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(
      state.copyWith(
        organizationName: event.organizationName,
        organizationNameError: null,
      ),
    );
    await _persistProgress();
  }

  Future<void> _onSegmentSelected(
    OnboardingSegmentSelected event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(segment: event.segment, segmentError: null));
    await _persistProgress();
  }

  Future<void> _onCurrencyChanged(
    OnboardingCurrencyChanged event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(currency: event.currency, currencyError: null));
    await _persistProgress();
  }

  Future<void> _onCountryChanged(
    OnboardingCountryChanged event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(country: event.country, countryError: null));
    await _persistProgress();
  }

  Future<void> _onDefaultLanguageChanged(
    OnboardingDefaultLanguageChanged event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(
      state.copyWith(
        defaultLanguage: event.defaultLanguage,
        defaultLanguageError: null,
      ),
    );
    await _persistProgress();
  }

  Future<void> _onNextStepRequested(
    OnboardingNextStepRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    final error = _validateStep(state.step);
    if (error != null) {
      emit(_applyStepError(error));
      return;
    }

    final nextStep = state.step.next;
    if (nextStep == null) {
      // Already on the last step: nothing to advance to, `submitted` is the
      // right event for it. No-op instead of throwing — a stray tap after
      // the UI already swapped the button is harmless.
      return;
    }

    emit(state.copyWith(step: nextStep));
    await _persistProgress();
  }

  Future<void> _onPreviousStepRequested(
    OnboardingPreviousStepRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    final previousStep = state.step.previous;
    if (previousStep == null) {
      return;
    }

    emit(state.copyWith(step: previousStep));
    await _persistProgress();
  }

  Future<void> _onSubmitted(
    OnboardingSubmitted event,
    Emitter<OnboardingState> emit,
  ) async {
    final nameError = validateOrganizationName(state.organizationName);
    final segmentError = validateOrganizationSegment(state.segment);
    if (nameError != null || segmentError != null) {
      emit(
        state.copyWith(
          organizationNameError: nameError,
          segmentError: segmentError,
        ),
      );
      return;
    }

    final userId = _userId;
    if (userId == null) {
      emit(
        state.copyWith(
          submissionStatus: OnboardingSubmissionStatus.failure,
          failure: const AuthenticationFailure(
            'É necessário estar autenticado para concluir a configuração.',
            code: 'onboarding_not_authenticated',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: OnboardingSubmissionStatus.submitting,
        failure: null,
      ),
    );

    final result = await completeOnboarding(
      progress: _progressFromState(),
      createdBy: userId,
    );
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<Organization>(value: final organization):
        await clearProgress(userId: userId);
        // Only the segment (a coarse category, never personal data) is
        // logged — never the organization's name, same LGPD restriction
        // `AnalyticsService.logEvent` documents (see `AGENTS.md`).
        await analyticsService.logEvent(
          AnalyticsEvents.organizationCreated,
          parameters: <String, Object?>{'segment': state.segment!.code},
        );
        if (emit.isDone) {
          return;
        }
        emit(
          state.copyWith(
            submissionStatus: OnboardingSubmissionStatus.success,
            createdOrganization: organization,
          ),
        );
      case AppFailure<Organization>(failure: final failure):
        emit(
          state.copyWith(
            submissionStatus: OnboardingSubmissionStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _persistProgress() async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    await saveProgress(userId: userId, progress: _progressFromState());
  }

  OnboardingProgress _progressFromState() {
    return OnboardingProgress(
      step: state.step,
      organizationName: state.organizationName,
      segment: state.segment,
      currency: state.currency,
      country: state.country,
      defaultLanguage: state.defaultLanguage,
    );
  }

  /// Validates the fields that belong to [step], or `null` when they all
  /// pass.
  String? _validateStep(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.organizationDetails => validateOrganizationName(
        state.organizationName,
      ),
      OnboardingStep.segment => validateOrganizationSegment(state.segment),
      OnboardingStep.regionalSettings =>
        validateCurrency(state.currency) ?? validateCountry(state.country),
      OnboardingStep.preferences => validateDefaultLanguage(
        state.defaultLanguage,
      ),
    };
  }

  OnboardingState _applyStepError(String error) {
    return switch (state.step) {
      OnboardingStep.organizationDetails => state.copyWith(
        organizationNameError: error,
      ),
      OnboardingStep.segment => state.copyWith(segmentError: error),
      OnboardingStep.regionalSettings => state.copyWith(
        currencyError: validateCurrency(state.currency),
        countryError: validateCountry(state.country),
      ),
      OnboardingStep.preferences => state.copyWith(defaultLanguageError: error),
    };
  }
}
