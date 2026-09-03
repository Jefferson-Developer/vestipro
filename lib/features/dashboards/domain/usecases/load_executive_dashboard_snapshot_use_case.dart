import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../targets/domain/entities/positivacao_snapshot.dart';
import '../../../targets/domain/entities/target.dart';
import '../../../targets/domain/entities/target_achievement_snapshot.dart';
import '../../../targets/domain/entities/target_progress_view_model.dart';
import '../../../targets/domain/repositories/positivacao_repository.dart';
import '../../../targets/domain/repositories/target_achievement_repository.dart';
import '../../../targets/domain/repositories/target_repository.dart';
import '../../../targets/domain/target_period_overlap.dart';
import '../../../targets/domain/value_objects/positivacao_dimension_type.dart';
import '../../../targets/domain/value_objects/target_dimension_type.dart';
import '../../../targets/domain/value_objects/target_metric_type.dart';
import '../entities/aggregation_snapshot.dart';
import '../entities/executive_dashboard_filters.dart';
import '../entities/executive_dashboard_metric.dart';
import '../entities/executive_dashboard_snapshot.dart';
import '../entities/executive_dashboard_trend_point.dart';
import '../repositories/aggregation_repository.dart';
import '../value_objects/aggregation_dimension.dart';

/// Assembles every KPI the Executive Dashboard (TASK-134) renders for one
/// [ExecutiveDashboardFilters] scope/period, reading exclusively from
/// already-server-computed snapshot contracts — TASK-133's
/// [AggregationRepository] for faturamento/pedidos/ticket médio/crescimento,
/// TASK-117's [PositivacaoRepository] for clientes ativos/positivação, and
/// TASK-116's [TargetRepository]/[TargetAchievementRepository] for
/// atingimento de meta consolidado. Never sums a raw `orders`/`customers`
/// document itself, per the BI aggregation rule in `AGENTS.md`.
///
/// Every field of the returned [ExecutiveDashboardSnapshot] degrades
/// independently: a failure resolving one repository never blocks the
/// others ("um KPI falha e os demais continuam exibidos", this task's own
/// testing requirement) — this method only ever returns [AppFailure] for an
/// invalid input payload, never for a downstream data failure.
///
/// **Team filter, documented limitation.** TASK-133 modeled exactly five
/// aggregation dimensions and none of them is "por equipe" — only
/// `sellerMonthly` (por vendedor). So when [teamMemberIds] is non-empty
/// (the caller/`ExecutiveDashboardBloc` already resolved which sellers
/// belong to the filtered team), faturamento/pedidos/ticket médio/
/// crescimento are computed by summing every seller's own `sellerMonthly`
/// snapshot instead of reading the exact `salesDaily` company total — a
/// single bounded read (`AggregationRepository.listByPeriod`, filtered
/// client-side to the team's member ids) that can only omit revenue from an
/// order with no assigned seller, never double-count one. The revenue trend
/// sparkline and "clientes ativos"/"clientes novos" always stay
/// company-wide even with a team filter active, since neither `salesDaily`
/// nor `customerMonthly` carries a seller/team dimension at all — the
/// positivação/atingimento-de-meta KPIs are the only two team-narrowable
/// beyond revenue/pedidos, since `PositivacaoDimensionType`/
/// `TargetDimensionType` both already model `team` natively (TASK-116/
/// TASK-117), independently of TASK-133's aggregation dimensions.
@injectable
final class LoadExecutiveDashboardSnapshotUseCase {
  const LoadExecutiveDashboardSnapshotUseCase(
    this._aggregationRepository,
    this._positivacaoRepository,
    this._targetRepository,
    this._targetAchievementRepository,
  );

  final AggregationRepository _aggregationRepository;
  final PositivacaoRepository _positivacaoRepository;
  final TargetRepository _targetRepository;
  final TargetAchievementRepository _targetAchievementRepository;

  /// A `sellerMonthly` bounded read easily covers even a large sales
  /// organization; a company with more active sellers than this in a single
  /// month would need this bound revisited, documented rather than silently
  /// truncated.
  static const int _sellerMonthlyLimit = 500;

