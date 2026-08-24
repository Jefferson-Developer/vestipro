import '../../../../core/errors/errors.dart';
import '../../domain/entities/collection.dart';

enum CollectionListLoadStatus { loading, ready, failure }

enum CollectionListCloseStatus { idle, closing, success, failure }

final class CollectionListState {
  const CollectionListState({
    this.loadStatus = CollectionListLoadStatus.loading,
    this.closeStatus = CollectionListCloseStatus.idle,
    this.organizationId = '',
    this.userId = '',
    this.collections = const <Collection>[],
    this.searchQuery = '',
    this.loadFailure,
    this.closeFailure,
  });

  final CollectionListLoadStatus loadStatus;
  final CollectionListCloseStatus closeStatus;
  final String organizationId;
  final String userId;
  final List<Collection> collections;
  final String searchQuery;
  final Failure? loadFailure;
  final Failure? closeFailure;

  List<Collection> get filteredCollections {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return collections;
    return collections
        .where((collection) => collection.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  CollectionListState copyWith({
    CollectionListLoadStatus? loadStatus,
    CollectionListCloseStatus? closeStatus,
    String? organizationId,
    String? userId,
    List<Collection>? collections,
    String? searchQuery,
    Failure? loadFailure,
    Failure? closeFailure,
    bool clearLoadFailure = false,
    bool clearCloseFailure = false,
  }) {
    return CollectionListState(
      loadStatus: loadStatus ?? this.loadStatus,
      closeStatus: closeStatus ?? this.closeStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      collections: collections ?? this.collections,
      searchQuery: searchQuery ?? this.searchQuery,
      loadFailure: clearLoadFailure ? null : loadFailure ?? this.loadFailure,
      closeFailure: clearCloseFailure
          ? null
          : closeFailure ?? this.closeFailure,
    );
  }
}
