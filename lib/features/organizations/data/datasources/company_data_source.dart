import '../dtos/company_dto.dart';

/// Data access contract for `organizations/{organizationId}/companies/{id}`
/// documents (TASK-027). [FirestoreCompanyDataSource] is the only
/// implementation today.
abstract interface class CompanyDataSource {
  Future<CompanyDto> create(CompanyDto dto);

  /// Lists every non-deleted Company document under [organizationId].
  /// Never queries across organizations.
  Future<List<CompanyDto>> listByOrganization(String organizationId);

  /// Returns `null` when no document exists for [id] under [organizationId].
  Future<CompanyDto?> getById({
    required String organizationId,
    required String id,
  });

  /// Overwrites only `name`, `legalName`, `taxId`, `status`, `updatedAt`
  /// and `updatedBy` on the existing document identified by
  /// [organizationId]/[id]; never `id` or `organizationId`. `version` is
  /// bumped atomically (Firestore `FieldValue.increment(1)`), never taken
  /// from the caller.
  Future<CompanyDto> update({
    required String organizationId,
    required String id,
    required String name,
    String? legalName,
    String? taxId,
    required String status,
    required DateTime updatedAt,
    required String updatedBy,
  });
}
