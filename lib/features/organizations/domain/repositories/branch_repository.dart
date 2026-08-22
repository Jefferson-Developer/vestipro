import '../../../../core/utils/utils.dart';
import '../entities/branch.dart';
import '../value_objects/branch_address.dart';
import '../value_objects/branch_status.dart';
import '../value_objects/branch_type.dart';

/// Contract for reading and writing [Branch] documents scoped under one
/// [Organization]/[Company] (TASK-027).
///
/// Every method requires [organizationId] (and [companyId] where
/// applicable) so no query can be built without a tenant/company scope by
/// mistake — Firestore Security Rules (TASK-030) remain the real source of
/// truth for isolation, this is defense-in-depth only. Deliberately narrow:
/// [update] takes no parameter that could rewrite [Branch.organizationId]
/// or [Branch.companyId], only mutable fields and audit metadata.
abstract interface class BranchRepository {
  Future<AppResult<Branch>> create({
    required String id,
    required String organizationId,
    required String companyId,
    required String name,
    required BranchType type,
    BranchAddress? address,
    required String createdBy,
  });

  /// Lists every non-deleted Branch of [companyId] within [organizationId].
  /// Never returns a Branch belonging to a different organization or a
  /// different company.
  Future<AppResult<List<Branch>>> listByCompany({
    required String organizationId,
    required String companyId,
  });

  Future<AppResult<Branch>> getById({
    required String organizationId,
    required String id,
  });

  /// Updates only [Branch.name], [Branch.type], [Branch.address],
  /// [Branch.status] and audit fields (`updatedAt`, `updatedBy`,
  /// `version`) of the Branch identified by [organizationId]/[id]. Never
  /// accepts nor changes [Branch.organizationId] or [Branch.companyId].
  Future<AppResult<Branch>> update({
    required String organizationId,
    required String id,
    required String name,
    required BranchType type,
    BranchAddress? address,
    required BranchStatus status,
    required String updatedBy,
  });
}
