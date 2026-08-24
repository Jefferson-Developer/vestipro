import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/season.dart';
import '../../domain/usecases/create_season_use_case.dart';
import '../../domain/usecases/update_season_use_case.dart';
import 'season_form_event.dart';
import 'season_form_state.dart';

@injectable
final class SeasonFormBloc extends Bloc<SeasonFormEvent, SeasonFormState> {
  SeasonFormBloc({required this.createSeason, required this.updateSeason})
    : super(const SeasonFormState()) {
    on<SeasonFormStarted>(_onStarted, transformer: restartable());
    on<SeasonFormNameChanged>(_onNameChanged, transformer: sequential());
    on<SeasonFormSubmitted>(_onSubmitted, transformer: sequential());
  }

  final CreateSeasonUseCase createSeason;
  final UpdateSeasonUseCase updateSeason;
  final Uuid _uuid = const Uuid();

  void _onStarted(SeasonFormStarted event, Emitter<SeasonFormState> emit) {
    emit(
      SeasonFormState(
        organizationId: event.organizationId,
        userId: event.userId,
        initialSeason: event.initialSeason,
        name: event.initialSeason?.name ?? '',
      ),
    );
  }

  void _onNameChanged(
    SeasonFormNameChanged event,
    Emitter<SeasonFormState> emit,
  ) {
    emit(
      state.copyWith(
        name: event.name,
        submissionStatus: SeasonFormSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onSubmitted(
    SeasonFormSubmitted event,
    Emitter<SeasonFormState> emit,
  ) async {
    if (state.name.trim().isEmpty) {
      emit(
        state.copyWith(
          submissionStatus: SeasonFormSubmissionStatus.failure,
          fieldErrors: const <String, String>{
            'name': 'Informe o nome da estação.',
          },
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: SeasonFormSubmissionStatus.submitting,
        clearFieldErrors: true,
        clearFailure: true,
        clearSavedSeason: true,
      ),
    );

    final result = state.isEditing
        ? await updateSeason(
            organizationId: state.organizationId,
            id: state.initialSeason!.id,
            name: state.name,
            updatedBy: state.userId,
          )
        : await createSeason(
            id: _uuid.v4(),
            organizationId: state.organizationId,
            name: state.name,
            createdBy: state.userId,
          );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<Season>(value: final season):
        emit(
          state.copyWith(
            submissionStatus: SeasonFormSubmissionStatus.success,
            savedSeason: season,
            clearFailure: true,
          ),
        );
      case AppFailure<Season>(failure: final failure):
        emit(
          state.copyWith(
            submissionStatus: SeasonFormSubmissionStatus.failure,
            failure: failure,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
          ),
        );
    }
  }
}
