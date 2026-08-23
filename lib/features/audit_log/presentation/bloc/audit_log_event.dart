import 'audit_log_action_filter.dart';

sealed class AuditLogEvent {
  const AuditLogEvent();
}

final class AuditLogStarted extends AuditLogEvent {
  const AuditLogStarted({required this.organizationId, required this.userId});

  final String organizationId;
  final String userId;
}

final class AuditLogRefreshRequested extends AuditLogEvent {
  const AuditLogRefreshRequested();
}

final class AuditLogLoadMoreRequested extends AuditLogEvent {
  const AuditLogLoadMoreRequested();
}

final class AuditLogActorFilterChanged extends AuditLogEvent {
  const AuditLogActorFilterChanged(this.actorUserId);

  final String actorUserId;
}

final class AuditLogActionFilterChanged extends AuditLogEvent {
  const AuditLogActionFilterChanged(this.filter);

  final AuditLogActionFilter? filter;
}

final class AuditLogPeriodFilterChanged extends AuditLogEvent {
  const AuditLogPeriodFilterChanged({this.from, this.to});

  final DateTime? from;
  final DateTime? to;
}

final class AuditLogTextFiltersApplied extends AuditLogEvent {
  const AuditLogTextFiltersApplied({
    required this.actorUserId,
    this.from,
    this.to,
  });

  final String actorUserId;
  final DateTime? from;
  final DateTime? to;
}

final class AuditLogFiltersCleared extends AuditLogEvent {
  const AuditLogFiltersCleared();
}
