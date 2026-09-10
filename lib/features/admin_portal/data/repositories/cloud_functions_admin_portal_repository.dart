import '../../../../core/errors/errors.dart';
import '../../../../core/functions/functions.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/admin_portal_models.dart';
import '../../domain/repositories/admin_portal_repository.dart';

final class CloudFunctionsAdminPortalRepository
    implements AdminPortalRepository {
  const CloudFunctionsAdminPortalRepository(this._functions);

  final CloudFunctionsService _functions;

  @override
  Future<AppResult<VestiProOperatorSession>> resolveOperatorSession() {
    return _guard(() async {
      final json = await _functions.call<Map<String, dynamic>>(
        'resolveVestiProOperatorSession',
        requireAuth: true,
      );
      return VestiProOperatorSession(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String? ?? 'Operador VestiPro',
        permissions:
            (json['permissions'] as List<dynamic>? ?? const <dynamic>[])
                .cast<String>()
                .map(parseVestiProOperatorPermission)
                .toSet(),
      );
    });
  }

  @override
  Future<AppResult<List<AdminOrganizationSummary>>> searchOrganizations({
    required String query,
    required String reason,
    String? ticketId,
  }) {
    return _guard(() async {
      final json = await _functions.call<Map<String, dynamic>>(
        'searchAdminOrganizations',
        requireAuth: true,
        data: <String, dynamic>{
          'query': query,
          'reason': reason,
          'ticketId': ?ticketId,
        },
      );
      return (json['organizations'] as List<dynamic>? ?? const <dynamic>[])
          .map((raw) => _summary(Map<String, dynamic>.from(raw as Map)))
          .toList(growable: false);
    });
  }

  @override
  Future<AppResult<AdminPortalDiagnosticReport>> loadDiagnosticReport(
    AdminPortalAccessRequest request,
  ) {
    return _guard(() async {
      final json = await _functions.call<Map<String, dynamic>>(
        'loadAdminDiagnosticReport',
        requireAuth: true,
        data: _requestToJson(request),
      );
      return AdminPortalDiagnosticReport(
        organizationId: json['organizationId'] as String,
        userId: json['userId'] as String,
        deviceId: json['deviceId'] as String,
        syncStatus: json['syncStatus'] as String,
        pendingOutboxItems: json['pendingOutboxItems'] as int? ?? 0,
        failedOutboxItems: json['failedOutboxItems'] as int? ?? 0,
        lastSyncAt: _date(json['lastSyncAt']),
        technicalLogs:
            (json['technicalLogs'] as List<dynamic>? ?? const <dynamic>[])
                .map((raw) => _log(Map<String, dynamic>.from(raw as Map)))
                .toList(growable: false),
      );
    });
  }

  @override
  Future<AppResult<AdminPortalActionResult>> reprocessOutboxItem(
    AdminPortalAccessRequest request,
  ) {
    return _guard(() async {
      final json = await _functions.call<Map<String, dynamic>>(
        'reprocessAdminOutboxItem',
        requireAuth: true,
        data: _requestToJson(request),
      );
      return AdminPortalActionResult(
        organizationId: json['organizationId'] as String,
        action: json['action'] as String,
        message: json['message'] as String,
        auditLogId: json['auditLogId'] as String,
      );
    });
  }

  Map<String, dynamic> _requestToJson(AdminPortalAccessRequest request) {
    return <String, dynamic>{
      'organizationId': request.organizationId,
      'reason': request.reason,
      'kind': request.kind.code,
      'ticketId': ?request.ticketId,
      'targetUserId': ?request.targetUserId,
      'deviceId': ?request.deviceId,
      'outboxItemId': ?request.outboxItemId,
    };
  }

  AdminOrganizationSummary _summary(Map<String, dynamic> json) {
    return AdminOrganizationSummary(
      organizationId: json['organizationId'] as String,
      displayName: json['displayName'] as String,
      status: json['status'] as String? ?? 'unknown',
      healthStatus: parseAdminPortalHealthStatus(
        json['healthStatus'] as String? ?? 'warning',
      ),
      activeUsers: json['activeUsers'] as int? ?? 0,
      syncErrors: json['syncErrors'] as int? ?? 0,
      orderVolumeLast30Days: json['orderVolumeLast30Days'] as int? ?? 0,
      openTickets: json['openTickets'] as int? ?? 0,
      lastActivityAt: _date(json['lastActivityAt']),
    );
  }

  AdminPortalTechnicalLog _log(Map<String, dynamic> json) {
    return AdminPortalTechnicalLog(
      id: json['id'] as String,
      level: parseAdminPortalLogLevel(json['level'] as String? ?? 'info'),
      message: json['message'] as String,
      occurredAt:
          _date(json['occurredAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      correlationId: json['correlationId'] as String?,
    );
  }

  DateTime? _date(Object? value) {
    return value is String ? DateTime.parse(value).toUtc() : null;
  }

  Future<AppResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return AppSuccess<T>(await action());
    } on AppException catch (error) {
      return AppFailure<T>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<T>(
        UnexpectedFailure(
          'Falha inesperada no portal administrativo VestiPro.',
          cause: error,
        ),
      );
    }
  }
}
