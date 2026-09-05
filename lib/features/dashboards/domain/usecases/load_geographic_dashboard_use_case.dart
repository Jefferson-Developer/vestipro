import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/aggregation_snapshot.dart';
import '../entities/executive_dashboard_visibility_filter.dart';
import '../entities/geographic_dashboard_filters.dart';
import '../entities/geographic_dashboard_snapshot.dart';
import '../repositories/aggregation_repository.dart';
import '../services/executive_dashboard_visibility_service.dart';
import '../value_objects/aggregation_dimension.dart';

@injectable
class LoadGeographicDashboardUseCase {
  const LoadGeographicDashboardUseCase(this._repository, this._visibility);

  final AggregationRepository _repository;
  final ExecutiveDashboardVisibilityService _visibility;

  Future<AppResult<GeographicDashboardSnapshot>> call({
    required String organizationId,
    required String userId,
    required GeographicDashboardFilters filters,
  }) async {
    final visibilityResult = await _visibility.resolve(
      organizationId: organizationId,
      userId: userId,
    );
    if (visibilityResult case AppFailure<ExecutiveDashboardVisibilityFilter>(
      failure: final failure,
    )) {
      return AppFailure<GeographicDashboardSnapshot>(failure);
    }
    final visibility =
        (visibilityResult as AppSuccess<ExecutiveDashboardVisibilityFilter>)
            .value;
    if (!visibility.canViewAny ||
        !visibility.canViewCompany(filters.companyId)) {
      return const AppFailure<GeographicDashboardSnapshot>(
        PermissionFailure(
          'Escopo geográfico fora da sua responsabilidade.',
          code: 'geographic_dashboard_scope_forbidden',
        ),
      );
    }

    final result = await _repository.listByPeriod(
      organizationId: organizationId,
      dimension: AggregationDimension.regionMonthly,
      companyId: filters.companyId,
      periodKey: filters.monthKey,
      limit: 500,
    );
    if (result case AppFailure<List<AggregationSnapshot>>(
      failure: final failure,
    )) {
      return AppFailure<GeographicDashboardSnapshot>(failure);
    }
    final snapshots = (result as AppSuccess<List<AggregationSnapshot>>).value;
    return AppSuccess<GeographicDashboardSnapshot>(_build(snapshots));
  }

  GeographicDashboardSnapshot _build(List<AggregationSnapshot> snapshots) {
    final citiesByState = <String, Map<String, List<AggregationSnapshot>>>{};
    for (final item in snapshots) {
      final state =
          (item.labels['state'] ?? item.labels['region'] ?? item.scopeId)
              .trim()
              .toUpperCase();
      final city = (item.labels['city'] ?? 'Sem cidade informada').trim();
      (citiesByState[state] ??= <String, List<AggregationSnapshot>>{})
          .putIfAbsent(city, () => <AggregationSnapshot>[])
          .add(item);
    }
    final statesByRegion = <String, List<GeographicDashboardRow>>{};
    for (final stateEntry in citiesByState.entries) {
      final cityRows =
          stateEntry.value.entries
              .map(
                (entry) => _row(
                  id: '${stateEntry.key}:${entry.key}',
                  label: entry.key,
                  level: GeographicDashboardLevel.city,
                  snapshots: entry.value,
                ),
              )
              .toList()
            ..sort((a, b) => b.revenue.compareTo(a.revenue));
      final stateRow = _merge(
        id: stateEntry.key,
        label: stateEntry.key,
        level: GeographicDashboardLevel.state,
        children: cityRows,
      );
      (statesByRegion[_brazilRegion(stateEntry.key)] ??=
              <GeographicDashboardRow>[])
          .add(stateRow);
    }
    final regions = statesByRegion.entries.map((entry) {
      entry.value.sort((a, b) => b.revenue.compareTo(a.revenue));
      return _merge(
        id: entry.key.toLowerCase().replaceAll(' ', '-'),
        label: entry.key,
        level: GeographicDashboardLevel.region,
        children: entry.value,
      );
    }).toList()..sort((a, b) => b.revenue.compareTo(a.revenue));
    final dates = snapshots.map((item) => item.generatedAt).toList()..sort();
    return GeographicDashboardSnapshot(
      regions: regions,
      generatedAt: dates.isEmpty ? null : dates.last,
      isFromLocalCache: snapshots.any((item) => item.isFromLocalCache),
    );
  }

