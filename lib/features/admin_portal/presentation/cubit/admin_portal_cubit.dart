// ignore_for_file: prefer_initializing_formals

import 'package:bloc/bloc.dart';

import '../../domain/entities/admin_portal_models.dart';
import '../../domain/usecases/admin_portal_use_cases.dart';
import 'admin_portal_state.dart';

final class AdminPortalCubit extends Cubit<AdminPortalState> {
  AdminPortalCubit({
    required ResolveVestiProOperatorSessionUseCase resolveSession,
    required SearchAdminOrganizationsUseCase searchOrganizations,
    required LoadAdminDiagnosticReportUseCase loadDiagnosticReport,
    required ReprocessAdminOutboxItemUseCase reprocessOutboxItem,
  }) : _resolveSession = resolveSession,
       _searchOrganizations = searchOrganizations,
       _loadDiagnosticReport = loadDiagnosticReport,
       _reprocessOutboxItem = reprocessOutboxItem,
       super(const AdminPortalState.initial());

  final ResolveVestiProOperatorSessionUseCase _resolveSession;
  final SearchAdminOrganizationsUseCase _searchOrganizations;
  final LoadAdminDiagnosticReportUseCase _loadDiagnosticReport;
  final ReprocessAdminOutboxItemUseCase _reprocessOutboxItem;

  Future<void> loadSession() async {
    emit(
      state.copyWith(
        status: AdminPortalStatus.loadingSession,
        clearFailure: true,
      ),
    );
    final result = await _resolveSession();
    result.fold(
      onSuccess: (session) {
        emit(
          state.copyWith(
            status: session.can(VestiProOperatorPermission.viewPortal)
                ? AdminPortalStatus.ready
                : AdminPortalStatus.denied,
            session: session,
          ),
        );
      },
      onFailure: (failure) {
        emit(state.copyWith(status: AdminPortalStatus.error, failure: failure));
      },
    );
  }

  void updateReason(String value) {
    emit(state.copyWith(reason: value, clearFailure: true));
  }

  void updateTicketId(String value) {
    emit(state.copyWith(ticketId: value, clearFailure: true));
  }

  void updateTargetUserId(String value) {
    emit(state.copyWith(targetUserId: value, clearFailure: true));
  }

  void updateDeviceId(String value) {
    emit(state.copyWith(deviceId: value, clearFailure: true));
  }

  void updateOutboxItemId(String value) {
    emit(state.copyWith(outboxItemId: value, clearFailure: true));
  }

  Future<void> search(String query) async {
    emit(
      state.copyWith(
        status: AdminPortalStatus.searching,
        query: query,
        clearFailure: true,
        clearActionResult: true,
      ),
    );
    final result = await _searchOrganizations(
      query: query,
      reason: state.reason,
      ticketId: state.ticketId,
    );
    result.fold(
      onSuccess: (organizations) {
        emit(
          state.copyWith(
            status: AdminPortalStatus.ready,
            organizations: organizations,
            selectedOrganization:
                organizations.contains(state.selectedOrganization)
                ? state.selectedOrganization
                : null,
            clearSelectedOrganization: !organizations.contains(
              state.selectedOrganization,
            ),
          ),
        );
      },
      onFailure: (failure) {
        emit(state.copyWith(status: AdminPortalStatus.error, failure: failure));
      },
    );
  }

  void selectOrganization(AdminOrganizationSummary organization) {
    emit(
      state.copyWith(
        selectedOrganization: organization,
        clearDiagnosticReport: true,
        clearActionResult: true,
        clearFailure: true,
      ),
    );
  }

  Future<void> loadDiagnostic() async {
    final organization = state.selectedOrganization;
    if (organization == null) return;
    emit(
      state.copyWith(
        status: AdminPortalStatus.loadingDiagnostic,
        clearFailure: true,
        clearActionResult: true,
      ),
    );
    final result = await _loadDiagnosticReport(_accessRequest(organization));
    result.fold(
      onSuccess: (report) => emit(
        state.copyWith(
          status: AdminPortalStatus.ready,
          diagnosticReport: report,
        ),
      ),
      onFailure: (failure) {
        emit(state.copyWith(status: AdminPortalStatus.error, failure: failure));
      },
    );
  }

  Future<void> reprocessOutbox() async {
    final organization = state.selectedOrganization;
    if (organization == null) return;
    emit(
      state.copyWith(
        status: AdminPortalStatus.reprocessing,
        clearFailure: true,
        clearActionResult: true,
      ),
    );
    final result = await _reprocessOutboxItem(
      _accessRequest(organization, kind: AdminPortalAccessKind.supportAction),
    );
    result.fold(
      onSuccess: (action) => emit(
        state.copyWith(status: AdminPortalStatus.ready, actionResult: action),
      ),
      onFailure: (failure) {
        emit(state.copyWith(status: AdminPortalStatus.error, failure: failure));
      },
    );
  }

  AdminPortalAccessRequest _accessRequest(
    AdminOrganizationSummary organization, {
    AdminPortalAccessKind kind = AdminPortalAccessKind.sensitiveDetail,
  }) {
    return AdminPortalAccessRequest(
      organizationId: organization.organizationId,
      reason: state.reason,
      kind: kind,
      ticketId: state.ticketId,
      targetUserId: state.targetUserId,
      deviceId: state.deviceId,
      outboxItemId: state.outboxItemId,
    );
  }
}
