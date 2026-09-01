import '../entities/positivacao_snapshot.dart';
import '../value_objects/positivacao_dimension_type.dart';
import '../value_objects/positivacao_settings.dart';

/// A raw order signal `PositivacaoCalculationService` needs: just enough of
/// an `Order` to decide whether it makes its `customerId` "positivado" —
/// never the full `Order` aggregate, so this stays decoupled from the
/// `orders` feature.
final class PositivacaoOrderSignal {
  const PositivacaoOrderSignal({
    required this.customerId,
    required this.statusCode,
    required this.orderTotal,
    required this.orderDate,
  });

  final String customerId;

  /// Raw `OrderStatus.name` (e.g. `'approved'`, `'draft'`).
  final String statusCode;
  final double orderTotal;
  final DateTime orderDate;
}

/// Formula v1 — **the future Cloud Function's source of truth** (same
/// "daily Cloud Function source of truth" precedent as
/// `CustomerScoringService`): a customer counts as positivado in a period
/// when at least one of their orders has an eligible [PositivacaoSettings]
/// status, meets the configured minimum value and falls inside
/// `[periodStart, periodEnd)`.
///
/// Pure: never reads `DateTime.now()`/a repository itself — every input is
/// caller-supplied, so this is trivially unit-testable and directly portable
/// to the TS Cloud Function this task documents as a pending follow-up (see
/// `docs/tasks/TASK-117-implementar-positivacao-de-carteira-CONCLUIDA.md`).
final class PositivacaoCalculationService {
  const PositivacaoCalculationService();

  PositivacaoSnapshot calculate({
    required String organizationId,
    required String companyId,
    required PositivacaoDimensionType dimensionType,
    required String dimensionId,
    required Set<String> portfolioCustomerIds,
    required List<PositivacaoOrderSignal> orders,
    required PositivacaoSettings settings,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime calculatedAt,
  }) {
    final eligibleOrdersByCustomer = <String, List<PositivacaoOrderSignal>>{};
    for (final order in orders) {
      if (!portfolioCustomerIds.contains(order.customerId)) continue;
      if (!settings.isEligibleStatus(order.statusCode)) continue;
      if (!settings.meetsMinimumValue(order.orderTotal)) continue;
      if (order.orderDate.isBefore(periodStart)) continue;
      if (!order.orderDate.isBefore(periodEnd)) continue;
      (eligibleOrdersByCustomer[order.customerId] ??=
              <PositivacaoOrderSignal>[])
          .add(order);
    }

    final positivatedCustomerIds = portfolioCustomerIds
        .where((customerId) => eligibleOrdersByCustomer.containsKey(customerId))
        .toSet();
    final nonPositivatedCustomerIds =
        portfolioCustomerIds.difference(positivatedCustomerIds).toList()
          ..sort();

    return PositivacaoSnapshot(
      organizationId: organizationId,
      companyId: companyId,
      dimensionType: dimensionType,
      dimensionId: dimensionId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalPortfolio: portfolioCustomerIds.length,
      positivatedCount: positivatedCustomerIds.length,
      nonPositivatedCustomerIds: nonPositivatedCustomerIds,
      calculatedAt: calculatedAt,
    );
  }
}
