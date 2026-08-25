import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/catalog_home_section.dart';
import '../../domain/entities/catalog_home_section_config.dart';
import '../../domain/entities/catalog_home_section_type.dart';
import '../../domain/entities/catalog_home_snapshot.dart';
import '../../domain/usecases/get_catalog_campaigns_section_use_case.dart';
import '../../domain/usecases/get_catalog_home_config_use_case.dart';
import '../../domain/usecases/get_featured_collections_section_use_case.dart';
import '../../domain/usecases/get_new_arrivals_section_use_case.dart';
import '../../domain/usecases/load_catalog_home_cache_use_case.dart';
import '../../domain/usecases/save_catalog_home_cache_use_case.dart';
import 'catalog_home_event.dart';
import 'catalog_home_state.dart';

/// Orchestrates the catalog home (TASK-076): first paints any cached
/// snapshot instantly, then fetches every enabled section in parallel via
/// independent use cases — one section failing never derails the others,
/// which is exactly why this loads/tracks each section through its own
/// `AppResult` instead of a single combined use case.
@injectable
final class CatalogHomeBloc extends Bloc<CatalogHomeEvent, CatalogHomeState> {
  CatalogHomeBloc({
    required this.getCatalogHomeConfig,
    required this.getFeaturedCollectionsSection,
    required this.getNewArrivalsSection,
    required this.getCatalogCampaignsSection,
    required this.loadCatalogHomeCache,
    required this.saveCatalogHomeCache,
    required this.analyticsService,
  }) : super(const CatalogHomeState()) {
    on<CatalogHomeStarted>(_onStarted);
    on<CatalogHomeRefreshRequested>(_onRefreshRequested);
    on<CatalogHomeSectionOpened>(_onSectionOpened);
  }

  final GetCatalogHomeConfigUseCase getCatalogHomeConfig;
  final GetFeaturedCollectionsSectionUseCase getFeaturedCollectionsSection;
  final GetNewArrivalsSectionUseCase getNewArrivalsSection;
  final GetCatalogCampaignsSectionUseCase getCatalogCampaignsSection;
  final LoadCatalogHomeCacheUseCase loadCatalogHomeCache;
  final SaveCatalogHomeCacheUseCase saveCatalogHomeCache;
  final AnalyticsService analyticsService;

  Future<void> _onStarted(
    CatalogHomeStarted event,
    Emitter<CatalogHomeState> emit,
  ) async {
    emit(
      CatalogHomeState(
        status: CatalogHomeLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
      ),
    );

    final cacheResult = await loadCatalogHomeCache(
      organizationId: event.organizationId,
      companyId: event.companyId,
    );
    if (emit.isDone) return;

    final cachedSnapshot = cacheResult.fold(
      onSuccess: (snapshot) => snapshot,
      onFailure: (_) => null,
    );
    if (cachedSnapshot != null) {
      emit(
        state.copyWith(
          status: CatalogHomeLoadStatus.ready,
          sections: cachedSnapshot.sections,
          isStale: true,
          cachedAt: cachedSnapshot.savedAt,
        ),
      );
      await _logViewedIfNeeded(emit);
      if (emit.isDone) return;
    }

    await _loadFreshSections(emit);
  }

  Future<void> _onRefreshRequested(
    CatalogHomeRefreshRequested event,
    Emitter<CatalogHomeState> emit,
  ) async {
    if (state.organizationId.isEmpty || state.isRefreshing) return;
    emit(state.copyWith(isRefreshing: true));
    await _loadFreshSections(emit);
  }

  Future<void> _onSectionOpened(
    CatalogHomeSectionOpened event,
    Emitter<CatalogHomeState> emit,
  ) async {
    await analyticsService.logEvent(
      AnalyticsEvents.catalogSectionOpened,
      parameters: <String, Object?>{
        'organization_id': state.organizationId,
        'section_type': event.type.name,
      },
    );
  }

