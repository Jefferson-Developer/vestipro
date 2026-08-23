import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../../domain/entities/commercial_team.dart';
import '../../domain/usecases/list_commercial_teams_use_case.dart';
import 'team_list_event.dart';
import 'team_list_state.dart';

@injectable
final class TeamListBloc extends Bloc<TeamListEvent, TeamListState> {
  TeamListBloc({
    required this.listCommercialTeams,
    required this.deleteTeam,
    required this.analyticsService,
  }) : super(const TeamListState()) {
    on<TeamListStarted>(_onStarted, transformer: restartable());
    on<TeamListRefreshRequested>(
      _onRefreshRequested,
      transformer: restartable(),
    );
    on<TeamListSearchChanged>(_onSearchChanged, transformer: sequential());
    on<TeamListDeleteRequested>(_onDeleteRequested, transformer: sequential());
  }

  final ListCommercialTeamsUseCase listCommercialTeams;
  final DeleteTeamUseCase deleteTeam;
  final AnalyticsService analyticsService;

  Future<void> _onStarted(
    TeamListStarted event,
    Emitter<TeamListState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: TeamListLoadStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        clearLoadFailure: true,
      ),
    );
    await _load(event.organizationId, emit);
  }

  Future<void> _onRefreshRequested(
    TeamListRefreshRequested event,
    Emitter<TeamListState> emit,
  ) async {
    if (state.organizationId.isEmpty) return;
    emit(
      state.copyWith(
        loadStatus: TeamListLoadStatus.loading,
        clearLoadFailure: true,
      ),
    );
    await _load(state.organizationId, emit);
  }

  Future<void> _load(String organizationId, Emitter<TeamListState> emit) async {
    final result = await listCommercialTeams(organizationId);
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<List<CommercialTeam>>(value: final teams):
        emit(
          state.copyWith(
            loadStatus: TeamListLoadStatus.ready,
            teams: teams,
            clearLoadFailure: true,
          ),
        );
      case AppFailure<List<CommercialTeam>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: TeamListLoadStatus.failure,
            loadFailure: failure,
          ),
        );
    }
  }

  void _onSearchChanged(
    TeamListSearchChanged event,
    Emitter<TeamListState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onDeleteRequested(
    TeamListDeleteRequested event,
    Emitter<TeamListState> emit,
  ) async {
    emit(
      state.copyWith(
        deleteStatus: TeamListDeleteStatus.deleting,
        clearDeleteFailure: true,
        clearDeletedTeamId: true,
      ),
    );
    final result = await deleteTeam(
      organizationId: state.organizationId,
      id: event.team.id,
      deletedBy: state.userId,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<Team>():
        await analyticsService.logEvent(
          AnalyticsEvents.teamDeleted,
          parameters: <String, Object?>{
            'organization_id': state.organizationId,
            'team_id': event.team.id,
          },
        );
        emit(
          state.copyWith(
            deleteStatus: TeamListDeleteStatus.success,
            teams: state.teams
                .where((team) => team.id != event.team.id)
                .toList(growable: false),
            deletedTeamId: event.team.id,
          ),
        );
        emit(
          state.copyWith(
            deleteStatus: TeamListDeleteStatus.idle,
            clearDeletedTeamId: true,
          ),
        );
      case AppFailure<Team>(failure: final failure):
        emit(
          state.copyWith(
            deleteStatus: TeamListDeleteStatus.failure,
            deleteFailure: failure,
          ),
        );
    }
  }
}
