import '../../../../core/errors/errors.dart';
import '../../domain/entities/customer_dashboard_filters.dart';
import '../../domain/entities/customer_dashboard_ranking_row.dart';
import '../../domain/entities/customer_dashboard_snapshot.dart';
import '../../domain/entities/executive_dashboard_visibility_filter.dart';
import 'executive_dashboard_state.dart' show ExecutiveDashboardScopeOption;

enum CustomerDashboardStatus { initial, loading, forbidden, error, ready }

enum CustomerDashboardRankingStatus { loading, ready, error }

final class CustomerDashboardState {
  const CustomerDashboardState({
    this.status = CustomerDashboardStatus.initial,
    this.organizationId = '',
    this.userId = '',
    this.visibilityFilter,
    this.filters = const CustomerDashboardFilters(
      companyId: '',
      year: 2024,
      month: 1,
    ),
    this.companyOptions = const <ExecutiveDashboardScopeOption>[],
    this.teamOptions = const <ExecutiveDashboardScopeOption>[],
    this.snapshot,
    this.rankingStatus = CustomerDashboardRankingStatus.loading,
    this.rankingRows = const <CustomerDashboardRankingRow>[],
    this.rankingFailure,
    this.visibleRankingCount = pageSize,
    this.failure,
  });

  /// How many ranking rows one "page" reveals — also the initial visible
  /// count and the increment `CustomerDashboardRankingPageRequested` grows
  /// it by.
  static const int pageSize = 20;

  final CustomerDashboardStatus status;
  final String organizationId;
  final String userId;

  /// Reuses `ExecutiveDashboardVisibilityFilter` verbatim — same RBAC
  /// scoping semantics `SalesDashboardState`/`ExecutiveDashboardState`
  /// already share, see `CustomerDashboardBloc`'s own docs.
  final ExecutiveDashboardVisibilityFilter? visibilityFilter;
  final CustomerDashboardFilters filters;
  final List<ExecutiveDashboardScopeOption> companyOptions;
  final List<ExecutiveDashboardScopeOption> teamOptions;
  final CustomerDashboardSnapshot? snapshot;

  /// Loaded independently from [snapshot]: a failed ranking table never
  /// blocks the KPI cards, and vice-versa.
  final CustomerDashboardRankingStatus rankingStatus;

  /// Every row fetched for the current filters, already sorted/filtered —
  /// the bounded, in-memory list [visibleRankingRows] windows over for
  /// pagination.
  final List<CustomerDashboardRankingRow> rankingRows;
  final Failure? rankingFailure;

  /// How many of [rankingRows], from the start, are currently "visible" —
  /// grown by [CustomerDashboardRankingPageRequested], reset to [pageSize]
  /// on any new fetch.
  final int visibleRankingCount;

  final Failure? failure;

  /// The current page of the ranking table — a prefix of [rankingRows], so
  /// growing [visibleRankingCount] always preserves every row already
  /// rendered.
  List<CustomerDashboardRankingRow> get visibleRankingRows {
    if (visibleRankingCount >= rankingRows.length) return rankingRows;
    return rankingRows.sublist(0, visibleRankingCount);
  }

  bool get hasMoreRankingRows => visibleRankingCount < rankingRows.length;

  /// Whether the caller may pick a company/team other than their own —
  /// mirrors `SalesDashboardState.canPickScope`.
  bool get canPickScope =>
      visibilityFilter?.mode ==
          ExecutiveDashboardVisibilityMode.allOrganization ||
      companyOptions.length > 1 ||
      teamOptions.isNotEmpty;

  CustomerDashboardState copyWith({
    CustomerDashboardStatus? status,
    String? organizationId,
    String? userId,
    ExecutiveDashboardVisibilityFilter? visibilityFilter,
    CustomerDashboardFilters? filters,
    List<ExecutiveDashboardScopeOption>? companyOptions,
    List<ExecutiveDashboardScopeOption>? teamOptions,
    CustomerDashboardSnapshot? snapshot,
    CustomerDashboardRankingStatus? rankingStatus,
    List<CustomerDashboardRankingRow>? rankingRows,
    Failure? rankingFailure,
    bool clearRankingFailure = false,
    int? visibleRankingCount,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return CustomerDashboardState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      visibilityFilter: visibilityFilter ?? this.visibilityFilter,
      filters: filters ?? this.filters,
      companyOptions: companyOptions ?? this.companyOptions,
      teamOptions: teamOptions ?? this.teamOptions,
      snapshot: snapshot ?? this.snapshot,
      rankingStatus: rankingStatus ?? this.rankingStatus,
      rankingRows: rankingRows ?? this.rankingRows,
      rankingFailure: clearRankingFailure
          ? null
          : (rankingFailure ?? this.rankingFailure),
      visibleRankingCount: visibleRankingCount ?? this.visibleRankingCount,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
