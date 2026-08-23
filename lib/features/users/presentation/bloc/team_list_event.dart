import '../../domain/entities/commercial_team.dart';

sealed class TeamListEvent {
  const TeamListEvent();
}

final class TeamListStarted extends TeamListEvent {
  const TeamListStarted({required this.organizationId, required this.userId});

  final String organizationId;
  final String userId;
}

final class TeamListRefreshRequested extends TeamListEvent {
  const TeamListRefreshRequested();
}

final class TeamListSearchChanged extends TeamListEvent {
  const TeamListSearchChanged(this.query);

  final String query;
}

final class TeamListDeleteRequested extends TeamListEvent {
  const TeamListDeleteRequested(this.team);

  final CommercialTeam team;
}