  GeographicDashboardRow _row({
    required String id,
    required String label,
    required GeographicDashboardLevel level,
    required List<AggregationSnapshot> snapshots,
  }) {
    final customers = snapshots
        .expand((item) => _csv(item.labels['customerIds']))
        .toSet();
    final orders = snapshots
        .expand((item) => _csv(item.labels['orderIds']))
        .toSet();
    final products = <String, int>{};
    for (final item in snapshots) {
      for (final part in (item.labels['topProducts'] ?? '').split('|')) {
        final separator = part.lastIndexOf(':');
        if (separator <= 0) continue;
        final name = part.substring(0, separator);
        products[name] =
            (products[name] ?? 0) +
            (int.tryParse(part.substring(separator + 1)) ?? 0);
      }
    }
    final top =
        products.entries
            .map(
              (entry) => GeographicProductHighlight(
                name: entry.key,
                quantity: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.quantity.compareTo(a.quantity));
    final first = snapshots.first;
    return GeographicDashboardRow(
      id: id,
      label: label,
      level: level,
      revenue: snapshots.fold(0, (sum, item) => sum + item.revenueNet),
      orderCount: snapshots.fold(0, (sum, item) => sum + item.orderCount),
      activeCustomerCount: customers.length,
      itemQuantity: snapshots.fold(0, (sum, item) => sum + item.itemQuantity),
      topProducts: top.take(3).toList(growable: false),
      customerIds: customers.toList(growable: false),
      orderIds: orders.toList(growable: false),
      latitude: double.tryParse(first.labels['latitude'] ?? ''),
      longitude: double.tryParse(first.labels['longitude'] ?? ''),
    );
  }

  GeographicDashboardRow _merge({
    required String id,
    required String label,
    required GeographicDashboardLevel level,
    required List<GeographicDashboardRow> children,
  }) {
    final customers = children
        .expand((row) => row.customerIds)
        .toSet()
        .toList();
    final orders = children.expand((row) => row.orderIds).toSet().toList();
    final products = <String, int>{};
    for (final row in children) {
      for (final product in row.topProducts) {
        products[product.name] =
            (products[product.name] ?? 0) + product.quantity;
      }
    }
    final top =
        products.entries
            .map(
              (entry) => GeographicProductHighlight(
                name: entry.key,
                quantity: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.quantity.compareTo(a.quantity));
    return GeographicDashboardRow(
      id: id,
      label: label,
      level: level,
      revenue: children.fold(0, (sum, row) => sum + row.revenue),
      orderCount: children.fold(0, (sum, row) => sum + row.orderCount),
      activeCustomerCount: customers.length,
      itemQuantity: children.fold(0, (sum, row) => sum + row.itemQuantity),
      topProducts: top.take(3).toList(growable: false),
      customerIds: customers,
      orderIds: orders,
      children: children,
    );
  }

  Iterable<String> _csv(String? value) => (value ?? '')
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty);

  String _brazilRegion(String state) => switch (state) {
    'PR' || 'SC' || 'RS' => 'Sul',
    'SP' || 'RJ' || 'MG' || 'ES' => 'Sudeste',
    'MT' || 'MS' || 'GO' || 'DF' => 'Centro-Oeste',
    'AC' || 'AP' || 'AM' || 'PA' || 'RO' || 'RR' || 'TO' => 'Norte',
    'AL' ||
    'BA' ||
    'CE' ||
    'MA' ||
    'PB' ||
    'PE' ||
    'PI' ||
    'RN' ||
    'SE' => 'Nordeste',
    _ => 'Não informado',
  };
}
