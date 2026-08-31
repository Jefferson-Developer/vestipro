/// Exponential backoff/retry-limit policy for `SyncEngine.runPush`
/// (TASK-109, EPIC-14).
///
/// [OutboxOperation.attemptCount] (see `OutboxTable` docs) already tracks
/// how many times an operation has been attempted, bumped by
/// `OutboxRepository.markSyncing` right before each attempt — this class
/// turns that count into "is this operation due for another attempt right
/// now" and "has it exhausted its retry budget", without needing any extra
/// persisted state.
final class SyncRetryPolicy {
  const SyncRetryPolicy({
    this.maxAttempts = 6,
    this.baseDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(minutes: 5),
  }) : assert(maxAttempts > 0, 'maxAttempts must be positive');

  /// How many attempts an operation gets before it is left `failed`,
  /// outside the automatic retry path, requiring manual action from the
  /// future Central de Sincronização (TASK-112).
  final int maxAttempts;

  /// Delay before the first retry (i.e. the wait after attempt 1 fails,
  /// before attempt 2 starts). Doubles for every attempt after that
  /// (2s, 4s, 8s, ... by default) up to [maxDelay].
  final Duration baseDelay;

  final Duration maxDelay;

  /// Whether an operation that has already been attempted [attemptCount]
  /// times may still be retried automatically.
  bool hasAttemptsLeft(int attemptCount) => attemptCount < maxAttempts;

  /// The backoff delay to wait after an operation's [attemptCount]-th
  /// attempt before its next one is due — `Duration.zero` for an operation
  /// that has never been attempted yet ([attemptCount] `<= 0`).
  Duration delayForAttempt(int attemptCount) {
    if (attemptCount <= 0) return Duration.zero;
    // 2^(attemptCount - 1): 1, 2, 4, 8, ... — capped so a large attemptCount
    // (e.g. a persisted row from a future build with a higher maxAttempts)
    // can never overflow into a negative/garbage duration.
    final uncappedFactor = attemptCount - 1 >= 62
        ? double.infinity
        : (1 << (attemptCount - 1)).toDouble();
    final candidateMicros = baseDelay.inMicroseconds * uncappedFactor;
    final cappedMicros = candidateMicros >= maxDelay.inMicroseconds
        ? maxDelay.inMicroseconds
        : candidateMicros.round();
    return Duration(microseconds: cappedMicros);
  }

  /// Whether an operation last attempted at [lastAttemptAt] (`null` if it
  /// was never attempted) with [attemptCount] prior attempts is due for
  /// another attempt at [now].
  bool isDueForRetry({
    required int attemptCount,
    required DateTime? lastAttemptAt,
    required DateTime now,
  }) {
    if (lastAttemptAt == null) return true;
    return !now.isBefore(lastAttemptAt.add(delayForAttempt(attemptCount)));
  }
}
