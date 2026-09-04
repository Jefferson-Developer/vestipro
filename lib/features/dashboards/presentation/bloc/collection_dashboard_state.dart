import '../../../../core/errors/errors.dart';
import '../../../products/domain/entities/collection.dart';
import '../../domain/entities/collection_dashboard_entry.dart';
import '../../domain/entities/collection_dashboard_filters.dart';
import '../../domain/entities/executive_dashboard_visibility_filter.dart';
import 'executive_dashboard_state.dart' show ExecutiveDashboardScopeOption;

enum CollectionDashboardStatus { initial, loading, forbidden, error, ready }

final class CollectionDashboardState {
  const CollectionDashboardState({
    this.status = CollectionDashboardStatus.initial,
    this.organizationId = '',
    this.userId = '',
    this.visibilityFilter,
    this.filters = const CollectionDashboardFilters(companyId: ''),
    this.companyOptions = const <ExecutiveDashboardScopeOption>[],
    this.collections = const <Collection>[],
    this.entries = const <CollectionDashboardEntry>[],
    this.failure,
  });

  final CollectionDashboardStatus status;
  final String organizationId;
  final String userId;

  /// Reuses `ExecutiveDashboardVisibilityFilter` verbatim — same RBAC
  /// scoping semantics every EPIC-17 dashboard already shares.
  final ExecutiveDashboardVisibilityFilter? visibilityFilter;
  final CollectionDashboardFilters filters;
  final List<ExecutiveDashboardScopeOption> companyOptions;

  /// Every non-deleted Collection of the organization (`deletedAt == null`)
  /// — kept as full `Collection` entities (not just id/name options) so
  /// `LoadCollectionDashboardEntriesUseCase` can read each one's own
  /// `startDate`/`endDate` without a second repository round-trip.
  ///
  /// **"Apenas coleções publicadas" — lacuna documentada.** `CollectionStatus`
  /// (TASK-066) only models `active`/`closed`, never a `draft`/`published`
  /// distinction — there is nothing in the domain today that separates a
  /// "rascunho" from a real coleção. Both `active` and `closed` Collections
  /// are offered here (a `closed` past season is exactly the kind of
  /// "mesma estação de anos diferentes" comparison this task's own escopo
  /// técnico calls for); only soft-deleted Collections (`deletedAt != null`)
  /// are excluded. Documented in
  /// `docs/tasks/TASK-138-implementar-dashboard-de-colecao-CONCLUIDA.md`.
  final List<Collection> collections;

  /// One entry per `filters.collectionIds`, in the same order, once loaded.
  final List<CollectionDashboardEntry> entries;

  final Failure? failure;

  List<ExecutiveDashboardScopeOption> get collectionOptions =>
      <ExecutiveDashboardScopeOption>[
        for (final collection in collections)
          ExecutiveDashboardScopeOption(
            id: collection.id,
            name: collection.name,
          ),
      ];

  /// Whether the caller may pick a company other than their own — mirrors
  /// `ProductDashboardState.canPickScope`.
  bool get canPickScope =>
      visibilityFilter?.mode ==
          ExecutiveDashboardVisibilityMode.allOrganization ||
      companyOptions.length > 1;

  CollectionDashboardState copyWith({
    CollectionDashboardStatus? status,
    String? organizationId,
    String? userId,
    ExecutiveDashboardVisibilityFilter? visibilityFilter,
    CollectionDashboardFilters? filters,
    List<ExecutiveDashboardScopeOption>? companyOptions,
    List<Collection>? collections,
    List<CollectionDashboardEntry>? entries,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return CollectionDashboardState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      visibilityFilter: visibilityFilter ?? this.visibilityFilter,
      filters: filters ?? this.filters,
      companyOptions: companyOptions ?? this.companyOptions,
      collections: collections ?? this.collections,
      entries: entries ?? this.entries,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
