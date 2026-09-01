import '../../../sync/domain/entities/outbox_summary.dart';

/// The four UI states TASK-113 requires from the combined device
/// connectivity + Outbox summary signal.
enum ConnectivityIndicatorStatus {
  onlineSynced,
  onlineSyncing,
  offlinePending,
  offlineNoPending,
}

/// Aggregated connectivity state shown by the global indicator (TASK-113).
final class ConnectivityIndicatorState {
  const ConnectivityIndicatorState({
    this.organizationId = '',
    this.isOnline = true,
    this.outboxSummary = const OutboxSummary(),
  });

  final String organizationId;
  final bool isOnline;
  final OutboxSummary outboxSummary;

  ConnectivityIndicatorStatus get status {
    if (isOnline) {
      return outboxSummary.totalUnsyncedCount > 0
          ? ConnectivityIndicatorStatus.onlineSyncing
          : ConnectivityIndicatorStatus.onlineSynced;
    }

    return outboxSummary.totalUnsyncedCount > 0
        ? ConnectivityIndicatorStatus.offlinePending
        : ConnectivityIndicatorStatus.offlineNoPending;
  }

  bool get hasUnsyncedOperations => outboxSummary.totalUnsyncedCount > 0;

  ConnectivityIndicatorState copyWith({
    String? organizationId,
    bool? isOnline,
    OutboxSummary? outboxSummary,
  }) {
    return ConnectivityIndicatorState(
      organizationId: organizationId ?? this.organizationId,
      isOnline: isOnline ?? this.isOnline,
      outboxSummary: outboxSummary ?? this.outboxSummary,
    );
  }
}
