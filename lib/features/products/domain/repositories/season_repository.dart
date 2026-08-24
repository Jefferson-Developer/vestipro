import '../../../../core/utils/utils.dart';
import '../entities/season.dart';

/// Contract for reading and writing `Season` documents scoped under one
/// Organization (TASK-066). Season is a shared vocabulary reused by every
/// `Collection` of the same Organization — never shared between tenants.
abstract interface class SeasonRepository {
  Future<AppResult<Season>> create({required Season season});

  Future<AppResult<Season>> update({required Season season});

  /// Lists every non-deleted Season of [organizationId]. Never returns a
  /// Season belonging to a different organization.
  Future<AppResult<List<Season>>> listByOrganization(String organizationId);

  Future<AppResult<Season>> getById({
    required String organizationId,
    required String id,
  });

  /// Whether a non-deleted Season with [name] (case-insensitive, trimmed)
  /// already exists in [organizationId]. [excludingSeasonId] lets an update
  /// check for duplicates without flagging the Season being edited.
  Future<AppResult<bool>> existsByName({
    required String organizationId,
    required String name,
    String? excludingSeasonId,
  });

  /// Whether any non-deleted `Collection` of [organizationId] still
  /// references [seasonId]. Used to block deleting a Season vocabulary
  /// entry still in use, the same guard `TeamRepository.hasCommercialLinks`
  /// applies before deleting a Team.
  Future<AppResult<bool>> hasCollections({
    required String organizationId,
    required String seasonId,
  });

  Future<AppResult<Season>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  });
}
