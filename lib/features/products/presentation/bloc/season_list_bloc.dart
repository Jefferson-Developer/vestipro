import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/season.dart';
import '../../domain/usecases/delete_season_use_case.dart';
import '../../domain/usecases/list_seasons_use_case.dart';
import 'season_list_event.dart';
import 'season_list_state.dart';

@injectable
final class SeasonListBloc extends Bloc<SeasonListEvent, SeasonListState> {
  SeasonListBloc({required this.listSeasons, required this.deleteSeason})
    : super(const SeasonListState()) {
    on<SeasonListStarted>(_onStarted, transformer: restartable());
    on<SeasonListRefreshRequested>(
      _onRefreshRequested,
      transformer: restartable(),
    );
    on<SeasonListSearchChanged>(_onSearchChanged, transformer: sequential());
    on<SeasonListDeleteRequested>(
      _onDeleteRequested,
      transformer: sequential(),
    );
  }

  final ListSeasonsUseCase listSeasons;
  final DeleteSeasonUseCase deleteSeason;

  Future<void> _onStarted(
    SeasonListStarted event,
    Emitter<SeasonListState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: SeasonListLoadStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        clearLoadFailure: true,
      ),
    );
    await _load(event.organizationId, emit);
  }

  Future<void> _onRefreshRequested(
    SeasonListRefreshRequested event,
    Emitter<SeasonListState> emit,
  ) async {
    if (state.organizationId.isEmpty) return;
    emit(
      state.copyWith(
        loadStatus: SeasonListLoadStatus.loading,
        clearLoadFailure: true,
      ),
    );
    await _load(state.organizationId, emit);
  }

  Future<void> _load(
    String organizationId,
    Emitter<SeasonListState> emit,
  ) async {
    final result = await listSeasons(organizationId);
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<List<Season>>(value: final seasons):
        emit(
          state.copyWith(
            loadStatus: SeasonListLoadStatus.ready,
            seasons: seasons,
            clearLoadFailure: true,
          ),
        );
      case AppFailure<List<Season>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: SeasonListLoadStatus.failure,
            loadFailure: failure,
          ),
        );
    }
  }

  void _onSearchChanged(
    SeasonListSearchChanged event,
    Emitter<SeasonListState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onDeleteRequested(
    SeasonListDeleteRequested event,
    Emitter<SeasonListState> emit,
  ) async {
    emit(
      state.copyWith(
        deleteStatus: SeasonListDeleteStatus.deleting,
        clearDeleteFailure: true,
      ),
    );
    final result = await deleteSeason(
      organizationId: state.organizationId,
      id: event.season.id,
      deletedBy: state.userId,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<Season>():
        emit(
          state.copyWith(
            deleteStatus: SeasonListDeleteStatus.success,
            seasons: state.seasons
                .where((season) => season.id != event.season.id)
                .toList(growable: false),
          ),
        );
        emit(state.copyWith(deleteStatus: SeasonListDeleteStatus.idle));
      case AppFailure<Season>(failure: final failure):
        emit(
          state.copyWith(
            deleteStatus: SeasonListDeleteStatus.failure,
            deleteFailure: failure,
          ),
        );
    }
  }
}
