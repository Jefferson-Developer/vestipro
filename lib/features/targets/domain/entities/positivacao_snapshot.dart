import '../value_objects/positivacao_dimension_type.dart';

/// A server-computed positivação snapshot for one carteira (TASK-117, EPIC-15/
/// VESTI-087): how many of a portfolio's customers bought within a period,
/// under one organization's [PositivacaoSettings] rule.
///
/// Never a summation contract for the same reason
/// `TargetAchievementRepository`/`TargetAchievementSnapshot` (TASK-116)
/// aren't: [totalPortfolio]/[positivatedCount]/[nonPositivatedCustomerIds]
/// must always come from a value some server-side aggregation already
/// computed — never this app summing raw Customer/Order documents on the
/// client, per the BI aggregation rule in `AGENTS.md`. [calculatedAt] `null`
/// means "no aggregation pipeline has populated this dimension/period yet",
/// a real, expected state today since no task before this one wires that
/// pipeline (see this task's own conclusion doc) — never "zero clientes".
final class PositivacaoSnapshot {
  const PositivacaoSnapshot({
    required this.organizationId,
    required this.companyId,
    required this.dimensionType,
    required this.dimensionId,
    required this.periodStart,
    required this.periodEnd,
    this.totalPortfolio,
    this.positivatedCount,
    this.nonPositivatedCustomerIds = const <String>[],
    this.calculatedAt,
  }) : assert(
         (totalPortfolio == null) == (calculatedAt == null),
         'totalPortfolio and calculatedAt must both be null or both be set.',
       ),
       assert(
         (positivatedCount == null) == (calculatedAt == null),
         'positivatedCount and calculatedAt must both be null or both be '
         'set.',
       );

  final String organizationId;
  final String companyId;
  final PositivacaoDimensionType dimensionType;
  final String dimensionId;

  /// Inclusive start / exclusive end of the period this snapshot covers.
  final DateTime periodStart;
  final DateTime periodEnd;

  /// Total number of customers in the carteira at calculation time — a
  /// snapshot, not a live count, so a customer removed/inactivated from the
  /// carteira afterwards never distorts an already-calculated period.
  final int? totalPortfolio;

  /// How many of [totalPortfolio] bought within the period under the
  /// applicable [PositivacaoSettings] rule.
  final int? positivatedCount;

  /// Ids of the customers who did **not** buy in the period — the
  /// "clientes pendentes de compra" list for commercial action. Only
  /// meaningful once [isCalculated] is `true`.
  final List<String> nonPositivatedCustomerIds;

  /// When the server last computed this snapshot, or `null` alongside
  /// [totalPortfolio]/[positivatedCount].
  final DateTime? calculatedAt;

  bool get isCalculated => calculatedAt != null;

  /// `positivatedCount / totalPortfolio * 100`, `0` for an empty carteira
  /// (never a `NaN`/`Infinity` division by zero) and `0` while
  /// [isCalculated] is `false`.
  double get percentage {
    final total = totalPortfolio;
    final positivated = positivatedCount;
    if (total == null || positivated == null || total <= 0) return 0;
    return (positivated / total) * 100;
  }

  /// A snapshot for [organizationId]/[companyId]/[dimensionType]/
  /// [dimensionId]/[periodStart]/[periodEnd] with nothing calculated yet —
  /// the "cálculo ainda não disponível" state every `PositivacaoRepository`
  /// implementation resolves to until a real aggregation pipeline runs.
  factory PositivacaoSnapshot.notCalculated({
    required String organizationId,
    required String companyId,
    required PositivacaoDimensionType dimensionType,
    required String dimensionId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    return PositivacaoSnapshot(
      organizationId: organizationId,
      companyId: companyId,
      dimensionType: dimensionType,
      dimensionId: dimensionId,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }
}
