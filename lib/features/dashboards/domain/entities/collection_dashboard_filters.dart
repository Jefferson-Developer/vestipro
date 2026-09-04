/// Filter/view state of the Collection Dashboard (TASK-138, EPIC-17): which
/// company scopes the underlying `productMonthly` read (TASK-133) and which
/// Collections are currently selected for the side-by-side comparison —
/// mirrored into the route's query parameters so a Flutter Web reload/share
/// link restores exactly the same comparison, same contract
/// `ProductDashboardFilters`/`CustomerDashboardFilters` already set.
///
/// Deliberately no `month`/`year` filter (unlike every other EPIC-17
/// dashboard): each [collectionIds] entry is read over *its own*
/// `Collection.startDate`–`endDate` (TASK-066), never a shared calendar
/// month — this task's own "deixar explícito o período de cada" rule would
/// be violated by a single global month picker.
final class CollectionDashboardFilters {
  const CollectionDashboardFilters({
    required this.companyId,
    this.collectionIds = const <String>[],
  });

  final String companyId;

  /// Ordered, deduplicated ids of the Collections currently compared —
  /// `LoadCollectionDashboardEntriesUseCase` returns one
  /// `CollectionDashboardEntry` per id, in this same order. Empty means "no
  /// coleção selecionada ainda" (the landing state before the caller picks
  /// at least one).
  final List<String> collectionIds;

  /// How many Collections the comparison UI renders side by side at once —
  /// a UI-level cap (not a data-layer one) so the desktop comparison layout
  /// never has to horizontally scroll past a screenful of cards.
  static const int maxComparedCollections = 4;

  CollectionDashboardFilters copyWith({
    String? companyId,
    List<String>? collectionIds,
  }) {
    return CollectionDashboardFilters(
      companyId: companyId ?? this.companyId,
      collectionIds: collectionIds ?? this.collectionIds,
    );
  }

  /// Toggles [collectionId] in/out of [collectionIds], never growing past
  /// [maxComparedCollections] (the UI disables further selection once the
  /// cap is reached, but this method itself is the single source of truth
  /// enforcing it).
  CollectionDashboardFilters toggleCollection(String collectionId) {
    final trimmed = collectionId.trim();
    if (trimmed.isEmpty) return this;
    if (collectionIds.contains(trimmed)) {
      return copyWith(
        collectionIds: collectionIds
            .where((id) => id != trimmed)
            .toList(growable: false),
      );
    }
    if (collectionIds.length >= maxComparedCollections) return this;
    return copyWith(collectionIds: <String>[...collectionIds, trimmed]);
  }

  Map<String, String> toQueryParameters() {
    return <String, String>{
      'companyId': companyId,
      if (collectionIds.isNotEmpty) 'collectionIds': collectionIds.join(','),
    };
  }

  factory CollectionDashboardFilters.fromQueryParameters(
    Map<String, String> queryParameters, {
    required String defaultCompanyId,
  }) {
    final companyId = queryParameters['companyId']?.trim();
    final resolvedCompanyId = (companyId == null || companyId.isEmpty)
        ? defaultCompanyId
        : companyId;
    final rawCollectionIds = queryParameters['collectionIds']?.trim();
    final collectionIds = (rawCollectionIds == null || rawCollectionIds.isEmpty)
        ? const <String>[]
        : rawCollectionIds
              .split(',')
              .map((id) => id.trim())
              .where((id) => id.isNotEmpty)
              .toSet()
              .take(maxComparedCollections)
              .toList(growable: false);

    return CollectionDashboardFilters(
      companyId: resolvedCompanyId,
      collectionIds: collectionIds,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CollectionDashboardFilters &&
        companyId == other.companyId &&
        _listEquals(collectionIds, other.collectionIds);
  }

  @override
  int get hashCode => Object.hash(companyId, Object.hashAll(collectionIds));
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
