import '../../../../core/errors/errors.dart';
import '../../domain/entities/commercial_team.dart';

enum TeamListLoadStatus { loading, ready, failure }

enum TeamListDeleteStatus { idle, deleting, success, failure }

final class TeamListState {
  const TeamListState({
    this.loadStatus = TeamListLoadStatus.loading,
    this.deleteStatus = TeamListDeleteStatus.idle,
    this.organizationId = '',
    this.userId = '',
    this.teams = const <CommercialTeam>[],
    this.searchQuery = '',
    this.loadFailure,
    this.deleteFailure,
    this.deletedTeamId,
  });

  final TeamListLoadStatus loadStatus;
  final TeamListDeleteStatus deleteStatus;
  final String organizationId;
  final String userId;
  final List<CommercialTeam> teams;
  final String searchQuery;
  final Failure? loadFailure;
  final Failure? deleteFailure;
  final String? deletedTeamId;

  List<CommercialTeam> get filteredTeams {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return teams;
    return teams
        .where(
          (team) =>
              team.name.toLowerCase().contains(query) ||
              team.managerName.toLowerCase().contains(query) ||
              team.memberNames.any(
                (name) => name.toLowerCase().contains(query),
              ),
        )
        .toList(growable: false);
  }

  TeamListState copyWith({
    TeamListLoadStatus? loadStatus,
    TeamListDeleteStatus? deleteStatus,
    String? organizationId,
    String? userId,
    List<CommercialTeam>? teams,
    String? searchQuery,
    Failure? loadFailure,
    Failure? deleteFailure,
    String? deletedTeamId,
    bool clearLoadFailure = false,
    bool clearDeleteFailure = false,
    bool clearDeletedTeamId = false,
  }) {
    return TeamListState(
      loadStatus: loadStatus ?? this.loadStatus,
      deleteStatus: deleteStatus ?? this.deleteStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      teams: teams ?? this.teams,
      searchQuery: searchQuery ?? this.searchQuery,
      loadFailure: clearLoadFailure ? null : loadFailure ?? this.loadFailure,
      deleteFailure: clearDeleteFailure
          ? null
          : deleteFailure ?? this.deleteFailure,
      deletedTeamId: clearDeletedTeamId
          ? null
          : deletedTeamId ?? this.deletedTeamId,
    );
  }
}
