import '../../../../core/errors/errors.dart';
import '../../domain/entities/season.dart';

enum SeasonListLoadStatus { loading, ready, failure }

enum SeasonListDeleteStatus { idle, deleting, success, failure }

final class SeasonListState {
  const SeasonListState({
    this.loadStatus = SeasonListLoadStatus.loading,
    this.deleteStatus = SeasonListDeleteStatus.idle,
    this.organizationId = '',
    this.userId = '',
    this.seasons = const <Season>[],
    this.searchQuery = '',
    this.loadFailure,
    this.deleteFailure,
  });

  final SeasonListLoadStatus loadStatus;
  final SeasonListDeleteStatus deleteStatus;
  final String organizationId;
  final String userId;
  final List<Season> seasons;
  final String searchQuery;
  final Failure? loadFailure;
  final Failure? deleteFailure;

  List<Season> get filteredSeasons {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return seasons;
    return seasons
        .where((season) => season.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  SeasonListState copyWith({
    SeasonListLoadStatus? loadStatus,
    SeasonListDeleteStatus? deleteStatus,
    String? organizationId,
    String? userId,
    List<Season>? seasons,
    String? searchQuery,
    Failure? loadFailure,
    Failure? deleteFailure,
    bool clearLoadFailure = false,
    bool clearDeleteFailure = false,
  }) {
    return SeasonListState(
      loadStatus: loadStatus ?? this.loadStatus,
      deleteStatus: deleteStatus ?? this.deleteStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      seasons: seasons ?? this.seasons,
      searchQuery: searchQuery ?? this.searchQuery,
      loadFailure: clearLoadFailure ? null : loadFailure ?? this.loadFailure,
      deleteFailure: clearDeleteFailure
          ? null
          : deleteFailure ?? this.deleteFailure,
    );
  }
}
