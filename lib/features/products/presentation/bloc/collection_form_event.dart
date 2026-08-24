import '../../domain/entities/collection.dart';

sealed class CollectionFormEvent {
  const CollectionFormEvent();
}

final class CollectionFormStarted extends CollectionFormEvent {
  const CollectionFormStarted({
    required this.organizationId,
    required this.userId,
    this.initialCollection,
  });

  final String organizationId;
  final String userId;
  final Collection? initialCollection;
}

final class CollectionFormNameChanged extends CollectionFormEvent {
  const CollectionFormNameChanged(this.name);

  final String name;
}

final class CollectionFormSeasonSelected extends CollectionFormEvent {
  const CollectionFormSeasonSelected(this.seasonId);

  final String? seasonId;
}

final class CollectionFormYearChanged extends CollectionFormEvent {
  const CollectionFormYearChanged(this.year);

  final int? year;
}

final class CollectionFormStartDateChanged extends CollectionFormEvent {
  const CollectionFormStartDateChanged(this.startDate);

  final DateTime? startDate;
}

final class CollectionFormEndDateChanged extends CollectionFormEvent {
  const CollectionFormEndDateChanged(this.endDate);

  final DateTime? endDate;
}

final class CollectionFormSubmitted extends CollectionFormEvent {
  const CollectionFormSubmitted();
}
