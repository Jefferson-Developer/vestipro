/// The metric a [Target] (meta comercial) measures.
///
/// Deliberately not exhaustive of every metric the business may ever want to
/// track: `TargetsTable`/`TargetDto` store the raw string code (see
/// `TargetMapper`), so a future metric only needs a new value here plus a new
/// `TargetMapper` switch case — never a schema change. Today's known set
/// covers `VESTI-085`/`VESTI-087`: revenue and quantity targets, plus
/// "positivação" (share of the portfolio that bought in the period,
/// `VESTI-087`).
enum TargetMetricType { revenue, quantity, positivacao }
