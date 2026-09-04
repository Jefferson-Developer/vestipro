import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

void main() {
  const useCase = BuildProductDashboardSnapshotUseCase();

  ProductDashboardRankingRow row({
    required String productId,
    required int quantitySold,
    required double revenueGross,
    required double discountAmount,
  }) {
    return ProductDashboardRankingRow(
      productId: productId,
      productName: productId,
      quantitySold: quantitySold,
      revenueGross: revenueGross,
      revenueNet: revenueGross - discountAmount,
      discountAmount: discountAmount,
      orderCount: 1,
      mixPercentage: 0,
    );
  }

  test('returns zeroed KPIs (never notCalculated) for an empty period', () {
    final snapshot = useCase(const <ProductDashboardRankingRow>[]);
    expect(snapshot.quantitySold.value, 0);
    expect(snapshot.activeProductCount.value, 0);
    expect(snapshot.averageDiscountPercentage.value, 0);
  });

  test('margin is always notCalculated (no cost data exists anywhere)', () {
    final snapshot = useCase(const <ProductDashboardRankingRow>[]);
    expect(
      snapshot.margin.status,
      ExecutiveDashboardMetricStatus.notCalculated,
    );
  });

  test('sums quantitySold across every row', () {
    final snapshot = useCase(<ProductDashboardRankingRow>[
      row(
        productId: 'a',
        quantitySold: 10,
        revenueGross: 100,
        discountAmount: 0,
      ),
      row(productId: 'b', quantitySold: 5, revenueGross: 50, discountAmount: 0),
    ]);
    expect(snapshot.quantitySold.value, 15);
  });

  test('activeProductCount only counts rows with quantitySold > 0', () {
    final snapshot = useCase(<ProductDashboardRankingRow>[
      row(
        productId: 'a',
        quantitySold: 10,
        revenueGross: 100,
        discountAmount: 0,
      ),
      row(productId: 'b', quantitySold: 0, revenueGross: 0, discountAmount: 0),
    ]);
    expect(snapshot.activeProductCount.value, 1);
  });

  test('averageDiscountPercentage is weighted by revenueGross, never a simple '
      'average of each row\'s own discount percentage', () {
    final snapshot = useCase(<ProductDashboardRankingRow>[
      // 50% discount on a small-revenue row.
      row(productId: 'a', quantitySold: 1, revenueGross: 10, discountAmount: 5),
      // 0% discount on a much larger-revenue row.
      row(
        productId: 'b',
        quantitySold: 1,
        revenueGross: 990,
        discountAmount: 0,
      ),
    ]);
    // A naive arithmetic mean of (50%, 0%) would be 25% — the weighted
    // total is 5 / 1000 = 0.5%.
    expect(snapshot.averageDiscountPercentage.value, closeTo(0.5, 0.001));
  });

  test('averageDiscountPercentage is 0 when total revenueGross is 0', () {
    final snapshot = useCase(<ProductDashboardRankingRow>[
      row(productId: 'a', quantitySold: 0, revenueGross: 0, discountAmount: 0),
    ]);
    expect(snapshot.averageDiscountPercentage.value, 0);
  });
}
