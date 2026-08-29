import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/inventory/inventory.dart';

void main() {
  group('GetStockTurnoverMetricsUseCase', () {
    test(
      'returns a snapshot consumable by dashboard and insight clients',
      () async {
        final repository = _FakeStockTurnoverRepository(
          StockTurnoverMetricSnapshot(
            organizationId: 'org-1',
            scopeType: StockTurnoverScopeType.product,
            scopeId: 'product-1',
            periodStart: DateTime.utc(2026, 8, 1),
            periodEnd: DateTime.utc(2026, 8, 30),
            coveredDays: 30,
            sellThroughRate: 0.42,
            stockCoverageDays: 9.5,
            turnoverRate: 1.3,
            openingStockQuantity: 100,
            receivedQuantity: 20,
            soldQuantity: 50,
            closingStockQuantity: 70,
            averageStockQuantity: 38.5,
            averageDailySalesQuantity: 1.6667,
            coverageStatus: StockCoverageStatus.ready,
            generatedAt: DateTime.utc(2026, 8, 31),
          ),
        );
        final useCase = GetStockTurnoverMetricsUseCase(repository);

        final result = await useCase(
          organizationId: 'org-1',
          scope: const StockTurnoverMetricScope(
            type: StockTurnoverScopeType.product,
            id: 'product-1',
          ),
          periodStart: DateTime.utc(2026, 8, 1),
          periodEnd: DateTime.utc(2026, 8, 30),
        );

        expect(result, isA<AppSuccess<StockTurnoverMetricSnapshot?>>());
        final snapshot =
            (result as AppSuccess<StockTurnoverMetricSnapshot?>).value!;

        final dashboardCard = _FakeInventoryDashboardConsumer().consume(
          snapshot,
        );
        final insightInput = _FakeStockInsightConsumer().consume(snapshot);

        expect(dashboardCard, 'product:product-1 sell-through 0.42 giro 1.30');
        expect(insightInput, 'ready coverage 9.5 days sold 50');
      },
    );
  });
}

final class _FakeStockTurnoverRepository implements StockTurnoverRepository {
  const _FakeStockTurnoverRepository(this.snapshot);

  final StockTurnoverMetricSnapshot? snapshot;

  @override
  Future<AppResult<StockTurnoverMetricSnapshot?>> getByScopeAndPeriod({
    required String organizationId,
    required StockTurnoverMetricScope scope,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    return AppSuccess<StockTurnoverMetricSnapshot?>(snapshot);
  }
}

final class _FakeInventoryDashboardConsumer {
  String consume(StockTurnoverMetricSnapshot snapshot) {
    return '${snapshot.scopeType.code}:${snapshot.scopeId} sell-through '
        '${snapshot.sellThroughRate.toStringAsFixed(2)} giro '
        '${snapshot.turnoverRate.toStringAsFixed(2)}';
  }
}

final class _FakeStockInsightConsumer {
  String consume(StockTurnoverMetricSnapshot snapshot) {
    return '${snapshot.coverageStatus.code} coverage '
        '${snapshot.stockCoverageDays.toStringAsFixed(1)} days sold '
        '${snapshot.soldQuantity}';
  }
}
