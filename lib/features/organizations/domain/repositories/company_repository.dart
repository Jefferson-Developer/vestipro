import '../../../../core/utils/utils.dart';
import '../entities/company.dart';
import '../value_objects/company_status.dart';

/// Contract for reading and writing [Company] documents scoped under one
/// [Organization] (TASK-027).
///
/// Every method requires [organizationId] so no query can be built without a
/// tenant scope by mistake — Firestore Security Rules (TASK-030) remain the
/// real source of truth for isolation, this is defense-in-depth only.
/// Deliberately narrow: [update] takes no parameter that could rewrite
/// [Company.organizationId], only mutable fields and audit metadata.
abstract interface class CompanyRepository {
  Future<AppResult<Company>> create({
    required String id,
    required String organizationId,
    required String name,
    String? legalName,
    String? taxId,
    required String createdBy,
  });

  /// Lists every non-deleted Company of [organizationId]. Never returns a
  /// Company belonging to a different organization.
  Future<AppResult<List<Company>>> listByOrganization(String organizationId);

  Future<AppResult<Company>> getById({
    required String organizationId,
    required String id,
  });

  /// Updates only [Company.name], [Company.legalName], [Company.taxId],
  /// [Company.status] and audit fields (`updatedAt`, `updatedBy`,
  /// `version`) of the Company identified by [organizationId]/[id]. Never
  /// accepts nor changes [Company.organizationId].
  Future<AppResult<Company>> update({
    required String organizationId,
    required String id,
    required String name,
    String? legalName,
    String? taxId,
    required CompanyStatus status,
    required String updatedBy,
  });
}
