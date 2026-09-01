import 'package:injectable/injectable.dart';

/// A pluggable closing-projection methodology (TASK-119, EPIC-15).
///
/// [ClosingProjectionService] never hardcodes a formula itself — it always
/// delegates the actual extrapolation to a [ProjectionStrategy], so a future
/// methodology (weighted moving average, seasonality-aware, ...) can be
/// swapped in without touching the service's contract, the dashboard cubit,
/// or the UI. [LinearProjectionStrategy] is the only implementation today
/// and is the default `ClosingProjectionService` uses.
///
/// [methodologyDescription] exists precisely so the calculation is never a
/// "caixa preta": it is the short, user-facing text the dashboard renders
/// next to the projected value explaining how that number was produced.
abstract interface class ProjectionStrategy {
  /// Short, non-technical explanation of how [project] arrives at its
  /// number — shown to the user next to the projected value.
  String get methodologyDescription;

  /// Extrapolates the period's final result from [realizedValue] and
  /// [elapsedFraction] (the period's elapsed time as `0.0`..`1.0`).
  ///
  /// Implementations must treat `elapsedFraction <= 0` (period not started
  /// yet) and `elapsedFraction >= 1` (period already over) as "nothing to
  /// extrapolate" and return [realizedValue] unchanged — extrapolating from
  /// zero or negative pace would produce a meaningless number.
  double project({
    required double realizedValue,
    required double elapsedFraction,
  });
}

/// Default methodology (TASK-119): simple linear projection.
///
/// `projected = realizado até a data / fração do período decorrida`, i.e. it
/// assumes the current sales pace holds steady for the rest of the period.
/// This is intentionally the simplest possible extrapolation — documented
/// explicitly here rather than buried in code, per the "nunca uma caixa
/// preta" rule — and is deliberately not the only strategy this feature can
/// ever have: `docs/architecture/closing-projection-methodology.md` lists
/// alternative methodologies (weighted moving average, sazonalidade) left
/// for a future [ProjectionStrategy] implementation.
@Injectable(as: ProjectionStrategy)
final class LinearProjectionStrategy implements ProjectionStrategy {
  const LinearProjectionStrategy();

  @override
  String get methodologyDescription =>
      'Projeção linear: com base no ritmo atual de vendas, estimamos o '
      'resultado final dividindo o valor realizado até hoje pelo percentual '
      'do período já decorrido.';

  @override
  double project({
    required double realizedValue,
    required double elapsedFraction,
  }) {
    if (elapsedFraction <= 0 || elapsedFraction >= 1) return realizedValue;
    return realizedValue / elapsedFraction;
  }
}
