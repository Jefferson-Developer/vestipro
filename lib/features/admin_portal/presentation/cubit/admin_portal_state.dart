import '../../../../core/errors/errors.dart';
import '../../domain/entities/admin_portal_models.dart';

enum AdminPortalStatus {
  idle,
  loadingSession,
  ready,
  searching,
  loadingDiagnostic,
  reprocessing,
  denied,
  error,
}

final class AdminPortalState {
  const AdminPortalState({
    required this.status,
    this.session,
    this.organizations = const <AdminOrganizationSummary>[],
    this.selectedOrganization,
    this.diagnosticReport,
    this.actionResult,
    this.failure,
    this.reason = '',
    this.ticketId = '',
    this.query = '',
    this.targetUserId = '',
    this.deviceId = '',
    this.outboxItemId = '',
  });

  const AdminPortalState.initial() : this(status: AdminPortalStatus.idle);

  final AdminPortalStatus status;
  final VestiProOperatorSession? session;
  final List<AdminOrganizationSummary> organizations;
  final AdminOrganizationSummary? selectedOrganization;
  final AdminPortalDiagnosticReport? diagnosticReport;
  final AdminPortalActionResult? actionResult;
  final Failure? failure;
  final String reason;
  final String ticketId;
  final String query;
  final String targetUserId;
  final String deviceId;
  final String outboxItemId;

  bool get isBusy =>
      status == AdminPortalStatus.loadingSession ||
      status == AdminPortalStatus.searching ||
      status == AdminPortalStatus.loadingDiagnostic ||
      status == AdminPortalStatus.reprocessing;

  bool get canViewSensitiveData =>
      session?.can(VestiProOperatorPermission.viewSensitiveData) ?? false;

  bool get canReprocessOutbox =>
      session?.can(VestiProOperatorPermission.reprocessOutbox) ?? false;

  AdminPortalState copyWith({
    AdminPortalStatus? status,
    VestiProOperatorSession? session,
    List<AdminOrganizationSummary>? organizations,
    AdminOrganizationSummary? selectedOrganization,
    bool clearSelectedOrganization = false,
    AdminPortalDiagnosticReport? diagnosticReport,
    bool clearDiagnosticReport = false,
    AdminPortalActionResult? actionResult,
    bool clearActionResult = false,
    Failure? failure,
    bool clearFailure = false,
    String? reason,
    String? ticketId,
    String? query,
    String? targetUserId,
    String? deviceId,
    String? outboxItemId,
  }) {
    return AdminPortalState(
      status: status ?? this.status,
      session: session ?? this.session,
      organizations: organizations ?? this.organizations,
      selectedOrganization: clearSelectedOrganization
          ? null
          : selectedOrganization ?? this.selectedOrganization,
      diagnosticReport: clearDiagnosticReport
          ? null
          : diagnosticReport ?? this.diagnosticReport,
      actionResult: clearActionResult
          ? null
          : actionResult ?? this.actionResult,
      failure: clearFailure ? null : failure ?? this.failure,
      reason: reason ?? this.reason,
      ticketId: ticketId ?? this.ticketId,
      query: query ?? this.query,
      targetUserId: targetUserId ?? this.targetUserId,
      deviceId: deviceId ?? this.deviceId,
      outboxItemId: outboxItemId ?? this.outboxItemId,
    );
  }
}
