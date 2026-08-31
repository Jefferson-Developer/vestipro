import '../../domain/entities/order_submission_issue.dart';

/// Lifecycle of the "novo pedido" screen's pre-submit validation (EPIC-13,
/// TASK-100).
enum OrderSubmissionValidationStatus {
  /// Nothing evaluated yet (draft just loaded/no order to evaluate).
  initial,

  /// Re-running `OrderSubmissionValidator` for the draft's current state —
  /// "Enviar pedido" stays disabled while this is in flight, so a stale
  /// pass/fail result is never acted on.
  evaluating,

  /// [OrderSubmissionValidationState.issues] reflects exactly the draft's
  /// current state.
  evaluated,
}

/// State of `OrderSubmissionValidationCubit` (EPIC-13, TASK-100).
final class OrderSubmissionValidationState {
  const OrderSubmissionValidationState({
    this.status = OrderSubmissionValidationStatus.initial,
    this.issues = const <OrderSubmissionIssue>[],
  });

  final OrderSubmissionValidationStatus status;
  final List<OrderSubmissionIssue> issues;

  bool get isEvaluating => status == OrderSubmissionValidationStatus.evaluating;

  List<OrderSubmissionIssue> get blockingIssues =>
      issues.where((issue) => issue.isBlocking).toList(growable: false);

  List<OrderSubmissionIssue> get warnings =>
      issues.where((issue) => !issue.isBlocking).toList(growable: false);

  bool get hasPendencies => issues.isNotEmpty;

  /// Whether "Enviar pedido" may be enabled: the draft has already been
  /// evaluated (never while [OrderSubmissionValidationStatus.evaluating] or
  /// [OrderSubmissionValidationStatus.initial], to never act on a stale or
  /// missing result) and no [OrderSubmissionIssue.isBlocking] pendency
  /// remains — a [warnings]-only result never blocks submission by itself
  /// (TASK-100's own rule).
  bool get canSubmit =>
      status == OrderSubmissionValidationStatus.evaluated &&
      blockingIssues.isEmpty;

  OrderSubmissionValidationState copyWith({
    OrderSubmissionValidationStatus? status,
    List<OrderSubmissionIssue>? issues,
  }) {
    return OrderSubmissionValidationState(
      status: status ?? this.status,
      issues: issues ?? this.issues,
    );
  }
}
