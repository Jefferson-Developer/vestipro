/// Outcome of one run of `LoadInitialCustomerOfflineDataUseCase`.
final class CustomerOfflineLoadSummary {
  const CustomerOfflineLoadSummary({
    required this.downloadedCount,
    required this.truncated,
    required this.loadedAt,
  });

  /// How many customers were written to the local store.
  final int downloadedCount;

  /// `true` when the remote portfolio had more customers than `maxCustomers`
  /// allowed this run to fetch (only realistically reachable for
  /// `ADMIN`/`OWNER`'s organization-wide scope). The local store still holds
  /// a consistent, usable subset — it is just not the full portfolio.
  final bool truncated;

  final DateTime loadedAt;

  static final empty = CustomerOfflineLoadSummary(
    downloadedCount: 0,
    truncated: false,
    loadedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}
