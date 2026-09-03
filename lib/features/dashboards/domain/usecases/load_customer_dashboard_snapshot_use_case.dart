import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../targets/domain/entities/positivacao_snapshot.dart';
import '../../../targets/domain/repositories/positivacao_repository.dart';
import '../../../targets/domain/value_objects/positivacao_dimension_type.dart';
import '../entities/aggregation_snapshot.dart';
import '../entities/customer_dashboard_filters.dart';
import '../entities/customer_dashboard_snapshot.dart';
import '../entities/executive_dashboard_metric.dart';
import '../repositories/aggregation_repository.dart';
import '../value_objects/aggregation_dimension.dart';

/// Assembles every KPI the Customer Dashboard (TASK-136) renders for one
/// [CustomerDashboardFilters] scope/period, reading exclusively from
/// already-server-computed snapshot contracts — TASK-133's
/// [AggregationRepository] (`customerMonthly`) for taxa de recompra/
/// frequência média/churn, and TASK-117's [PositivacaoRepository] for
/// clientes ativos/cobertura de carteira/positivação — the exact same
/// sources `LoadExecutiveDashboardSnapshotUseCase` already uses for its own
/// equivalent KPIs, so the two dashboards never disagree on what "cliente
/// ativo" means (this task's own acceptance criterion).
///
/// **Team filter, documented limitation.** `PositivacaoDimensionType`
/// already models `team` natively (TASK-117), so [activeCustomers]/
/// [portfolioCoverage]/[positivacaoPercentage] narrow correctly when
/// [teamId][CustomerDashboardFilters] is set — same as
/// `ExecutiveDashboardSnapshot`. [repurchaseRatePercentage]/
/// [averagePurchaseFrequency]/[churnPercentage] cannot: `customerMonthly`
/// (TASK-133) carries no seller/team label at all (only `customerId` as
/// `scopeId`), so narrowing them would require either a new aggregation
/// dimension (out of this task's scope) or a client-side join against the
/// RBAC-resolved carteira (a second, unbounded-shaped read this task's own
/// "nunca recalculado do zero no cliente" rule advises against for a KPI
/// card). These three metrics are always company-wide, exactly as
/// `ExecutiveDashboardSnapshot`'s revenue trend/positivação-adjacent metrics
/// already document their own team-filter gaps.
@injectable
final class LoadCustomerDashboardSnapshotUseCase {
  const LoadCustomerDashboardSnapshotUseCase(
    this._aggregationRepository,
    this._positivacaoRepository,
  );

  final AggregationRepository _aggregationRepository;
  final PositivacaoRepository _positivacaoRepository;

  /// Bounded read cap for a single "clientes do mês" fetch — same trade-off
  /// already accepted by `LoadSalesDashboardGroupRowsUseCase._rowLimit`
  /// (200) and `LoadExecutiveDashboardSnapshotUseCase._sellerMonthlyLimit`
  /// (500), sized up slightly since a customer portfolio is typically larger
  /// than a seller roster.
  static const int _customerMonthlyLimit = 1000;

