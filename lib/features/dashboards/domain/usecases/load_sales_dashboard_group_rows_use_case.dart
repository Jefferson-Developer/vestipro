import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/aggregation_snapshot.dart';
import '../entities/sales_dashboard_filters.dart';
import '../entities/sales_dashboard_group_row.dart';
import '../repositories/aggregation_repository.dart';
import '../value_objects/sales_dashboard_group_dimension.dart';
import '../value_objects/sales_dashboard_sort_field.dart';

const String _uncategorizedScopeId = 'uncategorized';
const String _uncategorizedLabel = 'Sem categoria';

/// Builds the Sales Dashboard's drill-down table (TASK-135, seção 12.3 de
/// `tasks.md`: "agrupamento"/"ordenação"/"comparação de período") for one
/// [SalesDashboardFilters.groupDimension], reading exclusively from
/// TASK-133's [AggregationRepository] — one bounded `listByPeriod` read for
/// the current period, one more for [SalesDashboardFilters
/// .comparisonPeriod], never a raw `orders`/`customers`/`products` scan (this
/// task's own "Regras de negócio e restrições": "nunca uma varredura
/// completa de coleção no cliente").
///
/// [SalesDashboardGroupDimension.category] re-aggregates the already-fetched,
/// already-bounded `productMonthly` rows by their denormalized
/// `labels['categoryId']` — a client-side fold over data already in memory,
/// never a second server round-trip nor a raw scan (see
/// [SalesDashboardGroupDimensionMapping.aggregationDimension]'s own docs).
@injectable
final class LoadSalesDashboardGroupRowsUseCase {
  const LoadSalesDashboardGroupRowsUseCase(this._aggregationRepository);

  final AggregationRepository _aggregationRepository;

  /// Same bound `AggregationRepository.listByPeriod`'s own default caps a
  /// single dashboard read at — enough for a "top N vendedores/clientes/
  /// produtos do mês" table, never a full historical scan.
  static const int _rowLimit = 200;

  Future<AppResult<List<SalesDashboardGroupRow>>> call({
    required String organizationId,
    required SalesDashboardFilters filters,

    /// RBAC narrowing already resolved by the caller (`SalesDashboardBloc`,
    /// from `ExecutiveDashboardVisibilityService`'s team-member resolution):
    /// only meaningful when [SalesDashboardFilters.groupDimension] is
    /// [SalesDashboardGroupDimension.seller] and a team filter is active —
    /// `null` means "no narrowing" (whole company), an empty list means "the
    /// filtered team has no resolvable member" (renders zero rows, never
    /// falls back to the whole company).
    Set<String>? sellerScopeIds,
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
      return AppFailure<List<SalesDashboardGroupRow>>(
        ValidationFailure(
          'Invalid sales dashboard group rows payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_sales_dashboard_group_rows_payload',
        ),
      );
    }

    if (sellerScopeIds != null &&
        sellerScopeIds.isEmpty &&
        filters.groupDimension == SalesDashboardGroupDimension.seller) {
      return const AppSuccess<List<SalesDashboardGroupRow>>(
        <SalesDashboardGroupRow>[],
      );
    }

    final currentResult = await _aggregationRepository.listByPeriod(
      organizationId: trimmedOrganizationId,
      dimension: filters.groupDimension.aggregationDimension,
      companyId: trimmedCompanyId,
      periodKey: filters.monthKey,
      limit: _rowLimit,
    );
    if (currentResult case AppFailure<List<AggregationSnapshot>>(
      failure: final failure,
    )) {
      return AppFailure<List<SalesDashboardGroupRow>>(failure);
    }
    final currentSnapshots = _restrictToSellers(
      (currentResult as AppSuccess<List<AggregationSnapshot>>).value,
      dimension: filters.groupDimension,
      sellerScopeIds: sellerScopeIds,
    );

    final comparisonPeriod = filters.comparisonPeriod;
    final comparisonResult = await _aggregationRepository.listByPeriod(
      organizationId: trimmedOrganizationId,
      dimension: filters.groupDimension.aggregationDimension,
      companyId: trimmedCompanyId,
      periodKey: comparisonPeriod.monthKey,
      limit: _rowLimit,
    );
    // Best-effort: a failed comparison read never blocks the current
    // period's rows — every row simply renders with no "Crescimento" value
    // (`SalesDashboardGroupRow.changePercentage` already treats a missing
    // comparison as "sem comparação", never as a failure of its own).
    final comparisonSnapshots = switch (comparisonResult) {
      AppSuccess<List<AggregationSnapshot>>(value: final value) =>
        _restrictToSellers(
          value,
          dimension: filters.groupDimension,
          sellerScopeIds: sellerScopeIds,
        ),
      AppFailure<List<AggregationSnapshot>>() => const <AggregationSnapshot>[],
    };

    final rows = filters.groupDimension == SalesDashboardGroupDimension.category
        ? _groupByCategory(
            current: currentSnapshots,
            previous: comparisonSnapshots,
          )
        : _groupByScope(
            current: currentSnapshots,
            previous: comparisonSnapshots,
          );

    final sorted = _sort(
      rows,
      field: filters.sortField,
      descending: filters.sortDescending,
    );
    return AppSuccess<List<SalesDashboardGroupRow>>(sorted);
  }

