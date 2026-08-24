import '../../domain/entities/collection.dart';

sealed class CollectionListEvent {
  const CollectionListEvent();
}

final class CollectionListStarted extends CollectionListEvent {
  const CollectionListStarted({
    required this.organizationId,
    required this.userId,
  });

  final String organizationId;
  final String userId;
}

final class CollectionListRefreshRequested extends CollectionListEvent {
  const CollectionListRefreshRequested();
}

final class CollectionListSearchChanged extends CollectionListEvent {
  const CollectionListSearchChanged(this.query);

  final String query;
}

final class CollectionListCloseRequested extends CollectionListEvent {
  const CollectionListCloseRequested(this.collection);

  final Collection collection;
}