  Future<void> _loadFreshSections(Emitter<CatalogHomeState> emit) async {
    final configs = await getCatalogHomeConfig(state.organizationId);
    if (emit.isDone) return;

    final organizationId = state.organizationId;
    final companyId = state.companyId;
    final enabledConfigs = configs.where((config) => config.enabled);

    final entries =
        <
          Future<
            MapEntry<CatalogHomeSectionType, AppResult<CatalogHomeSection>>
          >
        >[];
    for (final config in enabledConfigs) {
      final runner = _runnerFor(
        config.type,
        organizationId: organizationId,
        companyId: companyId,
      );
      if (runner == null) continue;
      entries.add(
        runner(config).then((result) => MapEntry(config.type, result)),
      );
    }

    final results = await Future.wait(entries);
    if (emit.isDone) return;

    final freshSections = <CatalogHomeSection>[];
    final failures = <CatalogHomeSectionType, Failure>{};
    for (final entry in results) {
      switch (entry.value) {
        case AppSuccess<CatalogHomeSection>(value: final section):
          if (!section.isEmpty) freshSections.add(section);
        case AppFailure<CatalogHomeSection>(failure: final failure):
          failures[entry.key] = failure;
      }
    }
    freshSections.sort((a, b) => a.order.compareTo(b.order));
    final allAttemptedFailed =
        entries.isNotEmpty && failures.length == entries.length;

    if (freshSections.isNotEmpty) {
      final snapshot = CatalogHomeSnapshot(
        sections: freshSections,
        savedAt: DateTime.now().toUtc(),
      );
      await saveCatalogHomeCache(
        organizationId: organizationId,
        companyId: companyId,
        snapshot: snapshot,
      );
      if (emit.isDone) return;
      emit(
        state.copyWith(
          status: CatalogHomeLoadStatus.ready,
          sections: freshSections,
          sectionFailures: failures,
          isStale: false,
          isRefreshing: false,
          cachedAt: snapshot.savedAt,
          clearFailure: true,
        ),
      );
      await _logViewedIfNeeded(emit);
      return;
    }

    if (state.sections.isNotEmpty) {
      // Nothing fresh came back (offline/failure), but we already have
      // cached or previously-loaded sections to keep showing — never blank
      // the screen just because a revalidation attempt failed.
      emit(
        state.copyWith(
          isRefreshing: false,
          sectionFailures: failures,
          isStale: allAttemptedFailed ? true : state.isStale,
        ),
      );
      await _logViewedIfNeeded(emit);
      return;
    }

    if (allAttemptedFailed) {
      emit(
        state.copyWith(
          status: CatalogHomeLoadStatus.failure,
          isRefreshing: false,
          sectionFailures: failures,
          failure: failures.values.first,
        ),
      );
      return;
    }

    // Every enabled section that has a runner succeeded, but the
    // organization genuinely has no content yet — a valid empty state, not
    // an error.
    emit(
      state.copyWith(
        status: CatalogHomeLoadStatus.ready,
        sections: const <CatalogHomeSection>[],
        sectionFailures: failures,
        isStale: false,
        isRefreshing: false,
        clearFailure: true,
      ),
    );
    await _logViewedIfNeeded(emit);
  }

  Future<void> _logViewedIfNeeded(Emitter<CatalogHomeState> emit) async {
    if (state.hasLoggedViewed) return;
    await analyticsService.logEvent(
      AnalyticsEvents.catalogHomeViewed,
      parameters: <String, Object?>{
        'organization_id': state.organizationId,
        'sections_count': state.sections.length,
        'is_stale': state.isStale,
      },
    );
    if (emit.isDone) return;
    emit(state.copyWith(hasLoggedViewed: true));
  }

  /// Maps a section type to its use case call, or `null` when no use case is
  /// registered yet (`bestSellers`/`recommended`/`readyToShip` — see
  /// `CatalogHomeSectionType`'s doc). A config enabling an unregistered type
  /// is silently skipped, never counted as an attempted-and-failed section.
  Future<AppResult<CatalogHomeSection>> Function(
    CatalogHomeSectionConfig config,
  )?
  _runnerFor(
    CatalogHomeSectionType type, {
    required String organizationId,
    String? companyId,
  }) {
    switch (type) {
      case CatalogHomeSectionType.featuredCollections:
        return (config) => getFeaturedCollectionsSection(
          organizationId: organizationId,
          config: config,
        );
      case CatalogHomeSectionType.newArrivals:
        return (config) => getNewArrivalsSection(
          organizationId: organizationId,
          companyId: companyId,
          config: config,
        );
      case CatalogHomeSectionType.campaigns:
        return (config) => getCatalogCampaignsSection(
          organizationId: organizationId,
          config: config,
        );
      case CatalogHomeSectionType.bestSellers:
      case CatalogHomeSectionType.recommended:
      case CatalogHomeSectionType.readyToShip:
        return null;
    }
  }
}
