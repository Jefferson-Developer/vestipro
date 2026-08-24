import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/collection.dart';
import '../../domain/entities/season.dart';
import '../../domain/usecases/create_collection_use_case.dart';
import '../../domain/usecases/list_seasons_use_case.dart';
import '../../domain/usecases/update_collection_use_case.dart';
import 'collection_form_event.dart';
import 'collection_form_state.dart';

@injectable
final class CollectionFormBloc
    extends Bloc<CollectionFormEvent, CollectionFormState> {
  CollectionFormBloc({
    required this.listSeasons,
    required this.createCollection,
    required this.updateCollection,
  }) : super(const CollectionFormState()) {
    on<CollectionFormStarted>(_onStarted, transformer: restartable());
    on<CollectionFormNameChanged>(_onNameChanged, transformer: sequential());
    on<CollectionFormSeasonSelected>(
      _onSeasonSelected,
      transformer: sequential(),
    );
    on<CollectionFormYearChanged>(_onYearChanged, transformer: sequential());
    on<CollectionFormStartDateChanged>(
      _onStartDateChanged,
      transformer: sequential(),
    );
    on<CollectionFormEndDateChanged>(
      _onEndDateChanged,
      transformer: sequential(),
    );
    on<CollectionFormSubmitted>(_onSubmitted, transformer: sequential());
  }

  final ListSeasonsUseCase listSeasons;
  final CreateCollectionUseCase createCollection;
  final UpdateCollectionUseCase updateCollection;
  final Uuid _uuid = const Uuid();

  Future<void> _onStarted(
    CollectionFormStarted event,
    Emitter<CollectionFormState> emit,
  ) async {
    final initial = event.initialCollection;
    emit(
      CollectionFormState(
        loadStatus: CollectionFormLoadStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        initialCollection: initial,
        name: initial?.name ?? '',
        seasonId: initial?.seasonId,
        year: initial?.year,
        startDate: initial?.startDate,
        endDate: initial?.endDate,
      ),
    );

    final result = await listSeasons(event.organizationId);
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<List<Season>>(value: final seasons):
        emit(
          state.copyWith(
            loadStatus: CollectionFormLoadStatus.ready,
            seasons: seasons,
            clearFailure: true,
          ),
        );
      case AppFailure<List<Season>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: CollectionFormLoadStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  void _onNameChanged(
    CollectionFormNameChanged event,
    Emitter<CollectionFormState> emit,
  ) {
    emit(
      state.copyWith(
        name: event.name,
        submissionStatus: CollectionFormSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onSeasonSelected(
    CollectionFormSeasonSelected event,
    Emitter<CollectionFormState> emit,
  ) {
    emit(
      state.copyWith(
        seasonId: event.seasonId,
        clearSeasonId: event.seasonId == null,
        submissionStatus: CollectionFormSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onYearChanged(
    CollectionFormYearChanged event,
    Emitter<CollectionFormState> emit,
  ) {
    emit(
      state.copyWith(
        year: event.year,
        clearYear: event.year == null,
        submissionStatus: CollectionFormSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onStartDateChanged(
    CollectionFormStartDateChanged event,
    Emitter<CollectionFormState> emit,
  ) {
    emit(
      state.copyWith(
        startDate: event.startDate,
        clearStartDate: event.startDate == null,
        submissionStatus: CollectionFormSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onEndDateChanged(
    CollectionFormEndDateChanged event,
    Emitter<CollectionFormState> emit,
  ) {
    emit(
      state.copyWith(
        endDate: event.endDate,
        clearEndDate: event.endDate == null,
        submissionStatus: CollectionFormSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onSubmitted(
    CollectionFormSubmitted event,
    Emitter<CollectionFormState> emit,
  ) async {
    if (state.name.trim().isEmpty) {
      emit(
        state.copyWith(
          submissionStatus: CollectionFormSubmissionStatus.failure,
          fieldErrors: const <String, String>{
            'name': 'Informe o nome da coleção.',
          },
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: CollectionFormSubmissionStatus.submitting,
        clearFieldErrors: true,
        clearFailure: true,
        clearSavedCollection: true,
      ),
    );

    final result = state.isEditing
        ? await updateCollection(
            organizationId: state.organizationId,
            id: state.initialCollection!.id,
            name: state.name,
            seasonId: state.seasonId,
            year: state.year,
            startDate: state.startDate,
            endDate: state.endDate,
            updatedBy: state.userId,
          )
        : await createCollection(
            id: _uuid.v4(),
            organizationId: state.organizationId,
            name: state.name,
            seasonId: state.seasonId,
            year: state.year,
            startDate: state.startDate,
            endDate: state.endDate,
            createdBy: state.userId,
          );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<Collection>(value: final collection):
        emit(
          state.copyWith(
            submissionStatus: CollectionFormSubmissionStatus.success,
            savedCollection: collection,
            clearFailure: true,
          ),
        );
      case AppFailure<Collection>(failure: final failure):
        emit(
          state.copyWith(
            submissionStatus: CollectionFormSubmissionStatus.failure,
            failure: failure,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
          ),
        );
    }
  }
}