  Future<AppResult<CustomerDashboardSnapshot>> call({
    required String organizationId,
    required CustomerDashboardFilters filters,
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
      return AppFailure<CustomerDashboardSnapshot>(
        ValidationFailure(
          'Invalid customer dashboard payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_customer_dashboard_payload',
        ),
      );
    }

    final hasTeamFilter = (filters.teamId ?? '').trim().isNotEmpty;
    final portfolioDimensionType = hasTeamFilter
        ? PositivacaoDimensionType.team
        : PositivacaoDimensionType.company;
    final portfolioDimensionId = hasTeamFilter
        ? filters.teamId!.trim()
        : trimmedCompanyId;

    final previousMonthFilters = filters.previousMonth;
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
    final portfolioCoverage = _positivacaoMetric(
      current: currentPositivacao,
      previous: previousPositivacao,
      valueOf: (s) => s.totalPortfolio!.toDouble(),
    );
    final positivacaoPercentage = _positivacaoMetric(
      current: currentPositivacao,
      previous: previousPositivacao,
      valueOf: (s) => s.percentage,
    );

    final currentRowsResult = await _aggregationRepository.listByPeriod(
      organizationId: trimmedOrganizationId,
      dimension: AggregationDimension.customerMonthly,
      companyId: trimmedCompanyId,
      periodKey: filters.monthKey,
      limit: _customerMonthlyLimit,
    );
    final previousRowsResult = await _aggregationRepository.listByPeriod(
      organizationId: trimmedOrganizationId,
      dimension: AggregationDimension.customerMonthly,
      companyId: trimmedCompanyId,
      periodKey: previousMonthFilters.monthKey,
      limit: _customerMonthlyLimit,
    );

    if (currentRowsResult case AppFailure<List<AggregationSnapshot>>(
      failure: final failure,
    )) {
      final failed = ExecutiveDashboardMetric.failed(failure.message);
      return AppSuccess<CustomerDashboardSnapshot>(
        CustomerDashboardSnapshot(
          activeCustomers: activeCustomers,
          newCustomers: const ExecutiveDashboardMetric.notCalculated(),
          reactivatedCustomers: const ExecutiveDashboardMetric.notCalculated(),
          repurchaseRatePercentage: failed,
          averagePurchaseFrequency: failed,
          churnPercentage: failed,
          portfolioCoverage: portfolioCoverage,
          positivacaoPercentage: positivacaoPercentage,
        ),
      );
    }
    final currentRows =
        (currentRowsResult as AppSuccess<List<AggregationSnapshot>>).value;
    final previousRows = switch (previousRowsResult) {
      AppSuccess<List<AggregationSnapshot>>(value: final value) => value,
      AppFailure<List<AggregationSnapshot>>() => null,
    };

    final currentRates = _repurchaseAndFrequency(currentRows);
    final previousRates = previousRows == null
        ? null
        : _repurchaseAndFrequency(previousRows);

    final repurchaseRatePercentage = ExecutiveDashboardMetric.available(
      value: currentRates.repurchaseRatePercentage,
      previousValue: previousRates?.repurchaseRatePercentage,
    );
    final averagePurchaseFrequency = ExecutiveDashboardMetric.available(
      value: currentRates.averageFrequency,
      previousValue: previousRates?.averageFrequency,
    );

    final churnPercentage = previousRows == null
        ? const ExecutiveDashboardMetric.notCalculated()
        : _churnMetric(previousRows: previousRows, currentRows: currentRows);

    return AppSuccess<CustomerDashboardSnapshot>(
      CustomerDashboardSnapshot(
        activeCustomers: activeCustomers,
        // See this class's own doc comment: no aggregation/customer field
        // today distinguishes "primeira compra" ou "reativação" sem
        // escanear o histórico completo de pedidos do cliente, o que a
        // própria task proíbe — sempre "não calculado", nunca inventado.
        newCustomers: const ExecutiveDashboardMetric.notCalculated(),
        reactivatedCustomers: const ExecutiveDashboardMetric.notCalculated(),
        repurchaseRatePercentage: repurchaseRatePercentage,
        averagePurchaseFrequency: averagePurchaseFrequency,
        churnPercentage: churnPercentage,
        portfolioCoverage: portfolioCoverage,
        positivacaoPercentage: positivacaoPercentage,
      ),
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

  /// `repeatCustomers / activeCustomers` (recompra intra-período) and
  /// `soma(orderCount) / activeCustomers` (frequência média) — both derived
  /// purely from an already-fetched, already-bounded list of pre-computed
  /// `customerMonthly` snapshots, never a new read nor a raw order scan.
  _CustomerRates _repurchaseAndFrequency(List<AggregationSnapshot> rows) {
    if (rows.isEmpty) {
      return const _CustomerRates(
        repurchaseRatePercentage: 0,
        averageFrequency: 0,
      );
    }
    final totalOrders = rows.fold<int>(0, (sum, row) => sum + row.orderCount);
    final repeatCustomers = rows.where((row) => row.orderCount >= 2).length;
    return _CustomerRates(
      repurchaseRatePercentage: (repeatCustomers / rows.length) * 100,
      averageFrequency: totalOrders / rows.length,
    );
  }

  /// `clientesQueSumiram / clientesAtivosNoPeríodoAnterior * 100` — o
  /// conjunto de `scopeId` (customerId) presentes no `customerMonthly` do
  /// período anterior e ausentes no do período corrente, dividido pelo total
  /// do período anterior. Ver a divergência documentada em
  /// `CustomerDashboardSnapshot.churnPercentage`.
  ExecutiveDashboardMetric _churnMetric({
    required List<AggregationSnapshot> previousRows,
    required List<AggregationSnapshot> currentRows,
  }) {
    if (previousRows.isEmpty) {
      return const ExecutiveDashboardMetric.notCalculated();
    }
    final currentCustomerIds = <String>{
      for (final row in currentRows) row.scopeId,
    };
    final churnedCount = previousRows
        .where((row) => !currentCustomerIds.contains(row.scopeId))
        .length;
    return ExecutiveDashboardMetric.available(
      value: (churnedCount / previousRows.length) * 100,
    );
  }
}

final class _CustomerRates {
  const _CustomerRates({
    required this.repurchaseRatePercentage,
    required this.averageFrequency,
  });

  final double repurchaseRatePercentage;
  final double averageFrequency;
}
