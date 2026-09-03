import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/aggregation_snapshot.dart';
import '../entities/customer_dashboard_filters.dart';
import '../entities/customer_dashboard_ranking_row.dart';
import '../repositories/aggregation_repository.dart';
import '../value_objects/aggregation_dimension.dart';
import '../value_objects/customer_dashboard_sort_field.dart';

/// Builds the Customer Dashboard's ranking table (TASK-136, seção 12.3 de
/// `tasks.md`: "ordenação"/"filtros avançados") for one
/// [CustomerDashboardFilters], reading exclusively from TASK-133's
/// [AggregationRepository] (`customerMonthly`) — one bounded `listByPeriod`
/// read for the filtered month, never a raw `orders`/`customers` scan (this
/// task's own "nunca recalculado do zero no cliente" rule).
///
/// **Team filter, documented limitation** (same as
/// `LoadCustomerDashboardSnapshotUseCase`): `customerMonthly` carries no
/// seller/team label, so this ranking is always company-wide even when
/// [CustomerDashboardFilters.teamId] is set — narrowing it would require a
/// new aggregation dimension or a second, unbounded-shaped join against the
/// RBAC-resolved carteira. Pagination (seção 12.3: "paginação") is applied
/// entirely client-side by the caller (`CustomerDashboardBloc`) over the
/// full sorted/filtered list this use case returns — a single bounded read
/// already covers "top N clientes do mês", never a server cursor.
@injectable
final class LoadCustomerDashboardRankingUseCase {
  const LoadCustomerDashboardRankingUseCase(this._aggregationRepository);

  final AggregationRepository _aggregationRepository;

  /// Same bound `LoadCustomerDashboardSnapshotUseCase._customerMonthlyLimit`
  /// already uses for the exact same dimension/period.
  static const int _rowLimit = 1000;

  Future<AppResult<List<CustomerDashboardRankingRow>>> call({
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
      return AppFailure<List<CustomerDashboardRankingRow>>(
        ValidationFailure(
          'Invalid customer dashboard ranking payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_customer_dashboard_ranking_payload',
        ),
      );
    }

    final result = await _aggregationRepository.listByPeriod(
      organizationId: trimmedOrganizationId,
      dimension: AggregationDimension.customerMonthly,
      companyId: trimmedCompanyId,
      periodKey: filters.monthKey,
      limit: _rowLimit,
    );
    if (result case AppFailure<List<AggregationSnapshot>>(
      failure: final failure,
    )) {
      return AppFailure<List<CustomerDashboardRankingRow>>(failure);
    }
    final snapshots = (result as AppSuccess<List<AggregationSnapshot>>).value;

    final normalizedSegment = filters.segment?.trim().toLowerCase();
    final rows = <CustomerDashboardRankingRow>[
      for (final snapshot in snapshots)
        if (normalizedSegment == null ||
            normalizedSegment.isEmpty ||
            snapshot.labels['segment']?.trim().toLowerCase() ==
                normalizedSegment)
          CustomerDashboardRankingRow(
            customerId: snapshot.scopeId,
            customerName:
                snapshot.labels['customerName']?.trim().isNotEmpty == true
                ? snapshot.labels['customerName']!.trim()
                : snapshot.scopeId,
            segment: snapshot.labels['segment']?.trim().isNotEmpty == true
                ? snapshot.labels['segment']!.trim()
                : null,
            revenueGross: snapshot.revenueGross,
            revenueNet: snapshot.revenueNet,
            orderCount: snapshot.orderCount,
            itemQuantity: snapshot.itemQuantity,
          ),
    ];

    return AppSuccess<List<CustomerDashboardRankingRow>>(
      _sort(rows, field: filters.sortField, descending: filters.sortDescending),
    );
  }

  List<CustomerDashboardRankingRow> _sort(
    List<CustomerDashboardRankingRow> rows, {
    required CustomerDashboardSortField field,
    required bool descending,
  }) {
    final sorted = List<CustomerDashboardRankingRow>.of(rows)
      ..sort((a, b) {
        final comparison = switch (field) {
          CustomerDashboardSortField.revenue => a.revenueNet.compareTo(
            b.revenueNet,
          ),
          CustomerDashboardSortField.frequency => a.orderCount.compareTo(
            b.orderCount,
          ),
          CustomerDashboardSortField.averageTicket => a.averageTicket.compareTo(
            b.averageTicket,
          ),
        };
        return descending ? -comparison : comparison;
      });
    return sorted;
  }
}
