/// The three levels an `npsMonthlyAggregates` snapshot is computed for
/// (TASK-202, EPIC-30, `tasks.md`: "por vendedor, equipe e organização") —
/// mirrors `NpsAggregateScope` in
/// `functions/src/nps/nps-shared.ts`/`recompute-nps-monthly-aggregates.ts`,
/// kept in sync manually (same trade-off already accepted for other
/// client/Functions enum pairs in this codebase, e.g.
/// `AggregationDimension`).
enum NpsAggregateScope { seller, team, organization }

extension NpsAggregateScopeCode on NpsAggregateScope {
  String get code => switch (this) {
    NpsAggregateScope.seller => 'seller',
    NpsAggregateScope.team => 'team',
    NpsAggregateScope.organization => 'organization',
  };
}
