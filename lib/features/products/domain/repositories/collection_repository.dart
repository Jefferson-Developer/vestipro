import '../../../../core/utils/utils.dart';
import '../entities/collection.dart';

/// Contract for reading and writing `Collection` documents scoped under one
/// Organization (TASK-066). Collection belongs to exactly one
/// `organizationId` — never shared between tenants.
abstract interface class CollectionRepository {
  Future<AppResult<Collection>> create({required Collection collection});

  Future<AppResult<Collection>> update({required Collection collection});

  /// Lists every non-deleted Collection of [organizationId], active or
  /// closed. Never returns a Collection belonging to a different
  /// organization.
  Future<AppResult<List<Collection>>> listByOrganization(String organizationId);

  Future<AppResult<Collection>> getById({
    required String organizationId,
    required String id,
  });

  /// Transitions `Collection.status` to `CollectionStatus.closed`. Never
  /// deletes the Collection nor any Product association — see
  /// `Collection`'s own doc.
  Future<AppResult<Collection>> close({
    required String organizationId,
    required String id,
    required String updatedBy,
  });
}
