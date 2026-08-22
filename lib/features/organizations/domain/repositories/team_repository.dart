import '../../../../core/utils/utils.dart';
import '../entities/team.dart';

/// Contract for reading and writing [Team] documents scoped under one
/// [Organization] (TASK-028).
///
/// Every method requires [organizationId] so no query can be built without a
/// tenant scope by mistake — Firestore Security Rules (TASK-030) remain the
/// real source of truth for isolation, this is defense-in-depth only.
abstract interface class TeamRepository {
  Future<AppResult<Team>> create({
    required String id,
    required String organizationId,
    required String name,
    required String createdBy,
  });

  /// Lists every non-deleted Team of [organizationId]. Never returns a Team
  /// belonging to a different organization.
  Future<AppResult<List<Team>>> listByOrganization(String organizationId);

  Future<AppResult<Team>> getById({
    required String organizationId,
    required String id,
  });

  /// Adds [userId] to [Team.memberIds] (idempotent: adding the same
  /// [userId] twice keeps a single entry) and bumps audit metadata. Never
  /// accepts nor changes [Team.organizationId].
  Future<AppResult<Team>> addMember({
    required String organizationId,
    required String id,
    required String userId,
    required String updatedBy,
  });
}
