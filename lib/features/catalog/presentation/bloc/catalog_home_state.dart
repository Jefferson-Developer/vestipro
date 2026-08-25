import '../../../../core/errors/errors.dart';
import '../../domain/entities/catalog_home_section.dart';
import '../../domain/entities/catalog_home_section_type.dart';

enum CatalogHomeLoadStatus { initial, loading, ready, failure }

final class CatalogHomeState {
  const CatalogHomeState({
    this.status = CatalogHomeLoadStatus.initial,
    this.organizationId = '',
    this.companyId,
    this.userId = '',
    this.sections = const <CatalogHomeSection>[],
    this.sectionFailures = const <CatalogHomeSectionType, Failure>{},
    this.isStale = false,
    this.isRefreshing = false,
    this.cachedAt,
    this.failure,
    this.hasLoggedViewed = false,
  });

  final CatalogHomeLoadStatus status;
  final String organizationId;
  final String? companyId;
  final String userId;

  /// Only non-empty, already-sorted-by-order sections — a section with no
  /// items is never kept here (TASK-076: never render an empty
  /// title/container).
  final List<CatalogHomeSection> sections;

  /// Sections whose use case failed on the last load attempt, keyed by
  /// type — kept separate from [sections] so a partial failure never wipes
  /// out sections that DID load successfully.
  final Map<CatalogHomeSectionType, Failure> sectionFailures;

  /// Whether [sections] currently on screen came from the local cache
  /// (stale-while-revalidate) rather than the latest fetch — drives the
  /// "dado pode estar desatualizado" notice on `CatalogHomePage`.
  final bool isStale;

  /// Whether a background refresh (pull-to-refresh or a post-cache
  /// revalidation) is in flight while [sections] already has content to
  /// show — distinct from [status] `loading`, which is only the very first,
  /// nothing-to-show-yet load.
  final bool isRefreshing;

  final DateTime? cachedAt;

  /// Only set when nothing could be shown at all: no cache and every
  /// enabled section failed. Never set while [sections] has content — a
  /// partial failure surfaces through [sectionFailures] instead.
  final Failure? failure;

  final bool hasLoggedViewed;

  bool get isInitialLoading =>
      status == CatalogHomeLoadStatus.initial ||
      (status == CatalogHomeLoadStatus.loading && sections.isEmpty && !isStale);

  CatalogHomeState copyWith({
    CatalogHomeLoadStatus? status,
    String? organizationId,
    String? companyId,
    bool clearCompanyId = false,
    String? userId,
    List<CatalogHomeSection>? sections,
    Map<CatalogHomeSectionType, Failure>? sectionFailures,
    bool? isStale,
    bool? isRefreshing,
    DateTime? cachedAt,
    bool clearCachedAt = false,
    Failure? failure,
    bool clearFailure = false,
    bool? hasLoggedViewed,
  }) {
    return CatalogHomeState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      companyId: clearCompanyId ? null : companyId ?? this.companyId,
      userId: userId ?? this.userId,
      sections: sections ?? this.sections,
      sectionFailures: sectionFailures ?? this.sectionFailures,
      isStale: isStale ?? this.isStale,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      cachedAt: clearCachedAt ? null : cachedAt ?? this.cachedAt,
      failure: clearFailure ? null : failure ?? this.failure,
      hasLoggedViewed: hasLoggedViewed ?? this.hasLoggedViewed,
    );
  }
}
