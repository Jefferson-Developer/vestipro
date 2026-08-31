/// Outcome of one run of `LoadInitialCustomerOfflineDataUseCase`.
final class CustomerOfflineLoadSummary {
  const CustomerOfflineLoadSummary({
    required this.downloadedCount,
    required this.truncated,
    required this.loadedAt,
    this.cancelled = false,
  });

  /// How many customers were written to the local store.
  final int downloadedCount;

  /// `true` when the remote portfolio had more customers than `maxCustomers`
  /// allowed this run to fetch (only realistically reachable for
  /// `ADMIN`/`OWNER`'s organization-wide scope). The local store still holds
  /// a consistent, usable subset — it is just not the full portfolio.
  final bool truncated;

  final DateTime loadedAt;

  /// `true` when a caller-supplied `OfflinePackageCancellationToken`
  /// (TASK-107) was observed cancelled mid-fetch — [downloadedCount] is
  /// always `0` in that case because the local replace was never attempted,
  /// not because nothing was fetched.
  final bool cancelled;

  static final empty = CustomerOfflineLoadSummary(
    downloadedCount: 0,
    truncated: false,
    loadedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}
