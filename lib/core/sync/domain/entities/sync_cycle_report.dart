import 'sync_pull_report.dart';
import 'sync_push_report.dart';

/// Combined outcome of one `SyncEngine.runFullCycle` call (TASK-109,
/// EPIC-14): a push pass (drain the Outbox) followed by a pull pass (apply
/// incremental remote changes), in that order — see `SyncEngine.runFullCycle`
/// docs for why push always runs first.
final class SyncCycleReport {
  const SyncCycleReport({
    required this.push,
    required this.pull,
    required this.completedAt,
  });

  final SyncPushReport push;
  final SyncPullReport pull;
  final DateTime completedAt;
}
