import 'package:injectable/injectable.dart';

import '../entities/executive_dashboard_metric.dart';
import '../entities/product_dashboard_ranking_row.dart';
import '../entities/product_dashboard_snapshot.dart';

/// Assembles the Product Dashboard's KPI cards (TASK-137, seção 12.2 de
/// `tasks.md`) as a pure, synchronous fold over the exact same
/// `List<ProductDashboardRankingRow>` `LoadProductDashboardRankingUseCase`
/// already fetched for the ranking table (TASK-133's `productMonthly`,
/// already price-list-restricted and coleção/categoria-filtered) — never a
/// second read, and never a KPI total that could disagree with what the
/// ranking table itself shows for the same filtered scope.
@injectable
final class BuildProductDashboardSnapshotUseCase {
  const BuildProductDashboardSnapshotUseCase();

  ProductDashboardSnapshot call(List<ProductDashboardRankingRow> rows) {
    if (rows.isEmpty) {
      return const ProductDashboardSnapshot(
        quantitySold: ExecutiveDashboardMetric.available(value: 0),
        activeProductCount: ExecutiveDashboardMetric.available(value: 0),
        averageDiscountPercentage: ExecutiveDashboardMetric.available(value: 0),
        margin: ExecutiveDashboardMetric.notCalculated(),
      );
    }

    final totalQuantity = rows.fold<int>(
      0,
      (sum, row) => sum + row.quantitySold,
    );
    final totalRevenueGross = rows.fold<double>(
      0,
      (sum, row) => sum + row.revenueGross,
    );
    final totalDiscount = rows.fold<double>(
      0,
      (sum, row) => sum + row.discountAmount,
    );
    final activeProductCount = rows.where((row) => row.quantitySold > 0).length;
    final averageDiscountPercentage = totalRevenueGross == 0
        ? 0.0
        : (totalDiscount / totalRevenueGross) * 100;

    return ProductDashboardSnapshot(
      quantitySold: ExecutiveDashboardMetric.available(
        value: totalQuantity.toDouble(),
      ),
      activeProductCount: ExecutiveDashboardMetric.available(
        value: activeProductCount.toDouble(),
      ),
      averageDiscountPercentage: ExecutiveDashboardMetric.available(
        value: averageDiscountPercentage,
      ),
      margin: const ExecutiveDashboardMetric.notCalculated(),
    );
  }
}
