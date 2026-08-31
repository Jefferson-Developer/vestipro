/// A cooperative cancellation flag `DownloadOfflinePackageUseCase` and every
/// `OfflinePackageEntityLoader` check between lots (TASK-107).
///
/// Deliberately not a `Stream`/`Future`-based cancellation primitive: every
/// checkpoint in this codebase's offline load loops is a plain synchronous
/// `if (cancellationToken.isCancelled)` right after a lot finishes fetching
/// and before it would otherwise start the next one (or before the entity's
/// single atomic local write), which is enough to guarantee a cancellation
/// never interrupts a write that is already in progress — only ever skips a
/// write that has not started yet.
final class OfflinePackageCancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}
