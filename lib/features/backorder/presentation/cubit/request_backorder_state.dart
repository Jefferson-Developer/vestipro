enum RequestBackorderStatus { initial, submitting, success, failure }

/// Drives [RequestBackorderSheet] (TASK-215, EPIC-32) — a self-contained
/// form that opens a `BackorderRequest` for a produto/variante sem estoque
/// pronta entrega suficiente.
final class RequestBackorderState {
  const RequestBackorderState({
    this.status = RequestBackorderStatus.initial,
    this.failureMessage,
    this.lastBackorderId,
  });

  final RequestBackorderStatus status;
  final String? failureMessage;

  /// Set (once) right after `submit` succeeds — the resulting `backorderId`,
  /// consumed by the widget to close the sheet and show a confirmation.
  final String? lastBackorderId;

  bool get isSubmitting => status == RequestBackorderStatus.submitting;

  RequestBackorderState copyWith({
    RequestBackorderStatus? status,
    String? failureMessage,
    bool clearFailureMessage = false,
    String? lastBackorderId,
  }) {
    return RequestBackorderState(
      status: status ?? this.status,
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
      lastBackorderId: lastBackorderId ?? this.lastBackorderId,
    );
  }
}
