import '../../domain/entities/season.dart';

sealed class SeasonListEvent {
  const SeasonListEvent();
}

final class SeasonListStarted extends SeasonListEvent {
  const SeasonListStarted({required this.organizationId, required this.userId});

  final String organizationId;
  final String userId;
}

final class SeasonListRefreshRequested extends SeasonListEvent {
  const SeasonListRefreshRequested();
}

final class SeasonListSearchChanged extends SeasonListEvent {
  const SeasonListSearchChanged(this.query);

  final String query;
}

final class SeasonListDeleteRequested extends SeasonListEvent {
  const SeasonListDeleteRequested(this.season);

  final Season season;
}
