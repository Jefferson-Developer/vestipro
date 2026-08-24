import '../../../crm/crm.dart';

sealed class CustomerDetailEvent {
  const CustomerDetailEvent();
}

final class CustomerDetailStarted extends CustomerDetailEvent {
  const CustomerDetailStarted({
    required this.organizationId,
    required this.customerId,
    required this.userId,
  });

  final String organizationId;
  final String customerId;
  final String userId;
}

final class CustomerDetailRetried extends CustomerDetailEvent {
  const CustomerDetailRetried();
}

final class CustomerDetailTimelineRetried extends CustomerDetailEvent {
  const CustomerDetailTimelineRetried();
}

final class CustomerDetailTimelineLoadMoreRequested
    extends CustomerDetailEvent {
  const CustomerDetailTimelineLoadMoreRequested();
}

final class CustomerDetailActivitySubmitted extends CustomerDetailEvent {
  const CustomerDetailActivitySubmitted({
    required this.description,
    required this.type,
    this.durationMinutes,
  });

  final String description;
  final CrmActivityType type;
  final int? durationMinutes;
}

final class CustomerDetailActivitySubmissionAcknowledged
    extends CustomerDetailEvent {
  const CustomerDetailActivitySubmissionAcknowledged();
}
