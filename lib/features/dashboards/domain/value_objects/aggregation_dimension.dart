/// The server-side aggregation dimensions available to EPIC-17 — the
/// original five from TASK-133 plus TASK-140's privacy-scoped seller views —
/// every dashboard in EPIC-17 (TASK-134 a TASK-143) reads one of these
/// instead of querying raw `orders`/`customers`/`products` collections
/// directly (`tasks.md`, seção 22: "Dashboards complexos não devem executar
/// centenas de consultas do cliente").
///
/// Mirrors `AggregationDimension` in
/// `functions/src/aggregations/aggregation-shared.ts` — kept in sync
/// manually, same trade-off already accepted for other client/Functions
/// enum pairs in this codebase (e.g. `OrderStatus`).
enum AggregationDimension {
  /// Revenue/order-count by day, scoped to a company (`scopeId` is the
  /// `companyId` itself — no further sub-scope). Recomputed near-real-time,
  /// on every order write.
  salesDaily,

  /// Revenue/order-count by seller and day. Recomputed near-real-time and
  /// readable by that seller (or an authorized manager) for the field home.
  sellerDaily,

  /// Privacy-scoped copy of the monthly seller aggregate used by the field
  /// dashboard. Kept separate because the management sales dashboard needs
  /// a bounded multi-seller list while representatives may only `get` self.
  representativeMonthly,

  /// Revenue/order-count by customer, per month. Recomputed nightly (batch).
  customerMonthly,

  /// Revenue/quantity by product, per month — carries `categoryId`/
  /// `collectionId` as denormalized [AggregationSnapshot.labels] so a
  /// dashboard can group/filter by category or collection without a second
  /// round-trip. Recomputed nightly (batch).
  productMonthly,

  /// Revenue/order-count by seller, per month. Recomputed nightly (batch).
  sellerMonthly,

  /// Revenue/order-count by region (the order's delivery address state),
  /// per month. Recomputed nightly (batch).
  regionMonthly,
}

extension AggregationDimensionCollection on AggregationDimension {
  /// The Firestore subcollection this dimension's snapshots live in, under
  /// `organizations/{organizationId}/{collectionName}/{docId}` — must match
  /// `AGGREGATE_COLLECTION_BY_DIMENSION` in
  /// `functions/src/aggregations/aggregation-shared.ts` and
  /// `firestore.rules`.
  String get collectionName => switch (this) {
    AggregationDimension.salesDaily => 'salesDailyAggregates',
    AggregationDimension.sellerDaily => 'sellerDailyAggregates',
    AggregationDimension.representativeMonthly =>
      'representativeMonthlyAggregates',
    AggregationDimension.customerMonthly => 'customerMonthlyAggregates',
    AggregationDimension.productMonthly => 'productMonthlyAggregates',
    AggregationDimension.sellerMonthly => 'sellerMonthlyAggregates',
    AggregationDimension.regionMonthly => 'regionMonthlyAggregates',
  };

  /// `true` for the one dimension recomputed near-real-time (per order
  /// write); `false` for the four recomputed only by the nightly batch —
  /// purely informational, e.g. for a dashboard to decide whether to show a
  /// "atualizado agora" vs. "atualizado até ontem à noite" freshness hint.
  bool get isNearRealTime =>
      this == AggregationDimension.salesDaily ||
      this == AggregationDimension.sellerDaily;
}