  Future<AppResult<ExecutiveDashboardSnapshot>> call({
    required String organizationId,
    required ExecutiveDashboardFilters filters,
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
      return AppFailure<ExecutiveDashboardSnapshot>(
        ValidationFailure(
          'Invalid executive dashboard payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_executive_dashboard_payload',
        ),
      );
    }

    final hasTeamFilter = (filters.teamId ?? '').trim().isNotEmpty;

    final currentResult = await _revenueAndOrders(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      hasTeamFilter: hasTeamFilter,
      teamMemberIds: teamMemberIds,
      year: filters.year,
      month: filters.month,
    );
    final previousMonthFilters = filters.previousMonth;
    final previousMonthResult = await _revenueAndOrders(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      hasTeamFilter: hasTeamFilter,
      teamMemberIds: teamMemberIds,
      year: previousMonthFilters.year,
      month: previousMonthFilters.month,
    );
    final previousYearFilters = filters.previousYear;
    final previousYearResult = await _revenueAndOrders(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      hasTeamFilter: hasTeamFilter,
      teamMemberIds: teamMemberIds,
      year: previousYearFilters.year,
      month: previousYearFilters.month,
    );

    final revenue = _revenueMetric(
      current: currentResult,
      previous: previousMonthResult,
      valueOf: (r) => r.revenueNet,
    );
    final orders = _revenueMetric(
      current: currentResult,
      previous: previousMonthResult,
      valueOf: (r) => r.orderCount.toDouble(),
    );
    final averageTicket = _revenueMetric(
      current: currentResult,
      previous: previousMonthResult,
      valueOf: (r) => r.orderCount == 0 ? 0 : r.revenueNet / r.orderCount,
    );
    final revenueGrowthMoM = _growthMetric(
      current: currentResult,
      comparison: previousMonthResult,
    );
    final revenueGrowthYoY = _growthMetric(
      current: currentResult,
      comparison: previousYearResult,
    );

    final revenueTrend = await _revenueTrend(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      filters: filters,
    );

    final portfolioDimensionType = hasTeamFilter
        ? PositivacaoDimensionType.team
        : PositivacaoDimensionType.company;
    final portfolioDimensionId = hasTeamFilter
        ? filters.teamId!.trim()
        : trimmedCompanyId;

    final currentPositivacao = await _positivacaoRepository.getForDimension(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      dimensionType: portfolioDimensionType,
      dimensionId: portfolioDimensionId,
      periodStart: filters.periodStart,
      periodEnd: filters.periodEnd,
    );
    final previousPositivacao = await _positivacaoRepository.getForDimension(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      dimensionType: portfolioDimensionType,
      dimensionId: portfolioDimensionId,
      periodStart: previousMonthFilters.periodStart,
      periodEnd: previousMonthFilters.periodEnd,
    );

    final activeCustomers = _positivacaoMetric(
      current: currentPositivacao,
      previous: previousPositivacao,
      valueOf: (s) => s.positivatedCount!.toDouble(),
    );
    final positivacaoPercentage = _positivacaoMetric(
      current: currentPositivacao,
      previous: previousPositivacao,
      valueOf: (s) => s.percentage,
    );

    final targetAchievementPercentage = await _targetAchievement(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      dimensionType: hasTeamFilter
          ? TargetDimensionType.team
          : TargetDimensionType.company,
      dimensionId: hasTeamFilter ? filters.teamId!.trim() : trimmedCompanyId,
      filters: filters,
    );

    return AppSuccess<ExecutiveDashboardSnapshot>(
      ExecutiveDashboardSnapshot(
        revenue: revenue,
        orders: orders,
        averageTicket: averageTicket,
        activeCustomers: activeCustomers,
        // See this class's own doc comment: no aggregation/customer field
        // today distinguishes "primeira compra neste período" without a
        // client-side scan of full order history, which the task's own
        // rule forbids — always shown as "not calculated", never fabricated.
        newCustomers: const ExecutiveDashboardMetric.notCalculated(),
        positivacaoPercentage: positivacaoPercentage,
        targetAchievementPercentage: targetAchievementPercentage,
        revenueGrowthMoM: revenueGrowthMoM,
        revenueGrowthYoY: revenueGrowthYoY,
        revenueTrend: revenueTrend,
      ),
    );
  }

