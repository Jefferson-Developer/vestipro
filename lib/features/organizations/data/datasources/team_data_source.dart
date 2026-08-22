import '../dtos/team_dto.dart';

/// Data access contract for `organizations/{organizationId}/teams/{id}`
/// documents (TASK-028). [FirestoreTeamDataSource] is the only
/// implementation today.
abstract interface class TeamDataSource {
  Future<TeamDto> create(TeamDto dto);

  /// Lists every non-deleted Team document under [organizationId]. Never
  /// queries across organizations.
  Future<List<TeamDto>> listByOrganization(String organizationId);

  /// Returns `null` when no document exists for [id] under [organizationId].
  Future<TeamDto?> getById({
    required String organizationId,
    required String id,
  });

  /// Adds [userId] to the document's `memberIds` array (Firestore
  /// `FieldValue.arrayUnion`, so adding it twice keeps a single entry) and
  /// bumps `updatedAt`/`updatedBy`/`version`.
  Future<TeamDto> addMember({
    required String organizationId,
    required String id,
    required String userId,
    required DateTime updatedAt,
    required String updatedBy,
  });
}
