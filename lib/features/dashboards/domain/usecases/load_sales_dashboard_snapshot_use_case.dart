import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/aggregation_snapshot.dart';
import '../entities/executive_dashboard_trend_point.dart';
import '../entities/sales_dashboard_filters.dart';
import '../entities/sales_dashboard_kpi.dart';
import '../entities/sales_dashboard_snapshot.dart';
import '../repositories/aggregation_repository.dart';
import '../value_objects/aggregation_dimension.dart';

/// Assembles every KPI the Sales Dashboard (TASK-135) renders for one
/// [SalesDashboardFilters] scope/period, reading exclusively from
/// TASK-133's [AggregationRepository] — never a raw `orders` query, per the
/// BI aggregation rule in `AGENTS.md`.
///
/// **Team filter, same documented limitation
/// `LoadExecutiveDashboardSnapshotUseCase` already carries.** TASK-133 never
/// modeled a "por equipe" dimension — only `sellerMonthly` (por vendedor).
/// So when [teamMemberIds] is non-empty, every KPI is computed by summing
/// each member's own `sellerMonthly` snapshot instead of the company-wide
/// `salesDaily` total (one bounded `listByPeriod` read, filtered
/// client-side to the team's member ids) — the revenue trend sparkline
/// always stays company-wide even with a team filter active, since
/// `salesDaily` carries no seller/team dimension at all.
///
/// **Margin and "produtos por pedido" are always [SalesDashboardKpi
/// .notCalculated]** — see [SalesDashboardKpiStatus.notCalculated] for why
/// (no cost/margin data anywhere in the backend; no aggregation dimension
/// records distinct-SKU composition per order).
@injectable
final class LoadSalesDashboardSnapshotUseCase {
  const LoadSalesDashboardSnapshotUseCase(this._aggregationRepository);

  final AggregationRepository _aggregationRepository;

  /// A `sellerMonthly` bounded read easily covers even a large sales
  /// organization — same bound `LoadExecutiveDashboardSnapshotUseCase`
  /// already uses for the identical team-filter fold.
  static const int _sellerMonthlyLimit = 500;

  Future<AppResult<SalesDashboardSnapshot>> call({
    required String organizationId,
    required SalesDashboardFilters filters,
    List<String> teamMemberIds = const <String>[],
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = filters.companyId.trim();
    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<SalesDashboardSnapshot>(
        ValidationFailure(
          'Invalid sales dashboard payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_sales_dashboard_payload',
        ),
      );
    }

    final hasTeamFilter = (filters.teamId ?? '').trim().isNotEmpty;

    final currentResult = await _totals(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      hasTeamFilter: hasTeamFilter,
      teamMemberIds: teamMemberIds,
      year: filters.year,
      month: filters.month,
    );
    final previousMonthFilters = filters.previousMonth;
    final previousMonthResult = await _totals(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      hasTeamFilter: hasTeamFilter,
      teamMemberIds: teamMemberIds,
      year: previousMonthFilters.year,
      month: previousMonthFilters.month,
    );
    final previousYearFilters = filters.previousYear;
    final previousYearResult = await _totals(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      hasTeamFilter: hasTeamFilter,
      teamMemberIds: teamMemberIds,
      year: previousYearFilters.year,
      month: previousYearFilters.month,
    );

    final revenue = _metric(
      current: currentResult,
      previousMonth: previousMonthResult,
      previousYear: previousYearResult,
      valueOf: (r) => r.revenueNet,
    );
    final orders = _metric(
      current: currentResult,
      previousMonth: previousMonthResult,
      previousYear: previousYearResult,
      valueOf: (r) => r.orderCount.toDouble(),
    );
    final averageTicket = _metric(
      current: currentResult,
      previousMonth: previousMonthResult,
      previousYear: previousYearResult,
      valueOf: (r) => r.orderCount == 0 ? 0 : r.revenueNet / r.orderCount,
    );
    final itemQuantity = _metric(
      current: currentResult,
      previousMonth: previousMonthResult,
      previousYear: previousYearResult,
      valueOf: (r) => r.itemQuantity.toDouble(),
    );
    final discountAverage = _metric(
      current: currentResult,
      previousMonth: previousMonthResult,
      previousYear: previousYearResult,
      valueOf: (r) =>
          r.revenueGross == 0 ? 0 : (r.discountAmount / r.revenueGross) * 100,
    );
    final piecesPerOrder = _metric(
      current: currentResult,
      previousMonth: previousMonthResult,
      previousYear: previousYearResult,
      valueOf: (r) => r.orderCount == 0 ? 0 : r.itemQuantity / r.orderCount,
    );

    final revenueTrend = await _revenueTrend(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      filters: filters,
    );

    return AppSuccess<SalesDashboardSnapshot>(
      SalesDashboardSnapshot(
        revenue: revenue,
        orders: orders,
        averageTicket: averageTicket,
        itemQuantity: itemQuantity,
        discountAverage: discountAverage,
        // See this class's own docs / `SalesDashboardKpiStatus
        // .notCalculated`: no cost/margin data exists anywhere in the
        // backend yet — always shown as "not calculated", never fabricated.
        margin: const SalesDashboardKpi.notCalculated(),
        piecesPerOrder: piecesPerOrder,
        // See this class's own docs: no aggregation dimension records
        // distinct-SKU composition per order.
        productsPerOrder: const SalesDashboardKpi.notCalculated(),
        revenueTrend: revenueTrend,
      ),
    );
  }

