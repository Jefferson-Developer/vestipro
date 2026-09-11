import '../../domain/entities/backorder_request.dart';

enum BackorderQueueStatus { initial, loading, ready, failure }

/// Drives [BackorderQueuePage] (TASK-215, EPIC-32) — the fila de atendimento
/// priorizada (`queue`, already sorted by priority/data server-side) plus a
/// separate "aguardando aprovação" inbox ([awaitingApproval]) for whoever
/// holds `Capability.backorderApprove`. Both lists are watched
/// simultaneously and kept in two independent streams: an org with zero
/// pending approvals still shows its queue, and vice-versa.
final class BackorderQueueState {
  const BackorderQueueState({
    this.status = BackorderQueueStatus.initial,
    this.queue = const <BackorderRequest>[],
    this.awaitingApproval = const <BackorderRequest>[],
    this.failureMessage,
    this.processingBackorderId,
    this.actionFailureMessage,
    this.lastActionBackorderId,
  });

  final BackorderQueueStatus status;
  final List<BackorderRequest> queue;
  final List<BackorderRequest> awaitingApproval;
  final String? failureMessage;

  /// The `id` of a backorder currently mid `decideBackorderApproval`/
  /// `cancelBackorderRequest`/`convertBackorderToOrder` call — used by the
  /// UI to disable just that row's actions, never the whole list.
  final String? processingBackorderId;
  final String? actionFailureMessage;

  /// Set (once) right after an approve/reject/cancel/convert action
  /// succeeds — a one-shot signal the widget consumes to show a
  /// confirmation snackbar without re-showing it on every rebuild.
  final String? lastActionBackorderId;

  bool get isLoading =>
      status == BackorderQueueStatus.initial ||
      status == BackorderQueueStatus.loading;

  BackorderQueueState copyWith({
    BackorderQueueStatus? status,
    List<BackorderRequest>? queue,
    List<BackorderRequest>? awaitingApproval,
    String? failureMessage,
    bool clearFailureMessage = false,
    String? processingBackorderId,
    bool clearProcessingBackorderId = false,
    String? actionFailureMessage,
    bool clearActionFailureMessage = false,
    String? lastActionBackorderId,
  }) {
    return BackorderQueueState(
      status: status ?? this.status,
      queue: queue ?? this.queue,
      awaitingApproval: awaitingApproval ?? this.awaitingApproval,
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
      processingBackorderId: clearProcessingBackorderId
          ? null
          : (processingBackorderId ?? this.processingBackorderId),
      actionFailureMessage: clearActionFailureMessage
          ? null
          : (actionFailureMessage ?? this.actionFailureMessage),
      lastActionBackorderId:
          lastActionBackorderId ?? this.lastActionBackorderId,
    );
  }
}
