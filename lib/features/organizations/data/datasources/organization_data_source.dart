import '../dtos/organization_dto.dart';
import '../dtos/organization_settings_dto.dart';

/// Data access contract for the root `organizations/{id}` document
/// (TASK-026). [FirestoreOrganizationDataSource] is the only implementation
/// today.
abstract interface class OrganizationDataSource {
  /// Creates the document at `organizations/{dto.id}` if it does not exist
  /// yet, otherwise returns the document already there unchanged —
  /// idempotent for retrying a failed create after a network error.
  Future<OrganizationDto> create(OrganizationDto dto);

  /// Returns `null` when no document exists for [id].
  Future<OrganizationDto?> getById(String id);

  /// Overwrites only `settings`, `updatedAt` and `updatedBy` on the existing
  /// document identified by [id]; never `id` or any other field.
  Future<OrganizationDto> updateSettings({
    required String id,
    required OrganizationSettingsDto settings,
    required DateTime updatedAt,
    required String updatedBy,
  });
}