  Future<AppResult<_PeriodTotals>> _totals({
    required String organizationId,
    required String companyId,
    required bool hasTeamFilter,
    required List<String> teamMemberIds,
    required int year,
    required int month,
  }) async {
    if (hasTeamFilter) {
      if (teamMemberIds.isEmpty) {
        return const AppSuccess<_PeriodTotals>(_PeriodTotals.zero());
      }
      final monthKey = _monthKey(year, month);
      final result = await _aggregationRepository.listByPeriod(
        organizationId: organizationId,
        dimension: AggregationDimension.sellerMonthly,
        companyId: companyId,
        periodKey: monthKey,
        limit: _sellerMonthlyLimit,
      );
      switch (result) {
        case AppFailure<List<AggregationSnapshot>>(failure: final failure):
          return AppFailure<_PeriodTotals>(failure);
        case AppSuccess<List<AggregationSnapshot>>(value: final snapshots):
          final memberIdSet = teamMemberIds.toSet();
          final teamSnapshots = snapshots.where(
            (snapshot) => memberIdSet.contains(snapshot.scopeId),
          );
          return AppSuccess<_PeriodTotals>(_PeriodTotals.fold(teamSnapshots));
      }
    }

    final result = await _aggregationRepository.listByPeriodRange(
      organizationId: organizationId,
      dimension: AggregationDimension.salesDaily,
      companyId: companyId,
      scopeId: companyId,
      fromPeriodKey: _firstDayKey(year, month),
      toPeriodKey: _lastDayKey(year, month),
    );
    switch (result) {
      case AppFailure<List<AggregationSnapshot>>(failure: final failure):
        return AppFailure<_PeriodTotals>(failure);
      case AppSuccess<List<AggregationSnapshot>>(value: final snapshots):
        return AppSuccess<_PeriodTotals>(_PeriodTotals.fold(snapshots));
    }
  }

  Future<List<ExecutiveDashboardTrendPoint>> _revenueTrend({
    required String organizationId,
    required String companyId,
    required SalesDashboardFilters filters,
  }) async {
    final result = await _aggregationRepository.listByPeriodRange(
      organizationId: organizationId,
      dimension: AggregationDimension.salesDaily,
      companyId: companyId,
      scopeId: companyId,
      fromPeriodKey: _firstDayKey(filters.year, filters.month),
      toPeriodKey: _lastDayKey(filters.year, filters.month),
    );
    // Best-effort: the trend sparkline degrades to "sem dados" on failure
    // (`AppManagementChart` already renders an empty list as its own empty
    // state) rather than failing the whole snapshot over a chart-only read.
    if (result case AppFailure<List<AggregationSnapshot>>()) {
      return const <ExecutiveDashboardTrendPoint>[];
    }
    final snapshots = (result as AppSuccess<List<AggregationSnapshot>>).value;
    return snapshots
        .map(
          (snapshot) => ExecutiveDashboardTrendPoint(
            day: DateTime.parse(snapshot.periodKey),
            value: snapshot.revenueNet,
          ),
        )
        .toList(growable: false);
  }

  SalesDashboardKpi _metric({
    required AppResult<_PeriodTotals> current,
    required AppResult<_PeriodTotals> previousMonth,
    required AppResult<_PeriodTotals> previousYear,
    required double Function(_PeriodTotals) valueOf,
  }) {
    if (current case AppFailure<_PeriodTotals>(failure: final failure)) {
      return SalesDashboardKpi.failed(failure.message);
    }
    final currentValue = valueOf((current as AppSuccess<_PeriodTotals>).value);
    final previousMonthValue = switch (previousMonth) {
      AppSuccess<_PeriodTotals>(value: final value) => valueOf(value),
      AppFailure<_PeriodTotals>() => null,
    };
    final previousYearValue = switch (previousYear) {
      AppSuccess<_PeriodTotals>(value: final value) => valueOf(value),
      AppFailure<_PeriodTotals>() => null,
    };
    return SalesDashboardKpi.available(
      value: currentValue,
      previousMonthValue: previousMonthValue,
      previousYearValue: previousYearValue,
    );
  }

  String _monthKey(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  String _firstDayKey(int year, int month) => '${_monthKey(year, month)}-01';

  String _lastDayKey(int year, int month) {
    final lastDay = DateTime.utc(year, month + 1, 0).day;
    return '${_monthKey(year, month)}-${lastDay.toString().padLeft(2, '0')}';
  }
}

final class _PeriodTotals {
  const _PeriodTotals({
    required this.revenueGross,
    required this.revenueNet,
    required this.discountAmount,
    required this.orderCount,
    required this.itemQuantity,
  });

  const _PeriodTotals.zero()
    : revenueGross = 0,
      revenueNet = 0,
      discountAmount = 0,
      orderCount = 0,
      itemQuantity = 0;

  factory _PeriodTotals.fold(Iterable<AggregationSnapshot> snapshots) {
    return _PeriodTotals(
      revenueGross: snapshots.fold<double>(
        0,
        (sum, snapshot) => sum + snapshot.revenueGross,
      ),
      revenueNet: snapshots.fold<double>(
        0,
        (sum, snapshot) => sum + snapshot.revenueNet,
      ),
      discountAmount: snapshots.fold<double>(
        0,
        (sum, snapshot) => sum + snapshot.discountAmount,
      ),
      orderCount: snapshots.fold<int>(
        0,
        (sum, snapshot) => sum + snapshot.orderCount,
      ),
      itemQuantity: snapshots.fold<int>(
        0,
        (sum, snapshot) => sum + snapshot.itemQuantity,
      ),
    );
  }

  final double revenueGross;
  final double revenueNet;
  final double discountAmount;
  final int orderCount;
  final int itemQuantity;
}
