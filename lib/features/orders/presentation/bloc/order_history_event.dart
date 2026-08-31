sealed class OrderHistoryEvent {
  const OrderHistoryEvent();
}

/// Loads the history/detail screen (TASK-104) for [orderId], scoped by
/// [organizationId]/[companyId] and re-checked against [userId]'s own
/// visibility through `GetOrderByIdUseCase`.
final class OrderHistoryStarted extends OrderHistoryEvent {
  const OrderHistoryStarted({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.orderId,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final String orderId;
}

/// Retries the same load after a failure, without requiring the caller to
/// resend every parameter again.
final class OrderHistoryRetried extends OrderHistoryEvent {
  const OrderHistoryRetried();
}
