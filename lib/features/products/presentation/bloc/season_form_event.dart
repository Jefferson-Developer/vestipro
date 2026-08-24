import '../../domain/entities/season.dart';

sealed class SeasonFormEvent {
  const SeasonFormEvent();
}

final class SeasonFormStarted extends SeasonFormEvent {
  const SeasonFormStarted({
    required this.organizationId,
    required this.userId,
    this.initialSeason,
  });

  final String organizationId;
  final String userId;
  final Season? initialSeason;
}

final class SeasonFormNameChanged extends SeasonFormEvent {
  const SeasonFormNameChanged(this.name);

  final String name;
}

final class SeasonFormSubmitted extends SeasonFormEvent {
  const SeasonFormSubmitted();
}
