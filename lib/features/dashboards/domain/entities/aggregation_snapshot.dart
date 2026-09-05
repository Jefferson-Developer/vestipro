import '../value_objects/aggregation_dimension.dart';

/// One pre-computed server-side snapshot (TASK-133) — a single row of
/// revenue/order-count/quantity already aggregated by [dimension], read
/// directly by a dashboard instead of it ever summing raw orders itself.
///
/// Mirrors `AggregateSnapshotDoc` in
/// `functions/src/aggregations/aggregation-shared.ts`, the shape every
/// Cloud Function in `functions/src/aggregations` actually writes.
final class AggregationSnapshot {
  const AggregationSnapshot({
    required this.organizationId,
    required this.companyId,
    required this.dimension,
    required this.scopeId,
    required this.periodKey,
    required this.revenueGross,
    required this.revenueNet,
    required this.discountAmount,
    required this.orderCount,
    required this.itemQuantity,
    required this.labels,
    required this.generatedAt,
    required this.version,
    this.isFromLocalCache = false,
  });

  final String organizationId;
  final String companyId;
  final AggregationDimension dimension;

  /// `companyId` itself for [AggregationDimension.salesDaily] (company-wide,
  /// no sub-scope); customerId/productId/sellerId/region (delivery address
  /// state) for the other four.
  final String scopeId;

  /// `YYYY-MM-DD` for [AggregationDimension.salesDaily], `YYYY-MM` for every
  /// monthly dimension.
  final String periodKey;

  final double revenueGross;
  final double revenueNet;
  final double discountAmount;
  final int orderCount;
  final int itemQuantity;

  /// Denormalized display fields (`customerName`, `sellerName`,
  /// `productName`, `categoryId`, `categoryName`, `collectionId`,
  /// `collectionName`, `segment`, `region`...) so a dashboard never has to
  /// re-fetch the source entity just to render a label.
  final Map<String, String> labels;

  final DateTime generatedAt;
  final int version;

  /// Whether this value was recovered from the durable last-known snapshot
  /// after a remote read failed (for example while the seller is offline).
  final bool isFromLocalCache;

  AggregationSnapshot copyWith({bool? isFromLocalCache}) {
    return AggregationSnapshot(
      organizationId: organizationId,
      companyId: companyId,
      dimension: dimension,
      scopeId: scopeId,
      periodKey: periodKey,
      revenueGross: revenueGross,
      revenueNet: revenueNet,
      discountAmount: discountAmount,
      orderCount: orderCount,
      itemQuantity: itemQuantity,
      labels: labels,
      generatedAt: generatedAt,
      version: version,
      isFromLocalCache: isFromLocalCache ?? this.isFromLocalCache,
    );
  }
}
