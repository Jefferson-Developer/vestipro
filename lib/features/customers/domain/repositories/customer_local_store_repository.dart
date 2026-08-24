import '../../../../core/utils/utils.dart';
import '../entities/customer.dart';

/// Domain contract for the on-device Customer cache populated by the initial
/// offline load (TASK-054).
///
/// Implementations must never persist a customer outside the
/// `organizationId`/`companyId` scope of the call, and must never be given
/// customers the caller has not already filtered by RBAC/portfolio — this
/// contract only stores what it is told to store.
abstract interface class CustomerLocalStoreRepository {
  /// Replaces every locally stored customer for [organizationId]/
  /// [companyId] with exactly [customers].
  ///
  /// This is the "carga inicial" primitive: it performs a full, idempotent
  /// replace rather than an incremental merge. The incremental sync engine
  /// (TASK-109) is expected to add its own merge method to this contract
  /// when it exists, reusing the same local schema.
  Future<AppResult<void>> replaceInitialLoad({
    required String organizationId,
    required String companyId,
    required List<Customer> customers,
  });

  /// Every customer currently stored locally for [organizationId]/
  /// [companyId], in no particular order.
  Future<AppResult<List<Customer>>> getAll({
    required String organizationId,
    required String companyId,
  });

  /// Number of customers currently stored locally for [organizationId]/
  /// [companyId], without materializing every row.
  Future<AppResult<int>> count({
    required String organizationId,
    required String companyId,
  });
}
