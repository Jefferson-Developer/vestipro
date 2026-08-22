import '../dtos/branch_address_dto.dart';
import '../dtos/branch_dto.dart';

/// Data access contract for `organizations/{organizationId}/branches/{id}`
/// documents (TASK-027). [FirestoreBranchDataSource] is the only
/// implementation today.
abstract interface class BranchDataSource {
  Future<BranchDto> create(BranchDto dto);

  /// Lists every non-deleted Branch document under [organizationId] whose
  /// `companyId` is [companyId]. Never queries across organizations or
  /// companies.
  Future<List<BranchDto>> listByCompany({
    required String organizationId,
    required String companyId,
  });

  /// Returns `null` when no document exists for [id] under [organizationId].
  Future<BranchDto?> getById({
    required String organizationId,
    required String id,
  });

  /// Overwrites only `name`, `type`, `address`, `status`, `updatedAt` and
  /// `updatedBy` on the existing document identified by
  /// [organizationId]/[id]; never `id`, `organizationId` or `companyId`.
  /// `version` is bumped atomically (Firestore `FieldValue.increment(1)`),
  /// never taken from the caller.
  Future<BranchDto> update({
    required String organizationId,
    required String id,
    required String name,
    required String type,
    BranchAddressDto? address,
    required String status,
    required DateTime updatedAt,
    required String updatedBy,
  });
}
