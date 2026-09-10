enum VestiProOperatorPermission {
  viewPortal,
  viewSensitiveData,
  reprocessOutbox,
}

extension VestiProOperatorPermissionCode on VestiProOperatorPermission {
  String get code {
    return switch (this) {
      VestiProOperatorPermission.viewPortal => 'adminPortal.view',
      VestiProOperatorPermission.viewSensitiveData =>
        'adminPortal.viewSensitiveData',
      VestiProOperatorPermission.reprocessOutbox =>
        'adminPortal.reprocessOutbox',
    };
  }
}

VestiProOperatorPermission parseVestiProOperatorPermission(String code) {
  for (final permission in VestiProOperatorPermission.values) {
    if (permission.code == code) return permission;
  }
  throw ArgumentError.value(code, 'code', 'Permissao de operador invalida.');
}

enum AdminPortalHealthStatus { healthy, warning, critical }

AdminPortalHealthStatus parseAdminPortalHealthStatus(String value) {
  return AdminPortalHealthStatus.values.byName(value);
}

enum AdminPortalLogLevel { info, warning, error }

AdminPortalLogLevel parseAdminPortalLogLevel(String value) {
  return AdminPortalLogLevel.values.byName(value);
}

enum AdminPortalAccessKind { summary, sensitiveDetail, supportAction }

extension AdminPortalAccessKindCode on AdminPortalAccessKind {
  String get code {
    return switch (this) {
      AdminPortalAccessKind.summary => 'summary',
      AdminPortalAccessKind.sensitiveDetail => 'sensitiveDetail',
      AdminPortalAccessKind.supportAction => 'supportAction',
    };
  }
}

final class VestiProOperatorSession {
  const VestiProOperatorSession({
    required this.userId,
    required this.displayName,
    required this.permissions,
  });

  final String userId;
  final String displayName;
  final Set<VestiProOperatorPermission> permissions;

  bool can(VestiProOperatorPermission permission) {
    return permissions.contains(permission);
  }
}

final class AdminOrganizationSummary {
  const AdminOrganizationSummary({
    required this.organizationId,
    required this.displayName,
    required this.status,
    required this.healthStatus,
    required this.activeUsers,
    required this.syncErrors,
    required this.orderVolumeLast30Days,
    required this.openTickets,
    required this.lastActivityAt,
  });

  final String organizationId;
  final String displayName;
  final String status;
  final AdminPortalHealthStatus healthStatus;
  final int activeUsers;
  final int syncErrors;
  final int orderVolumeLast30Days;
  final int openTickets;
  final DateTime? lastActivityAt;
}

final class AdminPortalDiagnosticReport {
  const AdminPortalDiagnosticReport({
    required this.organizationId,
    required this.userId,
    required this.deviceId,
    required this.syncStatus,
    required this.pendingOutboxItems,
    required this.failedOutboxItems,
    required this.lastSyncAt,
    required this.technicalLogs,
  });

  final String organizationId;
  final String userId;
  final String deviceId;
  final String syncStatus;
  final int pendingOutboxItems;
  final int failedOutboxItems;
  final DateTime? lastSyncAt;
  final List<AdminPortalTechnicalLog> technicalLogs;
}

final class AdminPortalTechnicalLog {
  const AdminPortalTechnicalLog({
    required this.id,
    required this.level,
    required this.message,
    required this.occurredAt,
    required this.correlationId,
  });

  final String id;
  final AdminPortalLogLevel level;
  final String message;
  final DateTime occurredAt;
  final String? correlationId;
}

final class AdminPortalAccessRequest {
  const AdminPortalAccessRequest({
    required this.organizationId,
    required this.reason,
    required this.kind,
    this.ticketId,
    this.targetUserId,
    this.deviceId,
    this.outboxItemId,
  });

  final String organizationId;
  final String reason;
  final AdminPortalAccessKind kind;
  final String? ticketId;
  final String? targetUserId;
  final String? deviceId;
  final String? outboxItemId;
}

final class AdminPortalActionResult {
  const AdminPortalActionResult({
    required this.organizationId,
    required this.action,
    required this.message,
    required this.auditLogId,
  });

  final String organizationId;
  final String action;
  final String message;
  final String auditLogId;
}
