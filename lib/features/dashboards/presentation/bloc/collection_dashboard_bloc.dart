import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/entities/company.dart';
import '../../../organizations/domain/repositories/company_repository.dart';
import '../../../products/domain/entities/collection.dart';
import '../../../products/domain/repositories/collection_repository.dart';
import '../../domain/entities/collection_dashboard_entry.dart';
import '../../domain/entities/collection_dashboard_filters.dart';
import '../../domain/entities/executive_dashboard_visibility_filter.dart';
import '../../domain/services/executive_dashboard_visibility_service.dart';
import '../../domain/usecases/load_collection_dashboard_entries_use_case.dart';
import 'collection_dashboard_event.dart';
import 'collection_dashboard_state.dart';
import 'executive_dashboard_state.dart' show ExecutiveDashboardScopeOption;

/// Drives the Collection Dashboard (TASK-138, EPIC-17): resolves which
/// companies/Collections the caller may pick as scope, then loads one
/// [CollectionDashboardEntry] per `filters.collectionIds` exclusively from
/// [LoadCollectionDashboardEntriesUseCase] (TASK-133's `productMonthly`
/// aggregation, read over each coleção's own período, plus TASK-094's giro
/// de estoque por coleção) — never a raw query against `orders`/`products`.
@injectable
final class CollectionDashboardBloc
    extends Bloc<CollectionDashboardEvent, CollectionDashboardState> {
  CollectionDashboardBloc(
    this._visibilityService,
    this._loadEntries,
    this._companyRepository,
    this._collectionRepository,
    this._analyticsService,
  ) : super(const CollectionDashboardState()) {
    on<CollectionDashboardStarted>(_onStarted);
    on<CollectionDashboardFiltersChanged>(_onFiltersChanged);
    on<CollectionDashboardRetried>(_onRetried);
  }

  final ExecutiveDashboardVisibilityService _visibilityService;
  final LoadCollectionDashboardEntriesUseCase _loadEntries;
  final CompanyRepository _companyRepository;
  final CollectionRepository _collectionRepository;
  final AnalyticsService _analyticsService;

  Future<void> _onStarted(
    CollectionDashboardStarted event,
    Emitter<CollectionDashboardState> emit,
  ) async {
    emit(
      CollectionDashboardState(
        status: CollectionDashboardStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        filters: event.initialFilters,
      ),
    );

    final visibilityResult = await _visibilityService.resolve(
      organizationId: event.organizationId,
      userId: event.userId,
    );
    if (visibilityResult case AppFailure<ExecutiveDashboardVisibilityFilter>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(
          status: CollectionDashboardStatus.error,
          failure: failure,
        ),
      );
      return;
    }
    final visibility =
        (visibilityResult as AppSuccess<ExecutiveDashboardVisibilityFilter>)
            .value;
    emit(state.copyWith(visibilityFilter: visibility));

    if (!visibility.canViewAny) {
      emit(state.copyWith(status: CollectionDashboardStatus.forbidden));
      return;
    }

    final companiesResult = await _companyRepository.listByOrganization(
      event.organizationId,
    );
    if (companiesResult case AppFailure<List<Company>>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(
          status: CollectionDashboardStatus.error,
          failure: failure,
        ),
      );
      return;
    }
    final companies = (companiesResult as AppSuccess<List<Company>>).value
        .where(
          (company) =>
              company.deletedAt == null &&
              visibility.canViewCompany(company.id),
        )
        .toList(growable: false);

    final companyOptions = <ExecutiveDashboardScopeOption>[
      for (final company in companies)
        ExecutiveDashboardScopeOption(id: company.id, name: company.name),
    ];

    final collectionsResult = await _collectionRepository.listByOrganization(
      event.organizationId,
    );
    final collections = switch (collectionsResult) {
      AppSuccess<List<Collection>>(value: final all) =>
        all
            .where((collection) => collection.deletedAt == null)
            .toList(growable: false),
      AppFailure<List<Collection>>() => const <Collection>[],
    };

    var effectiveFilters = event.initialFilters;
    if (companies.isNotEmpty &&
        !companies.any((company) => company.id == effectiveFilters.companyId)) {
      effectiveFilters = effectiveFilters.copyWith(
        companyId: companies.first.id,
      );
    }
    if (effectiveFilters.collectionIds.isEmpty && collections.isNotEmpty) {
      // Landing default: compare the most recently created coleção alone,
      // so the page never lands empty — the caller can still add/remove
      // entries via the coleção picker afterwards.
      effectiveFilters = effectiveFilters.copyWith(
        collectionIds: <String>[collections.first.id],
      );
    }

    emit(
      state.copyWith(
        companyOptions: companyOptions,
        collections: collections,
        filters: effectiveFilters,
      ),
    );

    await _load(effectiveFilters, emit);
  }

  Future<void> _onFiltersChanged(
    CollectionDashboardFiltersChanged event,
    Emitter<CollectionDashboardState> emit,
  ) async {
    final visibility = state.visibilityFilter;
    if (visibility == null || !visibility.canViewAny) return;
    if (!visibility.canViewCompany(event.filters.companyId)) return;

    emit(
      state.copyWith(
        status: CollectionDashboardStatus.loading,
        filters: event.filters,
      ),
    );
    await _load(event.filters, emit);
  }

  Future<void> _onRetried(
    CollectionDashboardRetried event,
    Emitter<CollectionDashboardState> emit,
  ) async {
    final visibility = state.visibilityFilter;
    if (visibility == null) return;
    emit(
      state.copyWith(
        status: CollectionDashboardStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(state.filters, emit);
  }

  Future<void> _load(
    CollectionDashboardFilters filters,
    Emitter<CollectionDashboardState> emit,
  ) async {
    if (filters.collectionIds.isEmpty) {
      emit(
        state.copyWith(
          status: CollectionDashboardStatus.ready,
          entries: const <CollectionDashboardEntry>[],
          clearFailure: true,
        ),
      );
      return;
    }

    final selectedCollections = <Collection>[
      for (final collectionId in filters.collectionIds)
        ...state.collections.where(
          (collection) => collection.id == collectionId,
        ),
    ];
    if (selectedCollections.isEmpty) {
      emit(
        state.copyWith(
          status: CollectionDashboardStatus.ready,
          entries: const <CollectionDashboardEntry>[],
          clearFailure: true,
        ),
      );
      return;
    }

    final result = await _loadEntries(
      organizationId: state.organizationId,
      companyId: filters.companyId,
      collections: selectedCollections,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            status: CollectionDashboardStatus.error,
            failure: failure,
          ),
        );
        return;
      case AppSuccess(value: final entries):
        emit(
          state.copyWith(
            status: CollectionDashboardStatus.ready,
            entries: entries,
            clearFailure: true,
          ),
        );
    }

    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.dashboardViewed,
        parameters: <String, Object?>{
          'organization_id': state.organizationId,
          'dashboard_type': 'collection',
          'company_id': filters.companyId,
          'collection_ids': filters.collectionIds.join(','),
        },
      ),
    );
  }
}
