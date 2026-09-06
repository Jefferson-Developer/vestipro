import '../../../../core/utils/utils.dart';
import '../entities/customer_import_template.dart';

/// Domain contract for `CustomerImportTemplate` persistence (TASK-167).
/// Firestore-backed (`organizations/{organizationId}/customerImportTemplates`),
/// written directly by the client (unlike `CustomerImportJob`, which only a
/// Cloud Function ever writes) since saving a mapping template carries no
/// financial/authorization risk beyond normal tenant scoping.
abstract interface class CustomerImportTemplateRepository {
  Future<AppResult<List<CustomerImportTemplate>>> listByOrganization({
    required String organizationId,
  });

  Future<AppResult<CustomerImportTemplate>> save({
    required CustomerImportTemplate template,
  });

  Future<AppResult<void>> delete({
    required String organizationId,
    required String id,
  });
}
