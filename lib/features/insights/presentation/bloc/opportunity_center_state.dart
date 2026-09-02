import '../../../../core/errors/errors.dart';
import '../../domain/entities/insight.dart';
import '../../domain/entities/opportunity_center_filters.dart';
import '../../domain/value_objects/insight_severity.dart';
import '../../domain/value_objects/insight_sort_by.dart';
import '../../domain/value_objects/insight_status.dart';

enum OpportunityCenterLoadStatus {
  initial,
  loading,
  ready,
  loadingMore,
  failure,
}

/// The most recent discard/resolve action, kept until either its
/// [OpportunityCenterUndoRequested] fires or another action supersedes it —
/// mirrors the "one active undo at a time" contract `AppSnackbar` already
/// enforces for the toast itself.
final class OpportunityCenterPendingUndo {
  const OpportunityCenterPendingUndo({
    required this.insight,
    required this.previousStatus,
    required this.appliedStatus,
  });

  /// The insight exactly as it was before the action — reinserted verbatim
  /// (with [previousStatus] restored) on undo.
  final Insight insight;
  final InsightStatus previousStatus;
  final InsightStatus appliedStatus;
}

final class OpportunityCenterState {
  const OpportunityCenterState({
    this.status = OpportunityCenterLoadStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.insights = const <Insight>[],
    this.filters = OpportunityCenterFilters.empty,
    this.hasMore = false,
    this.nextCursor,
    this.failure,
    this.pendingUndo,
  });

  final OpportunityCenterLoadStatus status;
  final String organizationId;
  final String companyId;
  final String userId;

  /// Every `Insight` loaded so far for the caller's visibility scope,
  /// already excluding `dismissed`/`resolved` (the repository never returns
  /// those). Filtering/sorting for display is derived by [visibleInsights],
  /// never mutating this list, so "paginação preservando itens já
  /// carregados" holds when [filters] changes.
  final List<Insight> insights;
  final OpportunityCenterFilters filters;
  final bool hasMore;
  final DateTime? nextCursor;
  final Failure? failure;
  final OpportunityCenterPendingUndo? pendingUndo;

  bool get isInitialLoading =>
      status == OpportunityCenterLoadStatus.initial ||
      status == OpportunityCenterLoadStatus.loading;

  bool get isLoadingMore => status == OpportunityCenterLoadStatus.loadingMore;

  /// [insights] filtered by [filters] and sorted by [OpportunityCenterFilters.sortBy]
  /// — impact estimado by default, per TASK-132's mandatory rule.
  List<Insight> get visibleInsights {
    final filtered = insights
        .where(
          (insight) => filters.matches(
            type: insight.type,
            severity: insight.severity,
            generatedAt: insight.generatedAt,
          ),
        )
        .toList(growable: false);

    switch (filters.sortBy) {
      case InsightSortBy.estimatedImpact:
        filtered.sort((a, b) => _impactScore(b).compareTo(_impactScore(a)));
      case InsightSortBy.generatedAt:
        filtered.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      case InsightSortBy.relatedEntity:
        filtered.sort((a, b) {
          final keyCompare = _relatedEntityKey(
            a,
          ).compareTo(_relatedEntityKey(b));
          if (keyCompare != 0) return keyCompare;
          return _impactScore(b).compareTo(_impactScore(a));
        });
    }
    return filtered;
  }

  OpportunityCenterState copyWith({
    OpportunityCenterLoadStatus? status,
    String? organizationId,
    String? companyId,
    String? userId,
    List<Insight>? insights,
    OpportunityCenterFilters? filters,
    bool? hasMore,
    DateTime? nextCursor,
    bool clearNextCursor = false,
    Failure? failure,
    bool clearFailure = false,
    OpportunityCenterPendingUndo? pendingUndo,
    bool clearPendingUndo = false,
  }) {
    return OpportunityCenterState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      insights: insights ?? this.insights,
      filters: filters ?? this.filters,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      failure: clearFailure ? null : (failure ?? this.failure),
      pendingUndo: clearPendingUndo ? null : (pendingUndo ?? this.pendingUndo),
    );
  }
}

/// Pragmatic single comparable impact score: `Insight.estimatedImpact` mixes
/// a currency amount with a percentage depending on the insight type
/// (TASK-122 a TASK-131), with no single normalized unit modeled anywhere
/// else in the domain, so amount takes priority, then percentage (weighted
/// so it is comparable to a realistic order-of-magnitude amount), then
/// `InsightSeverity` as the final tie-breaker.
double _impactScore(Insight insight) {
  final impact = insight.estimatedImpact;
  if (impact.amount != null) return impact.amount!;
  if (impact.percentage != null) return impact.percentage! * 1000;
  return _severityScore(insight.severity);
}

double _severityScore(InsightSeverity severity) {
  return switch (severity) {
    InsightSeverity.critical => 3,
    InsightSeverity.high => 2,
    InsightSeverity.medium => 1,
    InsightSeverity.low => 0,
  };
}

String _relatedEntityKey(Insight insight) {
  return insight.customerId ??
      insight.sellerId ??
      insight.productId ??
      insight.type.name;
}
