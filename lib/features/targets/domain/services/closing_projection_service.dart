import 'package:injectable/injectable.dart';

import '../entities/target_progress_view_model.dart';
import '../value_objects/projection_reliability.dart';
import 'projection_strategy.dart';

/// The projected result of a period's closing (TASK-119, EPIC-15), shown
/// alongside — and always visually distinct from — the realized value on the
/// achievement dashboard.
///
/// Every field here is either copied straight from the
/// [TargetProgressViewModel] this was computed from, or derived from
/// [ClosingProjectionService]'s own arithmetic on that same view model's
/// `target`/`realizedValue`/`now` — never from an independently fetched
/// number — so it can never numerically diverge from what the dashboard
/// (TASK-116) already shows for "realizado".
final class ClosingProjectionResult {
  const ClosingProjectionResult({
    required this.projectedValue,
    required this.projectedAchievementPercentage,
    required this.reliability,
    required this.methodologyDescription,
    required this.isAboveTarget,
  });

  /// Estimated final value for the period, per [reliability]'s methodology.
  final double projectedValue;

  /// [projectedValue] as a % of the target's goal (same zero-target guard as
  /// `TargetProgressViewModel.achievementPercentage`).
  final double projectedAchievementPercentage;

  final ProjectionReliability reliability;

  /// Short, user-facing explanation of how [projectedValue] was calculated —
  /// always rendered next to it, per the "nunca uma caixa preta" rule.
  final String methodologyDescription;

  /// Whether [projectedValue] meets or exceeds the target's goal.
  final bool isAboveTarget;

  /// Fewer than 10% of the period has elapsed — too little pace data to
  /// trust the extrapolation. The UI must surface this, never hide it.
  bool get isLowConfidence =>
      reliability == ProjectionReliability.lowConfidence;

  /// The period is already over: [projectedValue] is simply the final
  /// realized value, not an extrapolation.
  bool get isFinalResult => reliability == ProjectionReliability.periodEnded;
}

/// Estimates a period's closing result (TASK-119, EPIC-15) from the exact
/// same [TargetProgressViewModel] the achievement dashboard (TASK-116)
/// already computed — this service never re-fetches or independently
/// re-derives "realizado", it only extrapolates from the numbers the
/// dashboard is already showing, so the two screens can never disagree.
///
/// The extrapolation formula itself is delegated to a [ProjectionStrategy]
/// (default [LinearProjectionStrategy]) precisely so it can be swapped for a
/// richer methodology later (weighted moving average, sazonalidade, ...)
/// without breaking this contract — see
/// `docs/architecture/closing-projection-methodology.md`.
///
/// Edge cases (see this service's own test file):
/// - Period not started yet, or fewer than 10% of it elapsed: the estimate
///   is still computed and returned, but flagged
///   [ProjectionReliability.lowConfidence] — never hidden, never silently
///   treated as reliable.
/// - Period already ended: no extrapolation is needed or attempted, the
///   projection is simply the final realized value
///   ([ProjectionReliability.periodEnded]).
/// - Zeroed/missing target value: percentages never divide by zero, mirroring
///   `TargetProgressViewModel`'s own zero-target guard.
@injectable
final class ClosingProjectionService {
  const ClosingProjectionService({
    ProjectionStrategy strategy = const LinearProjectionStrategy(),
  })
    // Not an initializing formal on purpose: the public parameter is named
    // `strategy`, but the field is private `_strategy` — an initializing
    // formal would force the parameter itself to be private too, breaking the
    // public named-argument API (`ClosingProjectionService(strategy: ...)`).
    // ignore: prefer_initializing_formals
    : _strategy = strategy;

  final ProjectionStrategy _strategy;

  /// Below this fraction of the period elapsed, the projection is flagged
  /// [ProjectionReliability.lowConfidence] (task's "menos de 10% do
  /// período" rule).
  static const double lowConfidenceElapsedThreshold = 0.10;

  ClosingProjectionResult compute(TargetProgressViewModel progress) {
    final target = progress.target;
    final targetValue = target.targetValue;

    if (progress.isPeriodEnded) {
      final finalValue = progress.realizedValue;
      return ClosingProjectionResult(
        projectedValue: finalValue,
        projectedAchievementPercentage: progress.achievementPercentage,
        reliability: ProjectionReliability.periodEnded,
        methodologyDescription:
            'Período encerrado: a projeção é o valor final realizado, sem '
            'necessidade de estimativa.',
        isAboveTarget: finalValue >= targetValue,
      );
    }

    // Recomputed from the same target/now the passed-in [progress] itself
    // used (never from a fresh `DateTime.now()`), so this is bit-identical
    // to `TargetProgressViewModel.elapsedTimePercentage / 100` — the
    // consistency this service's test file asserts.
    final totalPeriodMs = target.endDate
        .difference(target.startDate)
        .inMilliseconds;
    final elapsedMs = progress.now.difference(target.startDate).inMilliseconds;
    final elapsedFraction = totalPeriodMs <= 0
        ? 1.0
        : (elapsedMs / totalPeriodMs).clamp(0.0, 1.0);

    final projectedValue = _strategy.project(
      realizedValue: progress.realizedValue,
      elapsedFraction: elapsedFraction,
    );
    final projectedAchievementPercentage = targetValue == 0
        ? (projectedValue > 0 ? 100.0 : 0.0)
        : (projectedValue / targetValue) * 100;

    final reliability = elapsedFraction < lowConfidenceElapsedThreshold
        ? ProjectionReliability.lowConfidence
        : ProjectionReliability.reliable;

    return ClosingProjectionResult(
      projectedValue: projectedValue,
      projectedAchievementPercentage: projectedAchievementPercentage,
      reliability: reliability,
      methodologyDescription: _strategy.methodologyDescription,
      isAboveTarget: projectedValue >= targetValue,
    );
  }
}
