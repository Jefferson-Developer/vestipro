import '../entities/target.dart';

/// Pure "quanto falta para bater a meta" computation for one [Target]
/// (TASK-116, EPIC-15): realized value, gap (absolute and %), achievement %,
/// how much of the period has elapsed and a simple linear projection of the
/// final result at the current pace.
///
/// Never itself queries anything: [realizedValue] must already be the
/// server-computed snapshot `TargetAchievementRepository` resolved (never a
/// client-side sum of raw order documents, per the BI aggregation rule in
/// `AGENTS.md`), and [now] is always caller-injected — never read internally
/// via `DateTime.now()` — so [compute] stays a pure, trivially unit-testable
/// function (see its own test file's "meta zerada"/"realizado maior que a
/// meta"/"período ainda não iniciado"/"período já encerrado" cases).
/// `TargetDashboardCubit` is the only caller, recomputing once per
/// `TargetAchievementRepository.watchForTarget` tick.
final class TargetProgressViewModel {
  const TargetProgressViewModel({
    required this.target,
    required this.realizedValue,
    required this.calculatedAt,
    required this.now,
    required this.gapAbsolute,
    required this.gapPercentage,
    required this.achievementPercentage,
    required this.elapsedTimePercentage,
    required this.projectedValue,
    required this.projectedAchievementPercentage,
  });

  final Target target;
  final double realizedValue;

  /// When the server last computed [realizedValue] — `null` only ever means
  /// "unknown", the caller is still responsible for never constructing this
  /// view model at all while the underlying snapshot is uncalculated.
  final DateTime? calculatedAt;

  /// The instant this view model was computed for — always caller-injected.
  final DateTime now;

  /// `target.targetValue - realizedValue`. Negative once [realizedValue]
  /// exceeds the goal.
  final double gapAbsolute;

  /// [gapAbsolute] as a % of `target.targetValue` (`0` when the target is
  /// zeroed, never a division-by-zero `NaN`/`Infinity`).
  final double gapPercentage;

  /// `realizedValue / target.targetValue * 100` (never a `NaN`/`Infinity`
  /// for a zeroed target: `100` when something was realized against a zero
  /// goal, `0` otherwise).
  final double achievementPercentage;

  /// How much of `target.startDate`..`target.endDate` has elapsed as of
  /// [now], clamped to `0`..`100` (`0` before the period starts, `100` once
  /// it has ended).
  final double elapsedTimePercentage;

  /// Linear projection of the final realized value at the current pace:
  /// `realizedValue` divided by the elapsed fraction of the period. Before
  /// the period starts, or once it has fully elapsed, the projection is
  /// simply [realizedValue] itself — there is no pace to extrapolate yet,
  /// or nothing left to extrapolate.
  final double projectedValue;

  /// [projectedValue] as a % of `target.targetValue`, same zero-target
  /// guard as [achievementPercentage].
  final double projectedAchievementPercentage;

  bool get isPeriodNotStarted => now.isBefore(target.startDate);

  bool get isPeriodEnded => !now.isBefore(target.endDate);

  /// Whether [realizedValue] is keeping pace with (or ahead of) how much of
  /// the period has already elapsed — the signal `AppKpiCard.trend` reads to
  /// decide up/down for "Realizado" and "Atingimento".
  bool get isOnPace => achievementPercentage >= elapsedTimePercentage;

  factory TargetProgressViewModel.compute({
    required Target target,
    required double realizedValue,
    DateTime? calculatedAt,
    required DateTime now,
  }) {
    final targetValue = target.targetValue;
    final gapAbsolute = targetValue - realizedValue;
    final gapPercentage = targetValue == 0
        ? 0.0
        : (gapAbsolute / targetValue) * 100;
    final achievementPercentage = _percentageOf(realizedValue, targetValue);

    final totalPeriodMs = target.endDate
        .difference(target.startDate)
        .inMilliseconds;
    final elapsedMs = now.difference(target.startDate).inMilliseconds;
    final elapsedFraction = totalPeriodMs <= 0
        ? 1.0
        : (elapsedMs / totalPeriodMs).clamp(0.0, 1.0);
    final elapsedTimePercentage = elapsedFraction * 100;

    final projectedValue = (elapsedFraction <= 0 || elapsedFraction >= 1)
        ? realizedValue
        : realizedValue / elapsedFraction;
    final projectedAchievementPercentage = _percentageOf(
      projectedValue,
      targetValue,
    );

    return TargetProgressViewModel(
      target: target,
      realizedValue: realizedValue,
      calculatedAt: calculatedAt,
      now: now,
      gapAbsolute: gapAbsolute,
      gapPercentage: gapPercentage,
      achievementPercentage: achievementPercentage,
      elapsedTimePercentage: elapsedTimePercentage,
      projectedValue: projectedValue,
      projectedAchievementPercentage: projectedAchievementPercentage,
    );
  }

  static double _percentageOf(double value, double targetValue) {
    if (targetValue == 0) return value > 0 ? 100.0 : 0.0;
    return (value / targetValue) * 100;
  }
}
