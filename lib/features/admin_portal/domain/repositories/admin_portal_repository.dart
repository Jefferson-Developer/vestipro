import '../../../../core/utils/utils.dart';
import '../entities/admin_portal_models.dart';

abstract interface class AdminPortalRepository {
  Future<AppResult<VestiProOperatorSession>> resolveOperatorSession();

  Future<AppResult<List<AdminOrganizationSummary>>> searchOrganizations({
    required String query,
    required String reason,
    String? ticketId,
  });

  Future<AppResult<AdminPortalDiagnosticReport>> loadDiagnosticReport(
    AdminPortalAccessRequest request,
  );

  Future<AppResult<AdminPortalActionResult>> reprocessOutboxItem(
    AdminPortalAccessRequest request,
  );
}
