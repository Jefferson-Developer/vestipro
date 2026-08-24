sealed class CustomerDetailEvent {
  const CustomerDetailEvent();
}

final class CustomerDetailStarted extends CustomerDetailEvent {
  const CustomerDetailStarted({
    required this.organizationId,
    required this.customerId,
  });

  final String organizationId;
  final String customerId;
}

final class CustomerDetailRetried extends CustomerDetailEvent {
  const CustomerDetailRetried();
}