  List<AggregationSnapshot> _restrictToSellers(
    List<AggregationSnapshot> snapshots, {
    required SalesDashboardGroupDimension dimension,
    required Set<String>? sellerScopeIds,
  }) {
    if (sellerScopeIds == null ||
        dimension != SalesDashboardGroupDimension.seller) {
      return snapshots;
    }
    return snapshots
        .where((snapshot) => sellerScopeIds.contains(snapshot.scopeId))
        .toList(growable: false);
  }

  List<SalesDashboardGroupRow> _groupByScope({
    required List<AggregationSnapshot> current,
    required List<AggregationSnapshot> previous,
  }) {
    final previousByScopeId = <String, double>{
      for (final snapshot in previous) snapshot.scopeId: snapshot.revenueNet,
    };
    return <SalesDashboardGroupRow>[
      for (final snapshot in current)
        SalesDashboardGroupRow(
          scopeId: snapshot.scopeId,
          label: _labelOf(snapshot) ?? snapshot.scopeId,
          revenueNet: snapshot.revenueNet,
          orderCount: snapshot.orderCount,
          itemQuantity: snapshot.itemQuantity,
          discountAmount: snapshot.discountAmount,
          previousRevenueNet: previousByScopeId[snapshot.scopeId],
        ),
    ];
  }

  List<SalesDashboardGroupRow> _groupByCategory({
    required List<AggregationSnapshot> current,
    required List<AggregationSnapshot> previous,
  }) {
    final previousByCategoryId = <String, double>{};
    for (final snapshot in previous) {
      final categoryId = _categoryIdOf(snapshot);
      previousByCategoryId[categoryId] =
          (previousByCategoryId[categoryId] ?? 0) + snapshot.revenueNet;
    }

    final revenueByCategory = <String, double>{};
    final discountByCategory = <String, double>{};
    final orderCountByCategory = <String, int>{};
    final itemQuantityByCategory = <String, int>{};
    final labelByCategory = <String, String>{};

    for (final snapshot in current) {
      final categoryId = _categoryIdOf(snapshot);
      revenueByCategory[categoryId] =
          (revenueByCategory[categoryId] ?? 0) + snapshot.revenueNet;
      discountByCategory[categoryId] =
          (discountByCategory[categoryId] ?? 0) + snapshot.discountAmount;
      orderCountByCategory[categoryId] =
          (orderCountByCategory[categoryId] ?? 0) + snapshot.orderCount;
      itemQuantityByCategory[categoryId] =
          (itemQuantityByCategory[categoryId] ?? 0) + snapshot.itemQuantity;
      labelByCategory.putIfAbsent(
        categoryId,
        () => snapshot.labels['categoryName']?.trim().isNotEmpty == true
            ? snapshot.labels['categoryName']!.trim()
            : (categoryId == _uncategorizedScopeId
                  ? _uncategorizedLabel
                  : categoryId),
      );
    }

    return <SalesDashboardGroupRow>[
      for (final categoryId in revenueByCategory.keys)
        SalesDashboardGroupRow(
          scopeId: categoryId,
          label: labelByCategory[categoryId] ?? categoryId,
          revenueNet: revenueByCategory[categoryId]!,
          orderCount: orderCountByCategory[categoryId] ?? 0,
          itemQuantity: itemQuantityByCategory[categoryId] ?? 0,
          discountAmount: discountByCategory[categoryId] ?? 0,
          previousRevenueNet: previousByCategoryId[categoryId],
        ),
    ];
  }

  String _categoryIdOf(AggregationSnapshot snapshot) {
    final categoryId = snapshot.labels['categoryId']?.trim();
    return (categoryId == null || categoryId.isEmpty)
        ? _uncategorizedScopeId
        : categoryId;
  }

  String? _labelOf(AggregationSnapshot snapshot) {
    for (final key in const <String>[
      'sellerName',
      'customerName',
      'productName',
    ]) {
      final value = snapshot.labels[key]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  List<SalesDashboardGroupRow> _sort(
    List<SalesDashboardGroupRow> rows, {
    required SalesDashboardSortField field,
    required bool descending,
  }) {
    final sorted = List<SalesDashboardGroupRow>.of(rows)
      ..sort((a, b) {
        final comparison = switch (field) {
          SalesDashboardSortField.revenue => a.revenueNet.compareTo(
            b.revenueNet,
          ),
          SalesDashboardSortField.orders => a.orderCount.compareTo(
            b.orderCount,
          ),
          SalesDashboardSortField.quantity => a.itemQuantity.compareTo(
            b.itemQuantity,
          ),
          SalesDashboardSortField.label => a.label.toLowerCase().compareTo(
            b.label.toLowerCase(),
          ),
        };
        return descending ? -comparison : comparison;
      });
    return sorted;
  }
}