  Future<AppResult<_RevenueOrders>> _revenueAndOrders({
    required String organizationId,
    required String companyId,
    required bool hasTeamFilter,
    required List<String> teamMemberIds,
    required int year,
    required int month,
  }) async {
    if (hasTeamFilter) {
      if (teamMemberIds.isEmpty) {
        return const AppSuccess<_RevenueOrders>(
          _RevenueOrders(revenueNet: 0, orderCount: 0),
        );
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
          return AppFailure<_RevenueOrders>(failure);
        case AppSuccess<List<AggregationSnapshot>>(value: final snapshots):
          final memberIdSet = teamMemberIds.toSet();
          final teamSnapshots = snapshots.where(
            (snapshot) => memberIdSet.contains(snapshot.scopeId),
          );
          return AppSuccess<_RevenueOrders>(
            _RevenueOrders(
              revenueNet: teamSnapshots.fold<double>(
                0,
                (sum, snapshot) => sum + snapshot.revenueNet,
              ),
              orderCount: teamSnapshots.fold<int>(
                0,
                (sum, snapshot) => sum + snapshot.orderCount,
              ),
            ),
          );
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
        return AppFailure<_RevenueOrders>(failure);
      case AppSuccess<List<AggregationSnapshot>>(value: final snapshots):
        return AppSuccess<_RevenueOrders>(
          _RevenueOrders(
            revenueNet: snapshots.fold<double>(
              0,
              (sum, snapshot) => sum + snapshot.revenueNet,
            ),
            orderCount: snapshots.fold<int>(
              0,
              (sum, snapshot) => sum + snapshot.orderCount,
            ),
          ),
        );
    }
  }

  Future<List<ExecutiveDashboardTrendPoint>> _revenueTrend({
    required String organizationId,
    required String companyId,
    required ExecutiveDashboardFilters filters,
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

  ExecutiveDashboardMetric _revenueMetric({
    required AppResult<_RevenueOrders> current,
    required AppResult<_RevenueOrders> previous,
    required double Function(_RevenueOrders) valueOf,
  }) {
    if (current case AppFailure<_RevenueOrders>(failure: final failure)) {
      return ExecutiveDashboardMetric.failed(failure.message);
    }
    final currentValue = valueOf((current as AppSuccess<_RevenueOrders>).value);
    final previousValue = switch (previous) {
      AppSuccess<_RevenueOrders>(value: final value) => valueOf(value),
      AppFailure<_RevenueOrders>() => null,
    };
    return ExecutiveDashboardMetric.available(
      value: currentValue,
      previousValue: previousValue,
    );
  }

  ExecutiveDashboardMetric _growthMetric({
    required AppResult<_RevenueOrders> current,
    required AppResult<_RevenueOrders> comparison,
  }) {
    if (current case AppFailure<_RevenueOrders>(failure: final failure)) {
      return ExecutiveDashboardMetric.failed(failure.message);
    }
    if (comparison case AppFailure<_RevenueOrders>()) {
      return const ExecutiveDashboardMetric.notCalculated();
    }
    final currentRevenue =
        (current as AppSuccess<_RevenueOrders>).value.revenueNet;
    final comparisonRevenue =
        (comparison as AppSuccess<_RevenueOrders>).value.revenueNet;
    if (comparisonRevenue == 0) {
      return const ExecutiveDashboardMetric.notCalculated();
    }
    return ExecutiveDashboardMetric.available(
      value: ((currentRevenue - comparisonRevenue) / comparisonRevenue) * 100,
    );
  }

  ExecutiveDashboardMetric _positivacaoMetric({
    required AppResult<PositivacaoSnapshot> current,
    required AppResult<PositivacaoSnapshot> previous,
    required double Function(PositivacaoSnapshot) valueOf,
  }) {
    if (current case AppFailure<PositivacaoSnapshot>(failure: final failure)) {
      return ExecutiveDashboardMetric.failed(failure.message);
    }
    final currentSnapshot = (current as AppSuccess<PositivacaoSnapshot>).value;
    if (!currentSnapshot.isCalculated) {
      return const ExecutiveDashboardMetric.notCalculated();
    }
    final previousValue = switch (previous) {
      AppSuccess<PositivacaoSnapshot>(value: final value) =>
        value.isCalculated ? valueOf(value) : null,
      AppFailure<PositivacaoSnapshot>() => null,
    };
    return ExecutiveDashboardMetric.available(
      value: valueOf(currentSnapshot),
      previousValue: previousValue,
    );
  }

  Future<ExecutiveDashboardMetric> _targetAchievement({
    required String organizationId,
    required String companyId,
    required TargetDimensionType dimensionType,
    required String dimensionId,
    required ExecutiveDashboardFilters filters,
  }) async {
    final targetsResult = await _targetRepository.listByDimension(
      organizationId: organizationId,
      companyId: companyId,
      dimensionType: dimensionType,
      dimensionId: dimensionId,
      metricType: TargetMetricType.revenue,
    );
    if (targetsResult case AppFailure<List<Target>>(failure: final failure)) {
      return ExecutiveDashboardMetric.failed(failure.message);
    }
    final targets =
        (targetsResult as AppSuccess<List<Target>>).value
            .where(
              (target) =>
                  target.deletedAt == null &&
                  targetPeriodsOverlap(
                    aStart: target.startDate,
                    aEnd: target.endDate,
                    bStart: filters.periodStart,
                    bEnd: filters.periodEnd,
                  ),
            )
            .toList(growable: false)
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
    if (targets.isEmpty) {
      return const ExecutiveDashboardMetric.notCalculated();
    }
    final target = targets.first;

    final achievementResult = await _targetAchievementRepository.getForTarget(
      organizationId: organizationId,
      targetId: target.id,
    );
    if (achievementResult case AppFailure<TargetAchievementSnapshot>(
      failure: final failure,
    )) {
      return ExecutiveDashboardMetric.failed(failure.message);
    }
    final snapshot =
        (achievementResult as AppSuccess<TargetAchievementSnapshot>).value;
    if (!snapshot.isCalculated) {
      return const ExecutiveDashboardMetric.notCalculated();
    }

    final progress = TargetProgressViewModel.compute(
      target: target,
      realizedValue: snapshot.realizedValue!,
      calculatedAt: snapshot.calculatedAt,
      now: DateTime.now().toUtc(),
    );
    return ExecutiveDashboardMetric.available(
      value: progress.achievementPercentage,
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

final class _RevenueOrders {
  const _RevenueOrders({required this.revenueNet, required this.orderCount});

  final double revenueNet;
  final int orderCount;
}
